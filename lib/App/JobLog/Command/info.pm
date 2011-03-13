package App::JobLog::Command::info;
BEGIN {
  $App::JobLog::Command::info::VERSION = '1.009';
}

# ABSTRACT: provides general App::JobLog information

use App::JobLog -command;
use autouse 'File::Temp'                => qw(tempfile);
use autouse 'Pod::Usage'                => qw(pod2usage);
use autouse 'Getopt::Long::Descriptive' => qw(prog_name);
use autouse 'Carp'                      => qw(carp);
use autouse 'App::JobLog::Config'       => qw(log DIRECTORY);
use Class::Autouse qw(Config File::Spec);

$App::JobLog::Command::info::VERSION ||= .001; # Dist::Zilla will automatically update this

use Modern::Perl;

# using quasi-pod -- == instead of = -- to make this work with Pod::Weaver

sub execute {
    my ( $self, $opt, $args ) = @_;
    my ( $fh, $fn ) = tempfile( UNLINK => 1 );
    my $executable = prog_name($0);
    my $text =
        $self->_header($executable)
      . $self->_basic_usage($executable)
      . $self->_footer($executable);
    my @options = ( -verbose => 2, -exitval => 0, -input => $fn );
    given ( $opt->verbosity ) {
        when ('verbose') {
            $text =
                $self->_header($executable)
              . $self->_body($executable)
              . $self->_footer($executable);
            my $perldoc =
              File::Spec->catfile( $Config::Config{scriptdir}, 'perldoc' );
            unless ( -e $perldoc ) {
                carp 'Cannot find perldoc. Text will not be paged.';
                push @options, -noperldoc => 1;
            }
        }
        when ('quiet') {
            $text = $self->_header($executable) . $self->_footer($executable);
            push @options, -noperldoc => 1;
        }
        default { push @options, -noperldoc => 1 }
    }

    $text = <<END;
$text
==cut
END
    $text =~ s/^==(\w)/=$1/gm;
    print $fh $text;
    $fh->close;
    pod2usage(@options);
}

sub usage_desc { '%c ' . __PACKAGE__->name }

sub abstract { 'describe job log' }

sub full_description {
    <<END
Describes application and provides usage information.
END
}

sub options {
    return (
        [
            "verbosity" => hidden => {
                one_of => [
                    [ 'quiet|q'       => 'minimal documentation' ],
                    [ 'verbose|man|v' => 'extensive documentation in pager' ],
                ],
            }
        ]
    );
}

# obtain all the
sub _unambiguous_prefixes {
    my ( $self, $command ) = @_;

    # borrowing this from App::Cmd::Command::commands
    my @commands =
      map { ( $_->command_names )[0] } $self->app->command_plugins;
    my %counts;
    for my $cmd (@commands) {
        for my $prefix ( _prefixes($cmd) ) {
            $counts{$prefix}++;
        }
    }
    my @prefixes;
    for my $prefix ( _prefixes($command) ) {
        push @prefixes, $prefix if $counts{$prefix} == 1;
    }
    return @prefixes;
}

# obtain all the prefixes of a word
sub _prefixes {
    my $cmd = shift;
    my @prefixes;
    for ( my ( $i, $lim ) = ( 0, length $cmd ) ; $i < $lim ; ++$i ) {
        push @prefixes, substr $cmd, 0, $lim - $i;
    }
    return @prefixes;
}

sub _header {
    my ( $self, $executable ) = (@_);
    return <<END;
==head1 Job Log

work log management

version $App::JobLog::Command::info::VERSION

This application allows one to keep a simple, human readable log
of one's activities. B<Job Log> also facilitates searching, summarizing,
and extracting information from this log as needed.
END
}

sub _body {
    my ( $self, $executable ) = (@_);
    return $self->_basic_usage($executable) . $self->_advanced_usage();
}

