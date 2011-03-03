package App::JobLog::Log::Format;
BEGIN {
  $App::JobLog::Log::Format::VERSION = '1.000';
}

# ABSTRACT: pretty printer for log


use Exporter 'import';
our @EXPORT = qw(
  display
  duration
  summary
  wrap
);

use Modern::Perl;
use App::JobLog::Config qw(
  columns
  day_length
  is_workday
  precision
);
use App::JobLog::Log::Synopsis qw(collect :merge);
use Text::WrapI18N qw();
use App::JobLog::TimeGrammar qw(parse);

use constant TAG_COLUMN_LIMIT => 10;
use constant MARGIN           => 30;
use constant DURATION_FORMAT  => '%0.' . precision . 'f';


sub summary {
    my ( $phrase, $test ) = @_;

    # we skip flex days if the events are at all filtered
    my $skip_flex = $test || 0;
    $test //= sub { $_[0] };
    my ( $start, $end ) = parse $phrase;
    unless ($skip_flex) {

     # if we are chopping off any of the first and last days we ignore flex time
        $skip_flex = 1 unless _break_of_dawn($start) && _witching_hour($end);
    }
    my $events = App::JobLog::Log->new->find_events( $start, $end );
    my @days = @{ _days( $start, $end, $skip_flex ) };
    my @periods = App::JobLog::Vacation->new->periods;

    # drop the vacation days that can't be relevant
    {
        my $e =
          App::JobLog::Log::Event->new(
            App::JobLog::Log::Line->new( time => $start ) );
        $e->end = $end;
        for ( my $i = 0 ; $i < @periods ; $i++ ) {
            my $p = $periods[$i];
            if ( $skip_flex && $p->flex || !$p->conflicts($e) ) {
                splice @periods, $i, 1;
                $i--;
            }
        }
    }

    # collect events into days
    for my $big_e (@$events) {
        for my $e ( $big_e->split_days ) {
            if ( $e = $test->($e) ) {
                for my $d (@days) {
                    next if $e->start > $d->end;
                    if ( $e->intersects( $d->pseudo_event ) ) {
                        push @{ $d->events }, $e;
                        last;
                    }
                    last if $e->is_open || $d->start > $e->end;
                }
            }
        }
    }

    # add in vacation times
    for my $p (@periods) {
        for my $d (@days) {
            if ( is_workday( $d->start ) && $p->conflicts($d) ) {
                my $clone = $p->clone;
                $clone->start = $d->start;
                if ( $clone->fixed ) {
                    $clone->end = $d->end;
                    push @{ $d->events }, $clone->overlap( $d->start, $d->end );
                }
                else {
                    if ( $clone->flex ) {
                        $clone->end = $clone->start->clone->add(
                            seconds => $d->time_remaining );
                        $d->{deferred} = $clone;
                    }
                    else {
                        $clone->end =
                          $clone->start->clone->add( hours => day_length );
                        push @{ $d->vacation }, $clone;
                    }
                }
            }
        }
    }

    # delete empty days
    for ( my $i = 0 ; $i < @days ; $i++ ) {
        my $d = $days[$i];
        if ( $d->is_empty && !is_workday( $d->start ) ) {
            splice @days, $i, 1;
            $i--;
        }
    }

    # fix deferred flex time and ensure events are chronologically ordered
    for my $d (@days) {
        my $flex   = $d->{deferred};
        my @events = @{ $d->events };
        if ($flex) {
            delete $d->{deferred};
            my $tr = $d->time_remaining;
            if ($tr) {
                $flex->end = $flex->start->clone->add( seconds => $tr );
            }
            push @events, $flex;
        }
        $d->{events} = [ sort { $a->cmp($b) } @events ] if @events > 1;
    }

    return \@days;
}

# whether the date is the first moment in its day
sub _break_of_dawn {
    my ($date) = @_;
    return $date->hour == 0 && $date->minute == 0 && $date->second == 0;
}

# whether the date is the last moment in its day
sub _witching_hour {
    my ($date) = @_;
    return $date->hour == 23 && $date->minute == 59 && $date->second == 59;
}

# create a list of days about which we wish to collect information
sub _days {
    my ( $start, $end, $skip_flex ) = @_;
    my @days;
    my $b1 = $start;
    my $b2 = $start->clone->add( days => 1 )->truncate( to => 'day' );
    while ( $b2 < $end ) {
        push @days,
          App::JobLog::Log::Day->new(
            start     => $b1,
            end       => $b2,
            skip_flex => $skip_flex
          );
        $b1 = $b2;
        $b2 = $b2->clone->add( days => 1 );
    }
    push @days,
      App::JobLog::Log::Day->new(
        start     => $b1,
        end       => $end,
        skip_flex => $skip_flex
      );
    return \@days;
}


