#!/usr/bin/perl -w
use strict;
use Time::HiRes qw(time);
use LWP::Simple qw(get);
use POSIX qw(strftime tcflush TCIFLUSH);

use IO::Socket;
use IO::Socket::INET;

use Net::MQTT::Simple "127.0.0.1";
use IO::Select;

$SIG{PIPE} = 'IGNORE';

sub ledbanner {
    my $ledsocket = IO::Socket::INET->new(
        PeerAddr => "10.42.76.66:12345",
        Proto => "udp"
    ) or warn "Ledbanner socket: $!";
    $ledsocket->send(shift);
    close $ledsocket;
}

my $minimum_time = .5;

my %url = (
    SKIP => 'http://jukebox:9000/Classic/status_header.html?p0=playlist&p1=jump&p2=%2B1&player=be%3Ae0%3Ae6%3A04%3A46%3A38',
    STOP => 'http://jukebox:9000/Classic/status_header.html?p0=stop&player=be%3Ae0%3Ae6%3A04%3A46%3A38',
    SHUF => 'http://jukebox:9000/Classic/plugins/RandomPlay/mix.html?type=track&player=be%3Ae0%3Ae6%3A04%3A46%3A38&addOnly=0',
    NOMZ => sub {
        ledbanner("NOMZ");
    },
    CO_2 => sub {
        my ($co2) = unpack "n", shift;
        print $co2, "\n";;
        retain "/revspace/sensors/co2", $co2;
        ledbanner($co2 > 1600 ? "!!sticky!!CO2 HIGH" : "!!reset!!CO2 HIGH");
    }
);

my $dev = (glob "/dev/ttyUSB*")[0];

-e $dev or die "$dev not found";

system qw(stty -F), $dev, qw(cs8 115200 ignbrk -brkint -icrnl -imaxbel -opost
    -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke
    noflsh -ixon -crtscts);


while (1) {
    my %prev;
    open my $fh, "<", (glob "/dev/ttyUSB*")[0] or die $!;
    while (<$fh>) {
        s/[\r\n]//g;
        my $msg = pack "H*", $_;
        my $type = substr $msg, 0, 4;
        my $data = substr $msg, 4;

        if (not exists $url{$type}) {
            print "Unknown: $msg\n";
            next;
        }

        next if $prev{$type} and $prev{$type} > (time() - $minimum_time);

        publish "/revspace/button/skip", "Skip pressed: " . localtime if $type eq "SKIP";
        publish "/revspace/button/nomz", "NOMZ pressed: " . localtime if $type eq "NOMZ";
        publish "/revspace/button/shuffle", "Shuffle pressed: " . localtime if $type eq "SHUF";
        publish "/revspace/button/stop", "Stop pressed: " . localtime if $type eq "STOP";

        print "$type\n";

        if (ref $url{$type}) {
            $url{$type}->($data);
        } else {
            get $url{$type};
        }
        $prev{$type} = time();
    }
    sleep 1;
}

