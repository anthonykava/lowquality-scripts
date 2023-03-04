#!/usr/bin/perl -w

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# / comments.pl: quick & dirty tool to show comments from a file or http/s URL /
# \              there will be false-(positives|negatives) note: quick & dirty \
# / @anthonykava                                               2023-03-04.1337 /
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

use strict;                                                 # of course
use warnings;                                               # why not?

# $url as argument, if not ^http then we assume it's a file
my $url=shift()||die("\nusage: $0 'url|filename'\n\n");     # needs a single arg
$url='file:'.$url if &ltrim($url)!~/^http/i;                # files get ^file:
$url=~s/[\'\"\`\!]//g;                                      # minor sanitisation

# we'll be running $cmd and parsing its output lines
my $cmd="wget --no-check-certificate -qO - '${url}'";       # default wget(1)
if($url=~/^file:(.+)$/) {                                   # if file: ...
    die("file not found: $1") if !-e $1;                    # check exists
    $cmd="cat '$1'";                                        # cat(1) for files
}

# tofu and potatoes
my $in=0;                                                   # flag for in block
my $ln=0;                                                   # line number
foreach(`${cmd}`) {                                         # iter. on output
    $ln++;                                                  # increment line no.
    chomp();                                                # no new lines
    s/^\s+//;                                               # trim leading space
    s/\s+$//;                                               # trim trailing
    if(/(\/\/.+)$/) {                                       # '//' comment
        printf("%5d: %s\n",$ln,$1) if !/((url|=)\s*[\(\"\']\s*|https?:)\Q$1\E/i;
    } elsif(/(#.+)$/) {                                     # '#' comment?
        $_=$1;
        s/\#([A-Fa-f0-9]{3}|[A-Fa-f0-9]{6})[\;\"\'\s]//g;   # try to del colours
        printf("%5d:  %s\n",$ln,$1) if /(\/\/|\#.+)$/;      # test again
    } elsif(/(\/\*.*)$/) {                                  # start of a block
        $_=$1;
        s/(\*\/).*$/$1/;                                    # trim trailing bits
        printf("%5d: [] %s\n",$ln,$_);
        $in=1 unless /\*\//;                                # set flag unless
    } elsif($in) {                                          # lines in block
        printf("%5d: \\- %s\n",$ln,$1) if  /(.*\*\/).*$/;   # trim trailing bits
        printf("%5d: \\- %s\n",$ln,$_) if !/(.*\*\/).*$/;   # fully within block
        $in=0 if /\*\//;                                    # unset flag
    }
}

# ltrim($_='') -- trim leading spaces from string $_ and return it
sub ltrim {
    $_=shift()||'';
    s/^\s+//;
    return($_);
}
