package App::JobLog::Command::today;
BEGIN {
  $App::JobLog::Command::today::VERSION = '1.006';
}

# ABSTRACT: show what has happened today

use App::JobLog -command;
use Modern::Perl;
use App::JobLog::Command::summary;
use autouse 'App::JobLog::Time' => qw(now);

use constant FORMAT => '%l:%M:%S %p on %A, %B %d, %Y';

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
      'App::JobLog::Command::summary'->execute( $opt, ["$start - today"] );
    if ( $remaining == 0 ) {
        say "\nyou are just now done";
    }
    else {
        my $then = now->add( seconds => $remaining );
        if ( $then < now ) {
            say "\nyou were finished at " . $then->strftime(FORMAT);
        }
        else {
            say "\nyou will be finished at " . $then->strftime(FORMAT);
        }
    }
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



=pod

=head1 NAME

App::JobLog::Command::today - show what has happened today

=head1 VERSION

version 1.006

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job today --help
 job <command>
 
 job today [-f] [long options...]
 	-f --finished     show when you can stop working given hours already
 	                  work; optional argument indicates span to calculate
 	                  hours over or start time; e.g., --finished
 	                  yesterday or --finished payperiod
 	--help            this usage screen
 houghton@NorthernSpy:~$ job t
 Monday,  7 March, 2011
   8:01 am - ongoing  1.33  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 1.33
   bar         1.33
   foo         1.33
 houghton@NorthernSpy:~$ job t --finished payperiod
 Monday,  7 March, 2011
   8:01 am - ongoing  1.34  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 1.34
   bar         1.34
   foo         1.34
 
 you will be finished at  7:17:32 pm on monday, march 07, 2011

=head1 DESCRIPTION

B<App::JobLog::Command::today> serves two functions:

=over 8

=item 1

Reviewing the current day's events. In this it is completely equivalent to L<App::JobLog::Command::summary> given an
option like C<today>, C<now>, or whatever might be the current date.

=item 2

Determining when you will be able to punch out for the day.

=back

The latter feature requires the C<--finished> option, which takes as its value the starting date for the period over
which working time is to be calculated. L<App::JobLog> then iterates over all of the days in the interval so delimited,
tallying up all the work hours for the work days (see the C<workday> parameter of L<App::JobLog::Command::configure>) and
subtracting vacation time and time worked. If you wish to use the pay period as your interval, you need to have defined
the C<start pay period> parameter of L<App::JobLog::Command::configure>.

=head1 ACKNOWLEDGEMENTS

This command was inspired by my wife Paula, who frequently wanted to know when I'd be done for the day. In an earlier
incarnation of this application one obtained it by passing in the option C<-p> and I knew it as the Paula feature.

=head1 SEE ALSO

L<App::JobLog::Command::summary>, L<App::JobLog::Command::last>, L<App::JobLog::Command::configure>,
L<App::JobLog::Command::vacation>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

