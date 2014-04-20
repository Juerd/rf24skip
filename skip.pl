#!/usr/bin/perl -w
use strict;
use Time::HiRes qw(time);
use LWP::Simple qw(get);
use POSIX qw(strftime tcflush TCIFLUSH);

use IO::Socket;
use IO::Socket::INET;

use Net::MQTT::Constants;
use Net::MQTT::Message;
use IO::Select;

my $verbose = 0;
my $stdin_buf = '';
my $sock_buf = '';
my $mid = 1;
my $next_ping;
my $got_ping_response = 1;
# Defaults
my $mqtthost = "127.0.0.1";
my $mqttport = "1883";
my $keep_alive_timer = 60;

our $mqttsocket = IO::Socket::INET->new(PeerAddr => $mqtthost.':'.$mqttport,
                        Timeout => $keep_alive_timer,
                       ) or die "Socket connect failed: $!\n";

sub ledbanner {
    my $ledsocket = IO::Socket::INET->new(qw/PeerAddr 10.42.76.66 PeerPort 12345 Proto udp/)
        or warn $!;
    $ledsocket->send(shift);
    close $ledsocket;
}

# Send an MQTT (low-level) message
sub send_message {
  my $socket = shift;
  my $msg = Net::MQTT::Message->new(@_);
  print 'Sending: ', $msg->string, "\n" if ($verbose >= 2);
  $msg = $msg->bytes;
  syswrite $socket, $msg, length $msg;
  print dump_string($msg, 'Sent: '), "\n\n" if ($verbose >= 3);
  $next_ping = Time::HiRes::time + $keep_alive_timer;
}

# MQTT Message - high-level
sub mqtt {
    my ($topic, $message, $retain) = @_;

    send_message($mqttsocket,
        message_type => MQTT_PUBLISH,
        retain => $retain,
        topic => "/revspace/" . $topic,
        message => $message);
}


# Connect to MQTT broker
send_message($mqttsocket, message_type => MQTT_CONNECT,
             keep_alive_timer => $keep_alive_timer);

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
        mqtt( "sensors/co2", $co2, 1 );
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

        mqtt( "button/skip", "Skip pressed") if ( $type eq "SKIP" );
        mqtt( "button/nomz", "NOMZ pressed") if ( $type eq "NOMZ" );
        mqtt( "button/shuffle", "Shuffle pressed") if ( $type eq "SHUF" );
        mqtt( "button/stop", "Stop pressed") if ( $type eq "STOP" );

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

