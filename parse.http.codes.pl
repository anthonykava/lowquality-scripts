#!/usr/bin/perl -w
# vim: set ts=4 sw=4 noet
#
# parse.http.codes.pl -- parse httpd log, show hits for each IP + response code
#                        output suitable for piping through 'sort -n' (count 1st)
#                        @anthonykava                       2020-04-02.1407.78-75
#
# example:  $ parse.http.codes.pl < access_log | grep c=403 | sort -n | tail -3
#           4062  4.3.2.1          c=403
#           6871  5.4.3.2          c=403
#           7227  6.5.4.3          c=403

use strict;                                             # for the scope
use warnings;                                           # for the help
use Socket qw/inet_aton inet_ntoa/;                     # for converting IPs to/from decimal

# variables
my $threshold   = shift()||2;                           # print results for >=$threshold hits
my %codeHits    = ();                                   # hash to store count of IP+response code

# parse input
while(<>) {                                             # iterate through input
    # 1.2.3.4 - - [01/Apr/2020:01:02:30 -0400] 
    # "GET /admin/ HTTP/1.0" 200 29 "https://1.2.3.4/admin/" "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1)"
    if(/^([\d\.:]+)\s+([^\s]+)\s([^\s]+)\s+\[(\d{2})\/(.{3})\/(\d{4}):(\d{2}):(\d{2}):(\d{2})\s([+\-\d]{5})\]\s+
        "([^\s]+)\s+([^\s]+)\s+([^"]+)"\s+(\d+)\s+(\d+)\s+"([^"]+)"\s+"([^"]+)"/x) {    # /x to split regex
        my($ip,$foo,$user,$dom,$mon,$y,$h,$m,$s,$tz,$meth,$req,$proto,$code,$bytes,$referer,$ua)=
            ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17);
        my $ipaddr=inet_aton($ip);                      # convert dotted decimal IP to binary
        my $ipnum=unpack('N',$ipaddr);                  # unpack binary IP to a decimal number
        my $key=sprintf('%d|%010d',$ipnum,$code);       # build key for hash, zero-pad IP
        $codeHits{$key}++;                              # increment our count
    }
}

# output results
foreach my $key (sort(keys(%codeHits))) {               # iterate through the hash
    my($ipnum,$code)=split(/\|/,$key,2);                # split key into numeric IP, code
    my $ip=inet_ntoa(pack('N',int($ipnum)));            # convert numeric IP to dotted decimal
    printf("%6d  %-15s  c=%3d\n",$codeHits{$key},$ip,$code)
        if $codeHits{$key} >= $threshold;               # only printing when hits>=$threshold
}
