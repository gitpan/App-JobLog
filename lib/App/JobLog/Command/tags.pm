package App::JobLog::Command::tags;
{
  $App::JobLog::Command::tags::VERSION = '1.020';
}

# ABSTRACT: show what tags you have used

use App::JobLog -command;
use Modern::Perl;
use Class::Autouse qw(App::JobLog::Log);
use autouse 'App::JobLog::TimeGrammar'  => qw(parse);
use autouse 'Getopt::Long::Descriptive' => qw(prog_name);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $events;
    eval {
        if (@$args)
        {
            my ( $start, $end ) = parse( join( ' ', @$args ) );
            $events = App::JobLog::Log->new->find_events( $start, $end );
        }
        else {
            $events = App::JobLog::Log->new->all_events;
        }
    };
    $self->usage_error($@) if $@;
    my %tags;
    for my $e (@$events) {
        $tags{$_} = 1 for @{ $e->tags };
    }
    if (%tags) {
        print "\n";
        say $_ for sort keys %tags;
        print "\n";
    }
    else {
        say 'no tags in log';
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o [date or date range]' }

sub abstract {
    'list tags employed in log or some subrange thereof';
}

sub full_description {
    <<END
List the tags used to categorize tasks in the log or in a specified range of dates. This allows one to
explore the categorical structure of tasks.

The date expressions understood are the same as those understood by the C<summary> command.
END
}

sub options {
    return (
        [
                "Use '@{[prog_name]} help "
              . __PACKAGE__->name
              . '\' to see full details.'
        ],
    );
}

sub validate {
    my ( $self, $opt, $args ) = @_;
}

1;



=pod

=head1 NAME

App::JobLog::Command::tags - show what tags you have used

=head1 VERSION

version 1.020

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job tags this week

 foo
 
 houghton@NorthernSpy:~$ job tags

 bar
 foo
 quux

=head1 DESCRIPTION

B<App::JobLog::Command::tags> lists the tags applied to tasks anywhere in the log or in a specified
time range. This allows one to examine how tasks have been categorized (and perhaps how they have
been mis-typed).

The time expressions understood are the same as are understood by L<App::JobLog::Command::summary>.

=head1 SEE ALSO

L<App::JobLog::Command::summary>, L<App::JobLog::Command::today>, L<App::JobLog::Command::last>, L<App::JobLog::Command::parse>, L<App::JobLog::TimeGrammar>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

