package App::JobLog::Command::done;
BEGIN {
  $App::JobLog::Command::done::VERSION = '1.001';
}

# ABSTRACT: close last open event

use App::JobLog -command;
use Modern::Perl;
use Class::Autouse 'App::JobLog::Log';

sub execute {
    my ( $self, $opt, $args ) = @_;

    App::JobLog::Log->new->append_event( done => 1 );
}

sub usage_desc { '%c ' . __PACKAGE__->name }

sub abstract { 'mark current task as done' }

1;

__END__
=pod

=head1 NAME

App::JobLog::Command::done - close last open event

=head1 VERSION

version 1.001

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

