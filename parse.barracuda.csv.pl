#!/usr/bin/perl -w
#vim: set ts=4 sw=4 sts=4 noet
#
# parse.barracuda.csv.pl - parse a Barracuda Spam Firewall CSV export to help hunt-down and destroy
#                          the old email addresses in a soon to be decommissioned domain
#                          @anthonykava                                       2020-04-03.1829.78-75

use strict;                                                             # semper
use warnings;                                                           # I AM ERROR
use Text::CSV;                                                          # for great parsing, take off every zig

# variables
my $type        = shift()||'';                                          # type of records to output (arg)
my $file        = shift()||'';                                          # CSV file (arg)
my @h           = ();                                                   # will hold headers from first line/array
my %doms        = ();                                                   # will hold count of From domains
my %rcpts       = ();                                                   # will hold count of To addresses
my %sizes       = ();                                                   # will hold messages and sizes
my %maxen       = qw/Time 0 From 0 To 0 Subject 0/;                     # init hash for max length() of t/de/a/s
my $truncLen    = 150;                                                  # chars at which to truncate long fields
$file='/dev/stdin' if !$file || $file eq '-';                           # - means STDIN, set $file value

# santity checks
die("\nUsage: $0 dom|rcpt|size|list [file.csv|-]\n\n")                  # die(), bad $type argument
    if $type!~/^[drsl]/i;                                               # <-- valid args, just first letters
die("FATAL: Problem with CSV file=${file}")                             # die(), CSV file issue
    if !$file || !-e $file;

# parse input
my $csv=Text::CSV->new({ binary => 1});                                 # instantiate Text::CSV object
if(open(my $fh,$file)) {
    while(my $aref=$csv->getline($fh)) {
        my @a=@$aref;                                                   # dereference from array ref to @a
        @h=(    'Classified','Time','From','To','Subject','Size',       # set headers to defaults if we're
                'Action','Reason','Score','Encryption Status',          # \ we're reading STDIN so that if
                'Source IP','Delivery Status','Destination Server',     #  \ we are grep(1)ing we are good
                'Delivery Detail' ) if $file eq '/dev/stdin';
        if(!@h) {                                                       # if we don't have headers yet ...
            @h=@a;                                                      # ... store this array in @h
        }
        else {                                                          # else ... process this line/array
            #Classified,Time,From,To,Subject,Size,Action,Reason,Score,
            #Encryption Status,Source IP,Delivery Status,Destination Server,Delivery Detail
            my %h=();                                                   # init hash %h for values
            $h{$h[$_]}=$a[$_] for(0 .. $#a);                            # set values in %h

            # update max length() vals when needed
            $h{'To'}=~s/\@.+$/@/ if defined($h{'To'});                  # strip 'To' domain
            foreach my $k (qw/Time From To Subject/) {
                if(defined($h{$k}) && $h{$k}) {                         # to suppress warnings and whatnot
                    chomp($h{$k});                                      # strip new line
                    $h{$k}=~s/^\s+//;                                   # strip leading spaces
                    $h{$k}=~s/\s+$//;                                   # strip trailing spaces
                    $h{$k}=sprintf('%s ...',substr($h{$k},0,$truncLen)) # truncate to $truncLen ...
                        if length($h{$k}) > $truncLen;                  # ... if we must
                    $maxen{$k}=length($h{$k})                           # store new world record ...
                        if length($h{$k}) > $maxen{$k};                 # ... if we exceeded the last
                }
                else {                                                  # if not defined, init as ''
                    $h{$k}='';
                }
            }

            # domains
            my $dom='';                                                 # init 'From' domain
            $dom=lc($1) if $h{'From'}=~/^[^\@]+\@(.+)$/;                # regex to grab domain
            $doms{$dom}++;                                              # increment counter

            # recipients
            my $rcpt='';                                                # init 'To' recipient
            $rcpt=lc($1) if $h{'To'}=~/^([^\@]+)\@/;                    # regex to grab local-part
            $rcpts{$rcpt}++;                                            # increment counter

            # sizes
            my $sizeKey=join("\x00",                                    # init key for hash %sizes
                $h{'Time'},$h{'From'},$h{'To'},$h{'Subject'});          #  \ key has msg details
            my $size=defined($h{'Size'}) && $h{'Size'}=~/^\d+$/ ?       # init 'Size' of message
                int($h{'Size'}) : 0;                                    #  \ 0 if NaN or !defined
            $sizes{$sizeKey}=$size;                                     # store the info and size
        }
    }
}
else {
    die("FATAL: Could not open CSV file=${file}");
}

# do output
if(!$type || $type=~/^d/i) {                                        # domains output
    foreach(sort { $doms{$a} <=> $doms{$b} } (keys(%doms))) {
        printf("%5d  %s\n",$doms{$_},$_);
    }
}
elsif($type=~/^r/i) {                                               # recipients output
    foreach(sort { $rcpts{$a} <=> $rcpts{$b} } (keys(%rcpts))) {
        printf("%5d  %s\n",$rcpts{$_},$_);
    }
}
elsif($type=~/^s/i) {                                               # sizes output
    foreach(sort { $sizes{$a} <=> $sizes{$b} } (keys(%sizes))) {
        s/[^\x00\x20-\x7e]//g;                                      # strip non-printable
        my($t,$de,$a,$s)=split(/\x00/,$_);                          # split our key into pieces
        printf( "%6.02f MiB  de:%-$maxen{'From'}s a:%-$maxen{'To'}s\n".
                "             s:%-$maxen{'Subject'}s\n".
                "             t:%-19s\n",
            defined($sizes{$_}) ? $sizes{$_}/1024/1024 : 0,$de,$a,$s,$t);
    }
}
elsif($type=~/^l/i) {                                               # list output
    foreach(sort(keys(%sizes))) {                                   # re-purpose %sizes
        s/[^\x00\x20-\x7e]//g;                                      # strip non-printable
        my($t,$de,$a,$s)=split(/\x00/,$_);                          # split our key into pieces
        printf( "%19s  %-$maxen{'From'}s  ->  a:%-$maxen{'To'}s  [ %-$maxen{'Subject'}s ]\n",
            $t,$de,$a,$s);
    }
}
