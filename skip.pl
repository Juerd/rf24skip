#!/usr/bin/perl -w
use strict;
use Time::HiRes qw(time);
use LWP::Simple qw(get);

my $minimum_time = .5;
my $url = 'http://jukebox:9000/Classic/status_header.html?p0=playlist&p1=jump&p2=%2B1&player=be%3Ae0%3Ae6%3A04%3A46%3A38';

my $dev = (glob "/dev/ttyUSB*")[0];

-e $dev or die "$dev not found";

system qw(stty -F), $dev, qw(cs8 115200 ignbrk -brkint -icrnl -imaxbel -opost
    -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke
    noflsh -ixon -crtscts);


while (1) {
    my $lastskip = 0;
    open my $fh, "<", (glob "/dev/ttyUSB*")[0] or die $!;
    while (<$fh>) {
        s/[\r\n]//g;
        my $msg = pack "H*", $_;
        if ($msg eq 'SKIP') {
            next if $lastskip > (time() - $minimum_time);
            get $url;
            $lastskip = time();
        }
    }
}
