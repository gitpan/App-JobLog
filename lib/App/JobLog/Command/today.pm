package App::JobLog::Command::today;
BEGIN {
  $App::JobLog::Command::today::VERSION = '1.000';
}

# ABSTRACT: show what has happened today

use App::JobLog -command;
use Modern::Perl;
use App::JobLog::Command::summary;
use autouse 'App::JobLog::Time' => qw(now);

sub execute {
    my ( $self, $opt, $args ) = @_;

    # display everything done today
    App::JobLog::Command::summary->execute( $opt, ['today'] );
    if ( exists $opt->{finished} ) {

        # adjust options
        my $start = $opt->{finished} || 'today';
        delete $opt->{finished};
        $opt->{hidden} = 1;
        _when_finished( $start, $opt );
    }
}

#
# Display stop time
#
sub _when_finished {
    my ( $start, $opt ) = @_;

    my $remaining =
      'App::JobLog::Command::summary'->execute( $opt, "$start - today" );
    if ( $remaining == 0 ) {
        print "you are just now done\n";
    }
    else {
        my $now  = now;
        my $then = $now->clone;
        $then->add( hours => $remaining );
        my $duration = $then->subtract_datetime($now);
        if ( $duration->days > 0 ) {
            print 'you were done';
            my ( $weeks, $days, $hours, $minutes, $seconds ) =
              $duration->in_units( 'weeks', 'days', 'hours', 'minutes',
                'seconds' );
            no strict 'refs';
            for my $period qw(weeks days hours minutes seconds) {
                print ' ' . _grammatical_number( $period, $$period );
            }
            printf " %s\n", $remaining < 0 ? 'ago' : 'from now';
        }
        else {
            printf "you %s done at %s\n",
              $remaining < 0 ? 'were' : 'will be',
              $then->strftime('%l:%M %p');
        }
    }
}

sub _grammatical_number {
    my ( $term, $units ) = @_;
    my $base = " $units $term";
    $base = $base . 's' if $units > 1;
    return $base;
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o' }

sub abstract { 'what has happened today' }

sub full_description {
    <<END;
List what has happened today.

This is basically a specialized variant of the @{[App::JobLog::Command::summary->name]} command.
END
}

sub options {
    return (
        [
            'finished|f:s',
            'show when you can stop working given hours already work; '
              . 'optional argument indicates span to calculate hours over or start time; '
              . 'e.g., --finished yesterday or --finished payperiod'
        ],
    );
}

1;

__END__
=pod

=head1 NAME

App::JobLog::Command::today - show what has happened today

=head1 VERSION

version 1.000

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

