#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use autodie;

use File::Path qw(remove_tree);
use File::Temp ();
use App::JobLog;
use App::JobLog::Config qw(log DIRECTORY);
use App::JobLog::Log::Line;
use App::JobLog::Log;
use App::JobLog::Time qw(tz);
use DateTime;
use File::Spec;
use IO::All -utf8;
use FileHandle;

use Test::More;
use App::Cmd::Tester;
use Test::Fatal;

# create a working directory
my $dir = File::Temp->newdir();
$ENV{ DIRECTORY() } = $dir;

# use a constant time zone so as to avoid crafting data to fit various datelight savings time adjustments
$App::JobLog::Config::tz =
  DateTime::TimeZone->new( name => 'America/New_York' );

subtest 'basic test' => sub {

    # make a big log
    my $log   = App::JobLog::Log->new;
    my $start = make_date(qw(2011  1  1 0  0 0));
    my $end   = $start->clone->add( months => 1 );
    my $t     = $start->clone;
    my $count = 1;
    while ( $t <= $end ) {
        $log->append_event( time => $t, description => 'foo' . $count++ );
        $t->add( hours => 6 );
    }
    my $result = test_app( 'App::JobLog' => [qw(summary -W 2011/1)] );
    is( $result->error, undef, 'threw no exceptions' );
};

subtest 'note summary' => sub {

    # make a big log
    '' > io log;
    my $log   = App::JobLog::Log->new;
    my $start = make_date(qw(2011  1  1 0  0 0));
    my $end   = $start->clone->add( months => 1 );
    my $t     = $start->clone;
    my $count = 1;
    while ( $t <= $end ) {
        my $method = $count % 2 ? 'append_event' : 'append_note';
        $log->$method( time => $t, description => 'foo' . $count++ );
        $t->add( hours => 6 );
    }
    my $result = test_app( 'App::JobLog' => [qw(summary -W --notes 2011/1)] );
    is( $result->error, undef, 'threw no exceptions' );
    like( $result->stdout, qr/foo/, 'found some notes' );
    test_app( 'App::JobLog' => [qw(note testing)] );
    $result = test_app( 'App::JobLog' => [qw(summary -W --notes today)] );
    like( $result->stdout, qr/testing/, 'found appended note' );
};

subtest 'tags' => sub {

    # make a big log
    '' > io log;
    my $log = App::JobLog::Log->new;
    my $d   = make_date(qw(2011  1  1 0  0 0));
    $log->append_event( time => $d, tags => ['description'] );
    $log->append_event( time => $d->clone->add( minutes => 1 ), done => 1 );
    $d->add( days => 1 );
    $log->append_note( time => $d, tags => ['note'] );
    my $result = test_app( 'App::JobLog' => [qw(tags)] );
    is( $result->error, undef, 'threw no exceptions' );
    like( $result->stdout, qr/description/, 'found description tag' );
    unlike( $result->stdout, qr/note/, 'did not find note tag' );
    $result = test_app( 'App::JobLog' => [qw(tags --all)] );
    like( $result->stdout, qr/description/, 'found description tag' );
    like( $result->stdout, qr/note/,        'found note tag' );
    $result = test_app( 'App::JobLog' => [qw(tags --notes)] );
    unlike( $result->stdout, qr/description/, 'did not find description tag' );
    like( $result->stdout, qr/note/, 'found note tag' );

    # search within range
    note 'searching within range of first date';
    $result = test_app( 'App::JobLog' => [qw(tags 2011/1/1)] );
    is( $result->error, undef, 'threw no exceptions' );
    like( $result->stdout, qr/description/, 'found description tag' );
    unlike( $result->stdout, qr/note/, 'did not find note tag' );
    $result = test_app( 'App::JobLog' => [qw(tags --all 2011/1/1)] );
    like( $result->stdout, qr/description/, 'found description tag' );
    unlike( $result->stdout, qr/note/, 'did not find note tag' );
    $result = test_app( 'App::JobLog' => [qw(tags --notes 2011/1/1)] );
    unlike( $result->stdout, qr/description/, 'did not find description tag' );
    unlike( $result->stdout, qr/note/,        'did not find note tag' );
    note 'searching within range of second date';
    $result = test_app( 'App::JobLog' => [qw(tags 2 January 2011)] );
    is( $result->error, undef, 'threw no exceptions' );
    unlike( $result->stdout, qr/description/, 'did not find description tag' );
    unlike( $result->stdout, qr/note/,        'did not find note tag' );
    $result = test_app( 'App::JobLog' => [qw(tags --all 2 January 2011)] );
    unlike( $result->stdout, qr/description/, 'did not find description tag' );
    like( $result->stdout, qr/note/, 'found note tag' );
    $result = test_app( 'App::JobLog' => [qw(tags --notes 2 January 2011)] );
    unlike( $result->stdout, qr/description/, 'did not find description tag' );
    like( $result->stdout, qr/note/, 'found note tag' );
};

done_testing();

remove_tree $dir;

sub make_date {
    my ( $year, $month, $day, $hour, $minute, $second ) = @_;
    return DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        hour      => $hour,
        minute    => $minute,
        second    => $second,
        time_zone => $App::JobLog::Config::tz,
    );
}
