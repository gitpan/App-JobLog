package App::JobLog::Command::last;
$App::JobLog::Command::last::VERSION = '1.032';
# ABSTRACT: show details of last recorded event

use Modern::Perl;
use App::JobLog -command;
use Class::Autouse qw(
  App::JobLog::Log
  App::JobLog::Command::summary
);

sub execute {
    my ( $self, $opt, $args ) = @_;

    # construct event test
    my %must   = map { $_ => 1 } @{ $opt->tag     || [] };
    my %mustnt = map { $_ => 1 } @{ $opt->without || [] };
    my $test   = sub {
        my $event = shift;
        my $good  = 1;
        if (%must) {
            $good = 0;
            for my $tag ( @{ $event->tags } ) {
                if ( $must{$tag} ) {
                    $good = 1;
                    last;
                }
            }
        }
        if ( $good && %mustnt ) {
            for my $tag ( @{ $event->tags } ) {
                if ( $mustnt{$tag} ) {
                    $good = 0;
                    last;
                }
            }
        }
        return $good;
    };

    # find event
    my ( $i, $count, $e ) = ( App::JobLog::Log->new->reverse_iterator, 0 );
    while ( $e = $i->() ) {
        $count++;
        last if $test->($e);
    }

    if ($e) {
        my $start = $e->start->strftime('%F at %H:%M:%S %p');
        my $end = $e->is_open ? 'now' : $e->end->strftime('%F at %H:%M:%S %p');
        $opt->{merge} = 'no_merge';
        App::JobLog::Command::summary->execute( $opt, ["$start - $end"] );
    }
    else {
        say $count ? 'no matching event' : 'empty log';
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name }

sub abstract { 'describe the last task recorded' }

sub options {
    return (
        [
            'tag|t=s@',
            'find the last event with one of these tags; '
              . 'multiple tags may be specified'
        ],
        [
            'without|w=s@',
            'find the last event which does not have any of these tags; '
              . 'multiple tags may be specified'
        ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::last - show details of last recorded event

=head1 VERSION

version 1.032

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job last
 Sunday,  6 March, 2011
   7:36 - 7:37 pm  0.01  widget  something to add                                                                                                                  
 
   TOTAL HOURS 0.01
   widget      0.01

=head1 DESCRIPTION

Without options specified B<App::JobLog::Command::last> simply tells you the last event in the log. 
This is useful if you want to know whether you ever punched out, for example, or if you want to know 
what tags a new event will inherit, what task you would be resuming, and so forth.

You may specify tags or tags to avoid, in which case B<last> will describe the last event matching
this restriction.

=head1 SEE ALSO

L<App::JobLog::Command::summary>, L<App::JobLog::Command::today>, L<App::JobLog::Command::resume>, L<App::JobLog::Command::tags>,
L<App::JobLog::Command::modify>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
