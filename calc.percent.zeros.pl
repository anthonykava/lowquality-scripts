#!/usr/bin/perl -w
# vim: set ts=4 sw=4 et
#
# calc.percent.zeros.pl -- read an input file, output stats including
#                          a percentage of 0x0 bytes vs. total bytes

use strict;                                             # semper
use warnings;                                           # errorus
use Getopt::Long;                                       # for command lining

# init a couple variables
my $z=0;                                                # count de 0x0s
my $b=0;                                                # count de bytes

# command line arguments, parsed
GetOptions(
    'file=s'        => \( my $file       = &findFileArg() ),
    'output=s'      => \( my $output     = 'human'        ),
    'blockSize=i'   => \( my $blockSizeM = 16             ),
    'printheaders'  =>   \my $headers,
    'help|?'        =>   \my $usage,
);
$headers=0 unless $headers;

die(    "\nUsage: $0 <file>\n\n".                       # show usage / help
        "\t[-f / --file='${file}'] (default STDIN)\n".  # file (STDIN default)
        "\t[-o / --output='${output}'] (human|tsv)\n".  # output format
        "\t[-b / --blocksizeM=${blockSizeM}]\n".        # block size in MiB
        "\t[-p / --printheaders]\n".                    # print headers
        "\t[ ? / --help]\n".                            # flag, to show help
        "\n"
) if $usage
    || !$file || !-e $file                              # need a good file
    || $output!~/^h|^t/i                                # valid output
    || 0;                                               # (chaser for an if)

# read the file and count 0x0s
if(open(my $fh,$file)) {                                # try to open the file
    while(read($fh,my $buf,( $blockSizeM * 2**20 ))) {  # read $blockSize bytes
        $b+=length($buf);                               # increment $b
        $z+=&countZeros($buf);                          # increment $z
    }
    close($fh) if $fh;                                  # close file handle
}
else {                                                  # couldn't open the file
    die("FATAL: Could not open file=${file}");
}

my $f=length("${b}");                                   # count chars for format
if($output=~/^t/i) {                                    # tsv output
    print join("\t",'file','0x0s','bytes','0perc') . "\n" if $headers;
    print join("\t",$file,$z,$b,( $b==0 ? -1 : $z/$b*100 )) . "\n";
}
else {                                                  # default to human
    printf( "\n".
            " file = %s\n".
            " 0x0s = %${f}d    ( %s )\n".
            "bytes = %${f}d    ( %s )\n".
            "0perc = %${f}.02f %%\n".
            "\n",
            $file,$z,&human($z),$b,&human($b),( $b==0 ? -1 : $z/$b*100 ) );
}

# findFileArg() -- searches @ARGV for file or defaults to /dev/stdin
sub findFileArg {
    my $ret='/dev/stdin';
    for my $i (0 .. $#ARGV) {
        if(-e $ARGV[$i]) {
            $ret=$ARGV[$i];
            last();
        }
    }
    return($ret);
}

# human($bytes=0) -- returns human-readable bytes like KiB, MiB, etc.
sub human {
    my $bytes=shift()||0;
    my $unit=( $bytes==1 ? 'byte' : 'bytes' );  # pedantic
    my $f='%7.02f';                             # default to float
    if($bytes>=2**40) {                         # if Mr. TiBs
        $unit='TiB';
        $bytes/=2**40;
    }
    elsif($bytes>=2**30) {                      # if Beegees
        $unit='GiB';
        $bytes/=2**30;
    }
    elsif($bytes>=2**20) {                      # if Russian jets
        $unit='MiB';
        $bytes/=2**20;
    }
    elsif($bytes>=2**10) {                      # if dog food
        $unit='KiB';
        $bytes/=2**10;
    }
    else {                                      # if plain byte(s) ...
        $f='%7d';                               # ... integer instead
    }
    return(sprintf("${f} %-5s", $bytes, $unit));
}

# countZeros($in='') -- returns number of 0x0 bytes
sub countZeros {
    my $in=shift()||'';
    my $ret=0;
    for(0 .. length($in)-1) {
        $ret++ if substr($in,$_,1) eq 0x0;
    }
    return($ret);
}
