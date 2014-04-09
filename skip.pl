#!/usr/bin/perl -w
use strict;
use Time::HiRes qw(time);
use LWP::Simple qw(get);
use POSIX qw(strftime tcflush TCIFLUSH);

use IO::Socket::INET;
sub ledbanner {
	my $socket = IO::Socket::INET->new(qw/PeerAddr 10.42.76.66 PeerPort 12345 Proto udp/)
		or warn $!;
	$socket->send(shift);
	close $socket;
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

        if (exists $url{$type}) {
           next if $prev{$type} and $prev{$type} > (time() - $minimum_time);
	    print "$type\n";
            if (ref $url{$type}) {
		$url{$type}->($data);
	    } else {
   		get $url{$type};
	    }
            $prev{$type} = time();
        } else {
            print "Unknown: $msg\n";
        }
    }
}