sub display {
    my ( $days, $merge_level ) = @_;

    # TODO augment events with vacation and holidays
    if (@$days) {
        collect $_, $merge_level for @$days;
        my @synopses = map { @{ $_->synopses } } @$days;

        # in the future we will allow more of these values to be toggled
        my $columns = {
            time        => _single_interval($merge_level),
            tags        => 1,
            description => 1,
            duration    => 1
        };
        my $format = _define_format( \@synopses, $columns );

        # keep track of various durations
        my $times = {
            total    => 0,
            untagged => 0,
            expected => 0,
            vacation => 0,
            tags     => {}
        };

        # display synopses and add up durations
        my $previous;
        for my $d (@$days) {
            $d->times($times);
            $d->display( $previous, $format, $columns );
            $previous = $d;
        }

        my ( $m1, $m2 ) =
          ( length 'TOTAL HOURS', length duration( $times->{total} ) );
        my @keys = keys %{ $times->{tags} };
        push @keys, 'UNTAGGED' if $times->{untagged};
        push @keys, 'VACATION' if $times->{vacation};
        for my $tag (@keys) {
            my $l = length $tag;
            $m1 = $l if $l > $m1;
        }
        $format = sprintf "  %%-%ds %%%ds\n", $m1, $m2;
        printf $format, 'TOTAL HOURS', duration( $times->{total} );
        printf $format, 'VACATION',    duration( $times->{vacation} )
          if $times->{vacation};
        if ( %{ $times->{tags} } ) {
            printf $format, 'UNTAGGED', duration( $times->{untagged} )
              if $times->{untagged};
            for my $key ( sort keys %{ $times->{tags} } ) {
                my $d = $times->{tags}{$key};
                printf $format, $key, duration($d);
            }
        }
    }
    else {
        say 'No events in interval specified.';
    }
}

# generate printf format for synopses
# returns format and wrap widths for tags and descriptions
sub _define_format {
    my ( $synopses, $hash ) = @_;

    #determine maximum width of each column
    my $widths;
    for my $s (@$synopses) {
        if ( $hash->{tags} ) {
            my $w1 = $hash->{widths}{tags} || 0;
            my $ts = $s->tag_string;
            if ( length $ts > TAG_COLUMN_LIMIT ) {
                my $wrapped = wrap( $ts, TAG_COLUMN_LIMIT );
                $ts = '';
                for my $line (@$wrapped) {
                    $ts = $line if length $line > length $ts;
                }
            }
            my $w2 = length $ts;
            $hash->{widths}{tags} = $w2 if $w2 > $w1;
        }
        if ( $hash->{time} ) {
            my $w1 = $hash->{widths}{time} || 0;
            my $w2 = length $s->time_fmt;
            $hash->{widths}{time} = $w2 if $w2 > $w1;
        }
        if ( $hash->{duration} ) {
            my $w1 = $hash->{widths}{duration} || 0;
            my $w2 = length duration( $s->duration );
            $hash->{widths}{duration} = $w2 if $w2 > $w1;
        }
    }
    my $margins = 0;
    if ( $hash->{tags} && $hash->{widths}{tags} ) {
        $margins++;
        $hash->{formats}{tags} = sprintf '%%-%ds', $hash->{widths}{tags};

# there seems to be a bug in Text::Wrap that requires tinkering with the column width
        $hash->{widths}{tags}++;
    }
    if ( $hash->{time} && $hash->{widths}{time} ) {
        $margins++;
        $hash->{formats}{time} = sprintf '%%%ds', $hash->{widths}{time};
    }
    if ( $hash->{duration} && $hash->{widths}{duration} ) {
        $margins++;
        $hash->{formats}{duration} = sprintf '%%%ds', $hash->{widths}{duration};
    }
    if ( $hash->{description} ) {
        $margins++;
        my $max_description = columns;
        for my $col (qw(time duration tags)) {
            $max_description -= $hash->{widths}{col} || 0;
        }
        $max_description -= $margins * 2;    # left margins
        $max_description -= MARGIN;          # margin on the right
        $hash->{widths}{description} = $max_description;
        $hash->{formats}{description} = sprintf '%%-%ds', $max_description;
    }

    my $format = '';
    for my $col (qw(time duration tags description)) {
        my $f = $hash->{formats}{$col};
        $format .= "  $f" if $f;
    }
    return $format;
}


sub wrap {
    my ( $text, $columns ) = @_;
    $Text::WrapI18N::columns = $columns;
    my $s = Text::WrapI18N::wrap( '', '', $text );
    my @ar = $s =~ /^.*$/mg;
    return \@ar;
}

# determines from merge level whether event times should be displayed
sub _single_interval {
    $_[0] == MERGE_ADJACENT
      || $_[0] == MERGE_ADJACENT_SAME_TAGS
      || $_[0] == MERGE_NONE;
}


sub duration { sprintf DURATION_FORMAT, $_[0] / ( 60 * 60 ) }

1;

__END__
=pod

=head1 NAME

App::JobLog::Log::Format - pretty printer for log

=head1 VERSION

version 1.000

=head1 DESCRIPTION

This module handles word wrapping, date formatting, and the like.

=head1 METHODS

=head2 time_remaining

Determines the time remaining to work in the given period.
Accepts a reference to an array of L<App::JobLog::Log::Event> objects
and returns an integer representing a number of seconds.

=head2 display

Formats L<App::JobLog::Log::Synopsis> objects so they fit nicely on the screen.

=head2 wrap

Wraps C<wrap> from L<Text::Wrap>. Expects a string and a number of columns.
Returns a reference to an array of substrings wrapped to fit the columns.

=head2 duration

Work time formatter.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

