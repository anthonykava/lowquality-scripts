#!/usr/bin/perl -w
# vim: set ts=4 sw=4 et
#
# ping.web.pl -- pings a web URL,  e.g., for hosts that don't
#                play well with others viz. ICMP echo replies
#                     @anthonykava      2020-01-27.1122.78-75

# essential modules and whatnot
use strict;                                     # mind the scope gap
use warnings;                                   # just in case w err
use Getopt::Long;                               # for command lining
use Socket qw/inet_ntoa/;                       # for resolving host
use Time::HiRes qw/time sleep/;                 # for a good ms time
use WWW::Curl::Easy;                            # for hitting an URL

# command line arguments, parsed
GetOptions(
    'url=s'             => \( my $url       = &findUrl()    ),
    'count=i'           => \( my $count     =  4            ),
    'timeout=i'         => \( my $timeout   =  3            ),
    'sleeptime=f'       => \( my $sleeptime =  1            ),
    'maxlinechars=i'    => \( my $maxline   = 32            ),
    'grabheaders'       =>   \my $grabheaders,
    'body'              =>   \my $body,
    'insecure'          =>   \my $insecure,
    'xcessive'          =>   \my $xcessive,
    'help|?'            =>   \my $usage,
);
$grabheaders=1 unless $body && !$grabheaders;   # always, unless not

die(                                            # show usage / helps
    "\nUsage: $0 <url>\n\n".
    "\t[-u / --url='${url}']\n".                # URL we are to ping
    "\t[-c / --count=${count}]\n".              # number of times to
    "\t[-t / --timeout=${timeout}]\n".          # timeout in seconds
    "\t[-s / --sleeptime=${sleeptime}]\n".      # sleep between ping
    "\t[-m / --maxline=${maxline}]\n".          # max chars to print
    "\t[-g / --grabheaders]\n".                 # flag, grab headers
    "\t[-b / --body]     # GET body\n".         # flag, headers only
    "\t[-i / --insecure] # don't verify TLS\n". # flag, don't verify
    "\t[-x / --xcessive] # continuous ping\n".  # flag, ping forever
    "\t[ ? / --help]\n".                        # flag, to show help
    "\n"
) if $usage
    || !$url || $url!~/^http/i                  # need a good URL oc
    || $count<1                                 # we need an int >=1
    || $timeout<0                               # need a little time
    || $sleeptime<0                             # no negative values
    || $maxline<0                               # no negative values
    || 0;                                       # (chaser for an if)

# variables and mirables
my $halt        =  0;                           # flag, end the pain
my $responses   =  0;                           # count of responses
my $roundTrips  =  0;                           # total of RTT times
my $roundTrips2 =  0;                           # liken ping(8) mdev
my $timeouts    =  0;                           # count of time-outs
my $errors      =  0;                           # count o' ye errors
my $maxRtt      = -1;                           # max RTT time aseen
my $minRtt      = -1;                           # min RTT time aseen
my $seq         =  0;                           # tracking number of
my $host        = &getHostName($url);           # hostname de la URL
my $pip         = gethostbyname($host);         # packed IP for host