sub _basic_usage {
    my ( $self, $executable ) = (@_);
    return <<END;
    
==head1 Usage

B<Job Log> keeps a log of events. If you begin a new task you type

   $executable @{[App::JobLog::Command::add->name]} what I am doing now

and it appends the following, modulo changes in time, to @{[log]}:

   2011 2 1 15 19 12::what I am doing now

The portion before the first colon is a timestamp in year month day hour minute second format.
The portion after the second colon is your description of the event. The portion between the
colons, here blank, is a list of space-delimited tags one can use to categorize events. For
instance, if you were performing this task for Acme Widgets you might have typed

   $executable @{[App::JobLog::Command::add->name]} -t "Acme Widgets" what I am doing now

producing

   2011 2 1 15 19 12:Acme\\ Widgets:what I am doing now
   
Note the I<\\> character. This is the escape character which neutralizes any special value of
the character after it -- I<\\>, I<:>, or a whitespace character.

You may tag an event multiple times. E.g.,

   $executable @{[App::JobLog::Command::add->name]} -t "Acme Widgets" -t foo -t bar what I am doing now

producing

   2011 2 1 15 19 12:Acme\\ Widgets foo bar:what I am doing now
   
For readability it is probably best to avoid spaces in tags.

Since one usually works on a particular project for an extended period of time, if you specify no tags
the event is given the same tags as the preceding event. For example,

   $executable @{[App::JobLog::Command::add->name]} -t foo what I am doing now
   $executable @{[App::JobLog::Command::add->name]} now something else

would produce something like

   2011 2 1 15 19 12:foo:what I am doing now
   2011 2 1 16 19 12:foo:now something else

When you are done with the last task of the day, or your stop to take a break, you type

   $executable @{[App::JobLog::Command::done->name]}

which adds something like

   2011 2 1 16 19 12:DONE

to the log. Note the single colon. In this case I<DONE> is not a tag, though it is made
to appear similar since it serves a similar function.

When you come back to work you can type

   $executable @{[App::JobLog::Command::resume->name]}

to add a new line to the log with the same description and tags as the last task you began.

TODO talk about summary and obtaining full list of commands

B<TIP:> any unambigous prefix of a command will do. All the following are equivalent:

@{[join "\n", map {"   $executable $_ doing something"} $self->_unambiguous_prefixes(App::JobLog::Command::add->name)]}
END
}

sub _advanced_usage {
    my ( $self, $executable ) = (@_);
    return <<END;
    
==head1 Environment Variables

B<Job Log> may be configured in part by two environment variables:

==over 8

==item @{[DIRECTORY()]}

By default B<Job Log> keeps the log and all other files in a hidden directory called .joblog in your home
directory. If @{[DIRECTORY()]} is set, however, it will keep this files here.

==back

All other configuration is done through the B<@{[App::JobLog::Command::configure->name]}> command.

==head1 Date Grammar

B<Job Log> goes to considerable trouble to interpret whatever time expressions you might throw at it.
For example, it understands all of the following:

   1
   11/24 to today
   17 dec, 2024
   1 april, 2022 to 1-23-2002
   2023.6.5 - 10.26.2020
   2-22 till yesterday
   24 apr
   27 november, 1995 through 10
   3-4-2004
   3-9 - today
   4.23- 16 november, 1992
   8/1/1997 through yesterday
   june 14
   last month - 6.14
   pay period

Every expression represents an interval of time. It either names an interval or defines it as the span from
the beginning of one interval to the end of another.

TODO provide the BNF grammar used in time parsing
END
}

sub _footer {
    my ( $self, $executable ) = (@_);
    return <<END;
    
==head1 License etc.

 Author        David Houghton
               dfhoughton at gmail dot com
 Copyright (c) 2011
 License       Perl_5
END
}

