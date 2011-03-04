package App::JobLog::Command::vacation;
BEGIN {
  $App::JobLog::Command::vacation::VERSION = '1.002';
}

# ABSTRACT: controller for vacation dates

use Modern::Perl;
use App::JobLog -command;
use autouse 'App::JobLog::TimeGrammar'      => qw(parse);
use autouse 'App::JobLog::Vacation::Period' => qw(
  FLEX
  FIXED
  ANNUAL
  MONTHLY
);
use Class::Autouse qw(App::JobLog::Vacation);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $vacation = App::JobLog::Vacation->new;
    if ( $opt->modification ) {
        eval {
            given ( $opt->modification )
            {
                when ('add') {
                    my ( $s, $e ) = parse( $opt->add );
                    my $repeats;
                    given ( $opt->{repeat} || '' ) {
                        when ('annual')  { $repeats = ANNUAL }
                        when ('monthly') { $repeats = MONTHLY }
                        default          { $repeats = 0 }
                    }
                    my $flexibility;
                    given ( $opt->{flexibility} || '' ) {
                        when ('fixed') { $flexibility = FIXED }
                        when ('flex')  { $flexibility = FLEX }
                        default        { $flexibility = 0 }
                    }
                    $vacation->add(
                        description => join( ' ', @$args ),
                        time        => $s,
                        end         => $e,
                        repeats     => $repeats,
                        type        => $flexibility,
                        tags => $opt->{tag} || [],
                    );
                }
                when ('remove') {
                    $vacation->remove( $opt->remove );
                }
            }
        };
        $self->usage_error($@) if $@;
    }
    _show($vacation);
    $vacation->close;
}

sub _show {
    my ($vacation) = @_;
    my $lines = $vacation->show;
    if (@$lines) {
        print $_ for @$lines;
    }
    else {
        say 'no vacation times recorded';
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o [<description>]' }

sub abstract { 'list or define days off' }

sub options {
    return (
        [ 'list|l', 'show all vacation times recorded', ],
        [
            'flexibility' => hidden => {
                one_of => [
                    [
                        'flex|f',
'add sufficient vacation time to complete workday; this is recorded with the "flex" tag'
                    ],
                    [
                        'fixed|x',
'a particular period of time during the day that should be marked as vacation; '
                          . 'this is in effect a special variety of work time, since it has a definite start and duration'
                    ],
                ]
            }
        ],
        [ 'tag|t=s@', 'tag vacation time; e.g., -a yesterday -t float' ],
        [
            'repeat' => 'hidden' => {
                one_of => [
                    [ 'annual',  'vacation period repeats annually' ],
                    [ 'monthly', 'vacation period repeats monthly' ],
                ]
            }
        ],
        [
            'modification' => 'hidden' => {
                one_of => [
                    [ 'add|a=s', 'add date or range; e.g., -a "May 17, 1951"' ],
                    [
                        'remove|r=i',
'remove period with given index from list (see --list); e.g., -d 1'
                    ],
                ]
            }
        ]
    );
}

sub validate {
    my ( $self, $opt, $args ) = @_;

    if ( $opt->modification ) {
        $self->usage_error('either list or modify') if $opt->list;
        $self->usage_error('no description provided')
          if $opt->modification eq 'add'
              && !@$args;
    }
    else {
        $self->usage_error('--tag requires that you add a date')
          if $opt->tag;
        $self->usage_error('--annual and --monthly require --add')
          if $opt->repeat;
        $self->usage_error('either list or modify') unless $opt->list;
        $self->usage_error('both --flex and --fixed require --add')
          if $opt->flexibility;
    }
}

1;



=pod

=head1 NAME

App::JobLog::Command::vacation - controller for vacation dates

=head1 VERSION

version 1.002

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

