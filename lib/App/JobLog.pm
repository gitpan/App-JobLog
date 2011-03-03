package App::JobLog;
BEGIN {
  $App::JobLog::VERSION = '1.001';
}
use App::Cmd::Setup -app;

# ABSTRACT: base of work log application


sub allow_any_unambiguous_abbrev { 1 }

1;

__END__
=pod

=head1 NAME

App::JobLog - base of work log application

=head1 VERSION

version 1.001

=head1 DESCRIPTION

C<App::JobLog> is a minimal extension of L<App::Cmd>. All it adds to a vanilla
instance of this class is all unambiguous aliases of basic commands.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