# the complete bnf diagram for time grammar, also maintained
# in App::JobLog::TimeGrammar for lack of introspection in pod
sub _bnf {
    return <<END;
              <expression> = s* ( <ever> | <span> ) s*
                    <ever> = "all" | "always" | "ever" | [ [ "the" s ] ( "entire" | "whole" ) s ] "log"
                    <span> = <date> [ <span_divider> <date> ]
 
                      <at> = "at" | "@"
                 <at_time> = [ ( s | s* <at> s* ) <time> ]
              <at_time_on> = [ <at> s ] <time> s "on" s
               <beginning> = "beg" [ "in" [ "ning" ] ]
                    <date> = <numeric> | <verbal>
               <day_first> = d{1,2} s <month>
                 <divider> = "-" | "/" | "."
                 <dm_full> = d{1,2} s <month> [ "," ] s d{4}
                     <dom> = d{1,2}
                    <full> = <at_time_on> <full_no_time> | <full_no_time> <at_time>
              <full_month> = "january" | "february" | "march" | "april" | "may" | "june" | "july" | "august" | "september" | "october" | "november" | "december" 
            <full_no_time> = <dm_full> | <md_full>
            <full_weekday> = "sunday" | "monday" | "tuesday" | "wednesday" | "thursday" | "friday" | "saturday"
                     <iso> = d{4} ( <divider> ) d{1,2} \1 d{1,2}
                      <md> = d{1,2} <divider> d{1,2}
                 <md_full> = <month> s d{1,2} "," s d{4}
          <modifiable_day> = <at_time_on> <modifiable_day_no_time> | <modifiable_day_no_time> <at_time>
  <modifiable_day_no_time> = [ <modifier> s ] <weekday>
        <modifiable_month> = [ <month_modifier> s ] <month>
       <modifiable_period> = [ <period_modifier> s ] <period>
                <modifier> = "last" | "this" 
                   <month> = <full_month> | <short_month> 
               <month_day> = <at_time_on> <month_day_no_time> | <month_day_no_time> <at_time>
       <month_day_no_time> = <month_first> | <day_first>
             <month_first> = <month> s d{1,2}
          <month_modifier> = <modifier> | <termini> [ s "of" ]
                      <my> = <month> [","] s <year>
            <named_period> = <modifiable_day> | <modifiable_month> | <modifiable_period> 
                     <now> = "now"
                 <numeric> = <year> | <ym> |<at_time_on> <numeric_no_time> | <numeric_no_time> <at_time>
         <numeric_no_time> = <us> | <iso> | <md> | <dom>
                     <pay> = "pay" | "pp" | "pay" s* "period"
                  <period> = "week" | "month" | "year" | <pay>
         <period_modifier> = <modifier> | <termini> [ s "of" [ s "the" ] ] 
         <relative_period> = [ <at> s* ] <time> s <relative_period_no_time> | <relative_period_no_time> <at_time> | <now>
 <relative_period_no_time> = "yesterday" | "today"
             <short_month> = "jan" | "feb" | "mar" | "apr" | "may" | "jun" | "jul" | "aug" | "sep" | "oct" | "nov" | "dec"
           <short_weekday> = "sun" | "mon" | "tue" | "wed" | "thu" | "fri" | "sat" 
            <span_divider> = s* ( "-"+ | ( "through" | "thru" | "to" | "til" [ "l" ] | "until" ) ) s*
                 <termini> = [ "the" s ] ( <beginning> | "end" )
                    <time> = d{1,2} [ : d{2} [ : d{2} ] ] [ s* <time_suffix> ]
             <time_suffix> = ( "a" | "p" ) ( "m" | ".m." )
                      <us> = d{1,2} ( <divider> ) d{1,2} \1 d{4}
                  <verbal> = <my> | <named_period> | <relative_period> | <month_day> | <full>  
                 <weekday> = <full_weekday> | <short_weekday>
                    <year> = d{4}
                      <ym> = <year> <divider> d{1,2}
END
}

1;



=pod

=head1 NAME

App::JobLog::Command::info - provides general App::JobLog information

=head1 VERSION

version 1.009

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job help info
 job info
 
 Describes application and provides usage information.
 
 
 	-q --quiet         minimal documentation
 	-v --man --verbose  extensive documentation in pager
 	--help             this usage screen

=head1 DESCRIPTION

The synopsis says it all. For command specific help you should try the help command:

 houghton@NorthernSpy:~$ job help summary
 job summary [-iMmTtV] [long options...] <date or date range>
 
 List events with certain properties in a particular time range. Only the portions
 of events falling within the range will be listed.
 
 Events may be filtered in numerous ways: by tag, time of day, or terms used in descriptions.
 If tags to match are provided, only those events that contain at least one such tag will be shown. If
 tags not to match are provided, only those events that contain none of these tags will be shown.
 
 if you provide description filters to match or avoid, these will be interpreted as regexes. try 'perldoc perlre'

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

