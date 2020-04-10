#!/usr/bin/perl -w
# vim: set ts=4 sw=4 noet
#
# count.ip.generic.pl -- parse text, count number of lines with an IP, nothing
#                        super fancy, also track /24, suitable for grep net:
#                        @anthonykava                    2020-04-09.1245.78-75
#
# example:  $ count.ip.generic.pl < access_log | sort -n | tail -3
#              567   ip: 4.3.2.1  
#              567  net: 4.3.2.0/24 
#             1508   ip: 5.4.3.2 
#             1508  net: 5.4.3.0/24
#             1527   ip: 6.5.4.3    
#             1742  net: 6.5.4.0/24 
use strict;                                             # for the scope
use warnings;                                           # for the help
use Socket qw/inet_aton inet_ntoa/;                     # for converting IPs to/from decimal

# variables
my $threshold   = shift()||2;                           # print results for >=$threshold hits
my %ipHits      = ();                                   # hash to store IP counts
my %netHits     = ();                                   # hash to store /24 counts

# parse input
while(<>) {                                             # iterate through input
    foreach my $ipDot (/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/g) {
        $ipHits{unpack('N',inet_aton($ipDot))}++;       # count decimal IP addresses
        my $netDot=$ipDot;                              # gonna wanna convert last octet
        $netDot=~s/\.\d{1,3}$/.0/;                      # replace last octet with .0 (lazy)
        $netHits{unpack('N',inet_aton($netDot))}++;     # count decimal net (/24) addresses
    }
}

# output results
foreach my $ip (sort(keys(%ipHits))) {                  # iterate through the IP hash
    my $ipDot=inet_ntoa(pack('N',int($ip)));            # convert numeric IP to dotted decimal
    printf("%6d   ip: %-15s\n",$ipHits{$ip},$ipDot)
        if $ipHits{$ip} >= $threshold;                  # only printing when hits>=$threshold
}

# output results
foreach my $net (sort(keys(%netHits))) {                # iterate through the network hash
    my $netDot=inet_ntoa(pack('N',int($net)));          # convert numeric net to dotted decimal
    printf("%6d  net: %-15s\n",$netHits{$net},$netDot.'/24')
        if $netHits{$net} >= $threshold;                # only printing when hits>=$threshold
}