# tofu and potatos
die("FATAL: Unable to resolve hostname '$host'") if !defined($pip);
printf("PING %s (%s) via '%s'\n",$host,inet_ntoa($pip),$url);
$SIG{INT}=sub { $halt=1; };                     # ^C stops the press
my $startTime=time();                           # time we started it
while(!$halt && --$count>=0) {                  # a big loop de loop
    # do the ping, per se
    my @response=();                            # array of our lines
    my $responseData='';                        # the raw data recvd
    my $curl = WWW::Curl::Easy->new;            # CURL object for us
    $curl->setopt(CURLOPT_URL, $url);
    $curl->setopt(CURLOPT_HEADER, $grabheaders ? 1 : 0);
    $curl->setopt(CURLOPT_HTTPHEADER, [ 'User-Agent: Karver-Web-Ping-0.1b' ] );
    $curl->setopt(CURLOPT_MAXREDIRS, 3);
    $curl->setopt(CURLOPT_TIMEOUT, $timeout);
    $curl->setopt(CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    $curl->setopt(CURLOPT_WRITEDATA, \$responseData);
    $curl->setopt(CURLOPT_NOBODY, 1) if !$body;
    if($insecure) {
        $curl->setopt(CURLOPT_SSL_VERIFYHOST, 0);
        $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);
    }
    #my $responseData='';                       # the raw data recvd
    my $sendTime=time();                        # stopwatch for ping
    my $retCode=$curl->perform;                 # now the CURLy deed
    my $recvTime=time();                        # record as end time
    my $roundTrip=($recvTime-$sendTime)*1000;   # RTT in millisecond
    my $bytes=0;                                # size of a response
    my $httpCode=-1;                            # HTTP code from svr
    if($retCode==0) {
        @response=split(/[\r\n]/,$responseData);
        $bytes=length($responseData);
        $responseData='';
        $httpCode=$curl->getinfo(CURLINFO_HTTP_CODE);
    }
    else {
        my $retCodeExtra='';
        $retCodeExtra="\t[ Not recommended: You can use --insecure to ignore certificate problems ]\n"
            if $retCode==60;
        print STDERR "CURL ERROR ping_seq=$seq: retCode=${retCode}\n".
            "\t".$curl->strerror($retCode)."\n".
            "\t".$curl->errbuf."\n".
            $retCodeExtra;
    }
    undef($curl);

    # parse server's response
    my $firstLine='';                           # hold 1st line back
    for my $i (0 .. $#response) {
        chomp($response[$i]);                   # say no to new line
        $response[$i]=~s/[^\x20-\x7e]/./g;      # printable only plz
        $response[$i]=substr(                   # truncate to X many
            $response[$i],0,$maxline);
        if($response[$i]) {                     # look for non-blank
            $firstLine=$response[$i];           # set $firstLine val
            $firstLine.='...'                   # append ... if long
                if length($firstLine)>=$maxline;
            last();                             # no mas, per favore
        }
    }

    # extract server time for fun and non-profit (see ping.php below)
    my $svrTime=0;
    $svrTime=$1 if $firstLine=~/^([\d\.]+)$/;

    # handle the response or lack thereof
    if($firstLine && $roundTrip<$timeout*1000) {
        if($svrTime>0) {
            printf( "%d %s from %s: ping_seq=%d time=%.01f ms [ HTTP %03d: '%s' @ %.02f Kbps ]\n",
                $bytes,
                $bytes==1 ? 'byte' : 'bytes',
                $host,
                $seq++,
                $roundTrip,
                $httpCode,
                scalar(localtime($svrTime)),
                $roundTrip>0 ? (($bytes/($roundTrip/1000))*8)/1024 : -1,
            );
        }
        else {
            printf( "%d %s from %s: ping_seq=%d time=%.01f ms [ HTTP %03d: '%s' @ %.02f Kbps ]\n",
                $bytes,
                $bytes==1 ? 'byte' : 'bytes',
                $host,
                $seq++,
                $roundTrip,
                $httpCode,
                $firstLine,
                $roundTrip>0 ? (($bytes/($roundTrip/1000))*8)/1024 : -1,
            );
        }
        $roundTrips+=$roundTrip;
        $roundTrips2+=$roundTrip*$roundTrip;
        $responses++;
        $maxRtt=$roundTrip if $roundTrip>$maxRtt;
        $minRtt=$roundTrip if $roundTrip<$minRtt || $minRtt==-1;
    }
    elsif($roundTrip>=$timeout*1000) {
        printf( "TIME-OUT for %s: ping_seq=%d time=%.01f ms [ HTTP %03d: %s ]\n",
            $host,
            $seq++,
            $roundTrip,
            $httpCode,
            $firstLine );
        $timeouts++;
    }
    else {
        my $extra='';
        $extra=sprintf(' [ HTTP %03d: %s ]',$httpCode,$firstLine) if $httpCode>0;
        $extra=sprintf(' [ %s ]',$firstLine) if !$extra && $firstLine;
        printf( "** ERROR for %s: ping_seq=%d time=%.01f ms%s\n",
            $host,
            $seq++,
            $roundTrip,
            $extra );
        $errors++;
    }

    $count=1 if $xcessive;                  # in continuous mode
    sleep($sleeptime) if !$halt && $count;  # perchance to sw0ne
}

printf( "\n--- %s ping statistics ---\n".
        "%d requests transmitted, %d responses, %d%% loss, %d timeouts, %d errors, time %dms\n".
        "rtt min/avg/max/mdev = %.03f/%.03f/%.03f/%.03f ms\n",
        $host,
        $seq,
        $responses,
        $seq>0 ? 100-($responses/$seq*100) : -1,
        $timeouts,
        $errors,
        (time()-$startTime)*1000,
        $minRtt,
        $responses>0 ? $roundTrips/$responses : -1,
        $maxRtt,
        $responses>0 ? sqrt($roundTrips2/$responses - ($roundTrips / $responses)**2 ) : -1 );

# fin -- exit true (0) if we got responses, false (1) if we didn't
exit($responses>0 ? 0 : 1);

##############################################
### END OF MAIN PROCEDURE, CAN YOU DIG IT? ###
##############################################

# getHostname(URL) -- returns hostname part of http/https URL
sub getHostName {
    $_=shift()||'';
    return($1) if /^https?:\/+([^\/]+)/i;
}

# findUrl() -- searches @ARGV for URLs to feed to $url
sub findUrl {
    my $ret='';
    for my $i (0 .. $#ARGV) {
        if($ARGV[$i]=~/^https?:/) {
            $ret=$ARGV[$i];
            last();
        }
    }
    return($ret);
}

# <!-- optional PHP code for ping.php follows (place on server) -->
# <?php
#   // Prevent caching
#   header('Expires: Sun, 01 Jan 2014 00:00:00 GMT');
#   header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
#   header("Cache-Control: post-check=0, pre-check=0", false);
#   header("Pragma: no-cache");
#
#   echo microtime(true)."\n";
# ?>
