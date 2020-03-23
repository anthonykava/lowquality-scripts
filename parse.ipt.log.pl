#!/usr/bin/perl -w
# vim: set ts=4 sw=4 et
#
# parse.ipt.log.pl -- parses kernel messages for netfilter LOG target output
#                     based on my personal standard ipt.accept / ipt.drop
#                     intended for easier human reading and greppage
#
#                     @anthonykava                     2020-03-20.1206.78-75
#
# ** example input/output **
#Mar 20 10:10:04 hostname kernel: ipt.drop: IN= OUT=eth0 SRC=10.0.0.1 DST=1.2.3.4 LEN=76 TOS=0x00 PREC=0xC0 TTL=64 ID=50644 DF PROTO=UDP SPT=123 DPT=123 LEN=56 
#2020-03-20 10:10:04  ipt.drop    udp         10.0.0.1:123    ntp             ->      1.2.3.4:123    ntp             [i: o:eth0, 76 byte(s)]

use strict;                                                                     # of course
use warnings;                                                                   # why not?

my %mons=&loadMonths();                                                         # get a %hash of month names to numbers
my %services=&loadServices();                                                   # get a %hash of port/proto service names
my $sMax=$services{'maxLen'};                                                   # len of longest service name for printf()

while(<>) {                                                                     # iterate on input (file arg or STDIN)
    #Mar 20 10:10:04 hostname kernel: ipt.drop:
    #IN= OUT=eth0 SRC=10.0.0.1 DST=1.2.3.4
    #LEN=76 TOS=0x00 PREC=0xC0 TTL=64 ID=50644 DF PROTO=UDP SPT=123 DPT=123 LEN=56 
    if(/^(\w{3})\s([\s\d]{2})\s(\d{2}):(\d{2}):(\d{2})\s.+kernel:(.+)\s
        IN=([^\s]*).*\sOUT=([^\s]*).*\sSRC=([\d\.]*).*\sDST=([\d\.]*).*\s
        LEN=(\d*).*\sPROTO=([^\s]*).*\sSPT=(\d*).*\sDPT=(\d*)/x) {              # /x to allow breaking-up this long regex
        my($mon,$day,$hour,$min,$sec,$logType,$ifIn,$ifOut,$ipSrc,$ipDst,       # variables we pull
            $len,$proto,$portSrc,$portDst)=($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14);
        my $year=(localtime())[5]+1900;                                         # year from localtime() -- just a guess
        my $portSrcKey=sprintf('%d/%s',$portSrc,lc($proto));                    # e.g., 3389/tcp
        my $portDstKey=sprintf('%d/%s',$portDst,lc($proto));                    # e.g., 3389/tcp
        my $portSrcSvc=$services{$portSrcKey}||'';                              # get service name from %services
        my $portDstSvc=$services{$portDstKey}||'';                              # get service name from %services
        $logType=~s/[\s:]//g;                                                   # clean-up $logType
        
        # output a formatted line
        printf("%04d-%02d-%02d %02d:%02d:%02d  %-10s  %-5s %15s:%-5d  ".
            "%-${sMax}s -> %15s:%-5d  %-${sMax}s [i:%s o:%s, %d byte(s)]\n",
            $year,$mons{lc($mon)},$day,$hour,$min,$sec,$logType,lc($proto),
            $ipSrc,$portSrc,$portSrcSvc,$ipDst,$portDst,$portDstSvc,$ifIn,$ifOut,$len);
    }
}

# loadMonths() -- returns a %hash for converting month abbreviated names to numbers
sub loadMonths {
    return(qw/jan 1 feb 2 mar 3 apr 4 may 5 jun 6 jul 7 aug 8 sep 9 oct 10 nov 11 dec 12/);
}

# loadServices() -- returns a %hash like 123/udp -> ntp, also 'maxLen' is the longest service name
sub loadServices {
    my %ret=qw/maxLen 0/;                                                       # holds our max length()
    my $file='/etc/services';                                                   # pretty standard, really
    if(-e $file && open(my $fh,$file)) {                                        # if things work...
        foreach(<$fh>) {                                                        # iterate through $file
            chomp();                                                            # yeet new line
            s/^\s+//;                                                           # remove leading spaces
            #com-bardac-dw   48556/tcp               # com-bardac-dw            # <-- EXAMPLE
            if(/^([^\#\s]+)\s+(\d+)\/([^\s]+)/) {                               # match example, not comments
                my($service,$port,$proto)=($1,$2,$3);                           # three being the number
                my $key=sprintf('%d/%s',$port,lc($proto));                      # prep key for our %hash
                $ret{$key}=$service if !$ret{$key};                             # store if it's our first
                $ret{'maxLen'}=length($service)                                 # update maxLen if needed
                    if length($service)>$ret{'maxLen'};
            }
        }
        close($fh);                                                             # close that file handle
    }
    return(%ret);                                                               # pass %hash on the left-hand side
}
