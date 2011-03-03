package App::JobLog::Command::configure;
BEGIN {
  $App::JobLog::Command::configure::VERSION = '1.000';
}

# ABSTRACT: examine or modify App::JobLog configuration

use App::JobLog -command;
use Modern::Perl;
use App::JobLog::Config qw(
  day_length
  editor
  merge
  pay_period_length
  precision
  start_pay_period
  sunday_begins_week
  workdays
  DAYS
  HOURS
  MERGE
  PERIOD
  PRECISION
  SUNDAY_BEGINS_WEEK
  WORKDAYS
);
use autouse 'App::JobLog::TimeGrammar' => qw(parse);

sub execute {
    my ( $self, $opt, $args ) = @_;
    _list_params() if $opt->list;
    if ( defined $opt->precision ) {
        my $precision = precision( $opt->precision );
        say "precision set to $precision";
    }
    if ( defined $opt->start_pay_period ) {
        eval {
            my ($s) = parse( $opt->start_pay_period );
            my $d = start_pay_period($s);
            say 'beginning of pay period set to ' . $d->strftime('%F');
        };
        $self->usage_error(
            'could not understand date: ' . $opt->start_pay_period )
          if $@;
    }
    if ( defined $opt->length_pay_period ) {
        my $length_pp = pay_period_length( $opt->length_pay_period );
        say "length of pay period in days set to $length_pp";
    }
    if ( defined $opt->day_length ) {
        my $day_length = day_length( $opt->day_length );
        say "length of work day set to $day_length";
    }
    if ( defined $opt->workdays ) {
        my $days = uc $opt->workdays;
        my %days = map { $_ => 1 } split //, $days;
        my @days;
        for ( split //, DAYS ) {
            push @days, $_ if $days{$_};
        }
        $days = join '', @days;
        $days = workdays($days);
        say "workdays set to $days";
    }
    if ( defined $opt->sunday_begins_week ) {
        my $bool;
        given ( $opt->sunday_begins_week ) {
            when (/true/i)  { $bool = 1 }
            when (/false/i) { $bool = 0 }
            default { $bool = $opt->sunday_begins_week || 0 }
        }
        $bool = sunday_begins_week($bool);
        say "Sunday begins week is now " . ( $bool ? 'true' : 'false' );
    }
    if ( defined $opt->merge ) {
        my $m = lc $opt->merge;
        $m =~ s/^\s++|\s++$//g;
        $m =~ s/\s++/ /g;
        my $value = merge($m);
        say "merge level is now '$value'";
    }
    if ( defined $opt->editor ) {
        my $value = editor( $opt->editor );
        say "log editor is now $value";
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o' }

sub abstract { 'set or display various parameters' }

sub options {
    return (
        [
            'precision=i',
            'decimal places of precision in display of time; '
              . 'e.g., --precision=1; '
              . 'default is '
              . PRECISION
        ],
        [
            'start-pay-period=s',
            'the first day of some pay period; '
              . 'pay period boundaries will be calculated based on this date and the pay period length; '
              . 'e.g., --start-pay-period="June 14, 1912"'
        ],
        [
            'sunday-begins-week=s',
            'whether Sundays should be regarded as the first day in the week; '
              . 'the alternative is Monday; default is '
              . ( SUNDAY_BEGINS_WEEK ? 'TRUE' : 'FALSE' )
        ],
        [
            'length-pay-period=i',
            'the length of the pay period in days; e.g., --pp-length= 7; '
              . 'default is '
              . PERIOD
        ],
        [
            'day-length=f',
            'length of workday; ' . 'e.g., -d 7.5; ' . 'default is ' . HOURS
        ],
        [
            'workdays=s',
            'which days of the week you work represented as some subset of '
              . DAYS
              . '; e.g., --workdays=MTWH; '
              . 'default is '
              . WORKDAYS
        ],
        [
            'merge=s',
            'amount of merging of events in summaries; '
              . 'available options are : '
              . "'adjacent same tags', 'adjacent', 'all', 'none', 'same day same tags', 'same day', 'same tags'; "
              . "default is '@{[MERGE]}'"
        ],
        [ 'editor=s', 'text editor to use when manually editing the log' ],
        [ 'list|l',   'list all configuration parameters' ],
    );
}

#
# list values of all params
#
sub _list_params {
    my @params = sort qw(
      precision
      day_length
      editor
      merge
      pay_period_length
      start_pay_period
      sunday_begins_week
      workdays
    );
    my %booleans = map { $_ => 1 } qw(
      sunday_begins_week
    );
    my ( $l1, $l2, %h ) = ( 0, 0 );

    for my $method (@params) {
        my $l     = length $method;
        my $value = eval "App::JobLog::Config::$method()";
        $value = $value ? 'true' : 'false' if $booleans{$method};
        $value = 'not defined' unless defined $value;
        $value = $value->strftime('%F') if ref $value eq 'DateTime';
        $l1    = $l                     if $l > $l1;
        $l     = length $value;
        $l2    = $l                     if $l > $l2;
        $h{$method} = $value;
    }
    my $format = '%-' . $l1 . 's %' . $l2 . "s\n";
    for my $method (@params) {
        my $value = $h{$method};
        $method =~ s/_/ /g;
        printf $format, $method, $value;
    }
}

sub validate {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error('specify some parameter to set or display') unless %$opt;
    $self->usage_error('cannot parse work days')
      if $opt->workdays && $opt->workdays !~ /^[SMTWHFA]*+$/i;
    $self->usage_error(
        'cannot understand argument ' . $opt->sunday_begins_week )
      if $opt->sunday_begins_week
          && $opt->sunday_begins_week !~ /^(?:true|false|[01])?$/i;
    if ( defined $opt->merge ) {
        my $m = lc $opt->merge;
        $m =~ s/^\s++|\s++$//g;
        $m =~ s/\s++/ /g;
        if ( $m !~
/^(?:adjacent|adjacent same tags|all|none|same day|same day same tags|same tags)$/
          )
        {
            $self->usage_error( 'unknown merge option: ' . $opt->merge );
        }
    }

}

1;



=pod

=head1 NAME

App::JobLog::Command::configure - examine or modify App::JobLog configuration

=head1 VERSION

version 1.000

=head1 DESCRIPTION

This wasn't written to be used outside of C<App::JobLog>. The code itself contains interlinear comments if
you want the details.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

