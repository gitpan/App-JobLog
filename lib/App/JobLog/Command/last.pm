package App::JobLog::Command::last;
BEGIN {
  $App::JobLog::Command::last::VERSION = '1.002';
}

# ABSTRACT: show details of last recorded event

use Modern::Perl;
use App::JobLog -command;
use Class::Autouse qw(
  App::JobLog::Log
  App::JobLog::Command::summary
);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my ($e) = App::JobLog::Log->new->last_event;
    if ($e) {
        my $start = $e->start->strftime('%F at %H:%M:%S %p');
        my $end = $e->is_open ? 'now' : $e->end->strftime('%F at %H:%M:%S %p');
        $opt->{merge} = 'no_merge';
        'App::JobLog::Command::summary'->execute( $opt, ["$start - $end"] );
    }
    else {
        say 'empty log';
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name }

sub abstract { 'describe the last task recorded' }

1;

__END__
=pod

=head1 NAME

App::JobLog::Command::last - show details of last recorded event

=head1 VERSION

version 1.002

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

