package App::JobLog::Command::edit;
BEGIN {
  $App::JobLog::Command::edit::VERSION = '1.002';
}

# ABSTRACT: edit the log

use App::JobLog -command;
use Modern::Perl;
use Class::Autouse qw{
  App::JobLog::Log
  App::JobLog::Log::Line
  FileHandle
};
use autouse 'File::Temp'                => qw(tempfile);
use autouse 'File::Copy'                => qw(copy);
use autouse 'Digest::MD5'               => qw(md5);
use autouse 'App::JobLog::Config'       => qw(editor log);
use autouse 'Getopt::Long::Descriptive' => qw(prog_name);
use autouse 'App::JobLog::TimeGrammar'  => qw(parse);

sub execute {
    my ( $self, $opt, $args ) = @_;
    if ( $opt->close ) {
        my $time = join ' ', @$args;
        eval {
            my ($s) = parse($time);
            my $log = App::JobLog::Log->new;
            my ( $e, $i ) = $log->find_previous($s);
            $self->usage_error('log does not contain appropriate event')
              unless $e;
            $log->insert( $i + 1,
                App::JobLog::Log::Line->new( time => $s, done => 1 ) );
        };
        $self->usage_error($@) if $@;
    }
    elsif ( my $editor = editor ) {
        if ( my $log = log ) {
            my ( $fh, $fn ) = tempfile;
            binmode $fh;
            copy( $log, $fh );
            $fh->close;
            $fh = FileHandle->new($log);
            my $md51 = md5($fh);
            system "$editor $log";
            $fh = FileHandle->new($log);
            my $md52 = md5($fh);

            if ( $md51 ne $md52 ) {
                $fh = FileHandle->new( "$log.bak", 'w' );
                copy( $fn, $fh );
                $fh->close;
                say "saved backup log in $log.bak";
                App::JobLog::Log->new->validate;
            }
            else {
                unlink $fn;
            }
        }
        else {
            say 'nothing in log to edit';
        }
    }
    else {
        $self->usage_error('no editor specified') unless $opt->close;
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' [-c <date and time>]' }

sub abstract { 'open a text editor to edit the log' }

sub full_description {
    <<END;
Close an open task or open a text editor to edit the log.

Closing an open task is the only edit you'll commonly have to make (it's
easy to forget to close the last task of the day). Fortunately, it is the easiest
edit to perform. You simply type

@{[prog_name]} @{[__PACKAGE__->name]} --close yesterday at 8:00 pm

for example and @{[prog_name]} will insert the appropriate line if it can do so.
If it can't because there is no open task at the time specified, it will emit a warning
instead.

The date and time parsing is handled by the same code used by the @{[App::JobLog::Command::summary->name]} command,
so what works for one works for the other. One generally does not specify hours and such
for summaries, but @{[prog_name]} will understand most common natural language time expressions.

If you need to do more extensive editing of the log this command will open a text editor
for you and confirm the validity of the log after you save, commenting out
ill-formed lines and printing a warning. This command requires the you
to have set editor configuration parameter to specify a text. 
The text editor must be invokable like so,

  <editor> <file to edit>
  
That is, you must be able to specify the file to edit as an argument. If the editor
requires any additional arguments or options you must provide those via the
environment variable.
END
}

sub options {
    return (
        [
            'close|close-task|c' =>
              'add a "DONE" line to the log at the specified moment'
        ],
    );
}

sub validate {
    my ( $self, $opt, $args ) = @_;

    if ( $opt->close ) {
        $self->usage_error('no time expression provided') unless @$args;
    }
}

1;



=pod

=head1 NAME

App::JobLog::Command::edit - edit the log

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

