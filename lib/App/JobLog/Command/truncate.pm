package App::JobLog::Command::truncate;
BEGIN {
  $App::JobLog::Command::truncate::VERSION = '1.019';
}

# ABSTRACT: decapitate the log

use App::JobLog -command;
use autouse 'App::JobLog::TimeGrammar' => qw(parse);
use Class::Autouse qw(IO::File App::JobLog::Log);
use autouse 'App::JobLog::Time'   => qw(now);
use autouse 'App::JobLog::Config' => qw(log);

use Modern::Perl;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $expression = join ' ', @$args;
    my ( $s, $is_interval );
    eval { ( $s, undef, $is_interval ) = parse $expression; };
    $self->usage_error($@) if $@;
    $self->usage_error('truncation date must not be a interval')
      if $is_interval;

    # determine name of head log
    my $log = App::JobLog::Log->new;
    my $p   = $log->find_previous($s);
    $self->usage("no event in log prior to $expression") unless $p;
    my $e    = $log->first_event;
    my $base = 'log-' . $e->ymd . '--'$p->ymd;
    # create output handle for head log
    my $io   = $opt->compression
      ? _pick_compression( $opt->compression ) :: 'IO::File';
    given ($io) {
        when ('IO::File')            { }
        when ('IO::Compress::Zip')   { }
        when ('IO::Compress::Gzip')  { }
        when ('IO::Compress::Bzip2') { }
        when ('IO::Compress::Lzma')  { }
        default { die "unprepared to handle $io; please report bug"}
    }

    # create backup log
    # iterate over events in log, appending old ones to new handle
    # append done event if necessary
    $io->close;
    # create  temp file
    # append start line if necessary
    # append remaining lines to new log
    # move old to new
}

sub validate {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('no time expression provided') unless @$args;
    if ( $opt->compression ) {
        my $alg = _pick_compression( $opt->compression );
        eval { require $alg };
        $self->usage(
"you must install $alg to use compression option --$opt->compression"
        ) if $@;
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name }

sub abstract {
    'Truncate the log to contain only those moments after a given date.';
}

sub options {
    return (
        [
            compression => hidden => {
                one_of => [
                    [ 'zip|z',   'pass truncated head of log through zip', ],
                    [ 'gzip|g',  'pass truncated head of log through gzip', ],
                    [ 'bzip2|b', 'pass truncated head of log through bzip2', ],
                    [ 'lzma|l',  'pass truncated head of log through lzma', ],
                ]
            }
        ]
    );
}

sub full_description {
    <<END
If you are getting strange results with @{[App::JobLog::Command::summary->name]}, the problem
might be the time expression you're using. This command lets you see how your expression is
getting parsed.

It repeats to you the phrase it has parsed, prints out the start and end time of the corresponding
interval, and finally, whether it understands itself to have received an expression of the form
<date> or <date> <separator> <date>, the latter form being called an "interval" for diagnostic
purposes.
END
}

1;

# converts chosen compression opt into appropriate IO:: algorithm
sub _pick_compression {
    my $alg = shift;
    given ($alg) {
        when ('zip')   { return 'IO::Compress::Zip' }
        when ('gzip')  { return 'IO::Compress::Gzip' }
        when ('bzip2') { return 'IO::Compress::Bzip2' }
        when ('lzma')  { return 'IO::Compress::Lzma' }
    }



=pod

=head1 NAME

App::JobLog::Command::truncate - decapitate the log

=head1 VERSION

version 1.019

=head1 DESCRIPTION

If you are getting strange results with summary, the problem
might be the time expression you're using. This command lets you see how your expression is
getting parsed.

It repeats to you the phrase it has parsed, prints out the start and end time of the corresponding
interval, and finally, whether it understands itself to have received an expression of the form
<date> or <date> <separator> <date>, the latter form being called an "interval" for diagnostic
purposes.

=head1 SEE ALSO

L<App::JobLog::TimeGrammar>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

