#!/usr/bin/perl -w
# vim: set ts=4 sw=4 noet
#
# fuse.real.fake.files.pl  FUSE driver for creating a file system
#                          with fake files for whatever you need.
#
#                          Made because I needed dummy 3 TB files
#                          of 0x0 for some RAID reassembly, quick
#                          and/or dirty.  Definitely dirty.
#
#                          NO WARRANTY - AS IS - PROOF OF CONCEPT
#                          @anthonykava "karver" 2020-02-28
#
#   Example use (no root/sudo required):
#
#               $ ./fuse.real.fake.files.pl 4 3T 0x0 mnt/
#               ^-- makes a FS with 4x 3 TiB files of 0x0 at mnt/
#
# Uses Fuse Perl module found thuswhere:
#
#   http://search.cpan.org/dist/Fuse/
#
#   Debian/Ubuntu can usually do: apt install libfuse-perl
#
#   https://github.com/dpavlin/perl-fuse.git
#   (This script has roots in 'examples/example.pl' from the repo)
#
#   Perl module pre-reqs: Cwd, File::Basename, Fuse, POSIX

use strict;                                                 # of course
use warnings;                                               # helpful
use Cwd             qw/cwd abs_path/;                       # for resolving relative paths
use File::Basename  qw/basename/;                           # for getting basename from path
use Fuse            qw/fuse_get_context/;                   # kinda the point
use POSIX           qw/ENOENT EISDIR EINVAL/;               # values for FUSE

#     _,.-~'{    VARIABLES   }`~-.,_

my $usage           = "\tUsage: $0 numFiles fileSize hexVal mntPoint [debug] [stayAttached]\n";
my $numFiles        = shift()||4;                           # number of files
my $fileSize        = shift()||'3T';                        # size of each file
my $hexVal          = shift()||'0x0';                       # hex value for file content
my $mntPoint        = shift()||'mnt';                       # Mount point
my $debug           = shift()||0;                           # 0=none, 1=some
my $stayAttached    = shift()||0;                           # 0=be daemon-like, 1=stay

# Prepare parameters
$numFiles=$numFiles=~/^\d+$/ ? int($numFiles) : 0;          # force int
$fileSize=~s/[^0-9KMGTP]//gi;                               # reduce to nums and units
if($fileSize=~/^(\d+)([KMGTP])/i) {                         # if not all nums...
    my($num,$unit)=(int($1),uc($2));                        # split num from unit type
    $num*=2**10 if $unit eq 'K';                            # calc KiB
    $num*=2**20 if $unit eq 'M';                            # calc MiB
    $num*=2**30 if $unit eq 'G';                            # calc GiB
    $num*=2**40 if $unit eq 'T';                            # calc TiB
    $num*=2**50 if $unit eq 'P';                            # calc PiB
    $fileSize=$num>=0 ? $num : 0;
}
$hexVal=~s/^0x//i;                      # drop leading 0x
if($hexVal=~/^([0-9a-f]{1,2})/i) {      # grab first hex byte
    $hexVal=pack("H*",$1);
}
else {
    $hexVal='';                         # clear $hexVal if it's wrong
}

#     _,.-~'{     SET-UP     }`~-.,_

# Test parameters
die($usage) if  0
    || $numFiles<1
    || $fileSize<0
    || !$hexVal
    || !$mntPoint;

# Make $mntPoint if it doesn't exist, resolve to absolute path (FUSE wants)
mkdir($mntPoint) if !-e $mntPoint;
$mntPoint=abs_path($mntPoint) if -e $mntPoint;
die("FATAL: mntPoint=${mntPoint} is not a dir") if !-d $mntPoint;

# Build our file system layout as arrays of files in %fs (keys are dirs)
my %fs=('/' => []);
my %paths=('/' => -1);
for my $i (0 .. $numFiles-1) {
    my $file=sprintf('%08d',$i);
    push(@{ $fs{'/'} },$file);
    $paths{sprintf('/%s',$file)}=$fileSize;
}

#     _,.-~'{ MAIN PROCEDURE }`~-.,_

&daemonise() if !$stayAttached;         # fork-off
Fuse::main(                             # FUSE tofu & potatoes
    mountpoint  =>  $mntPoint,          # <-- mount point here
    mountopts   =>  'ro,allow_other',
    getattr     =>  "main::e_getattr",
    getdir      =>  "main::e_getdir",
    open        =>  "main::e_open",
    statfs      =>  "main::e_statfs",
    read        =>  "main::e_read",
    threaded    =>  0
);

#     _,.-~'{  SUB-ROUTINES  }`~-.,_

# e_getattr($file) -- handler for returning FS attributes
sub e_getattr {
    my $path=shift()||'.';
    my @ret=(-ENOENT());                # default no entity
    &debug("e_getattr($path)");

    my $blockSize=2**10 * 64;                                                           # our preferred block size
    my $size=$blockSize;                                                                # default $size to 1 block
    my $modes=(0100<<9) + 0444;                                                         # default mode to regular file 0444
    my($dev,$ino,$rdev,$blocks,$gid,$uid,$nlink,$blksize)=(0,0,0,1,0,0,1,$blockSize);   # init stat details
    my($atime,$ctime,$mtime)=(time(),time(),time());                                    # MAC times are now

    # If $path is meant to be a directory (e.g., /, ., 2016, 2016/06, 2016/06/29
    my $dirTest='/'.$path;
    if($path eq '/' || $path eq '.' || $fs{$path} || $fs{$dirTest}) {                   # directory
        $modes=(0040<<9)+0555;  # 0555 mode dir
        @ret=($dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
    }
    elsif($paths{$path} || $paths{$dirTest}) {                                          # regular file
        $modes=(0100<<9)+0444;  # 0444 mode file
        $size=$fileSize;
        @ret=($dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
    }
    return(@ret);
}

# e_getdir($dir) -- handler for returning dir entries
sub e_getdir {
    my $dir=shift()||'/';                           # / default, why not
    my @ret=();
    &debug("e_getdir($dir)");
    @ret=@{ $fs{'/'} } if $dir eq '/' || $dir eq '.';
    debug("should show fs dir=$dir now, fs{$dir}=@{ $fs{$dir} }");
    return(@ret,0);         # no, I don't know what the last element '0' means
}

# e_open($file) -- handler for opening files, returns file handle
# "VFS sanity check; it keeps all the necessary state, not much to do here."
sub e_open {
    my $file=shift()||'.';
    my($flags,$fileinfo)=@_;
    my @ret=(-ENOENT());

    # e.g., open called 2015/12/30/2015-17184.pdf, 32768, HASH(0x183cfe8)
    &debug("open called $file, $flags, $fileinfo");

    # If $file is meant to be a directory (e.g., /, ., 2016, 2016/06, 2016/06/29
    my $dirTest='/'.$file;
    if($file eq '/' || $file eq '.' || $fs{$file} || $fs{$dirTest}) {   # directory
        @ret=(-EISDIR());   # error: this is a dir, mate
    }
    elsif($paths{$file}) {                      # if $file is meant to be a file
        @ret=(0,rand());                        # random file handle for appearances
    }
    &debug("open ok for file=$file (handle $ret[1])") if $ret[1];
    return(@ret);
}

# e_read($file) -- handler for reading files
# "return an error numeric, or binary/text string.  (note: 0 means EOF, "0" will"
# "give a byte (ascii \"0\") to the reading program)"
sub e_read {
    my $path=shift()||'.';
    my($buf,$off,$fh)=@_;
    my $ret=-ENOENT();
    &debug("read from $path, $buf \@ $off");
#   e.g., read from 2015/02/19/2015-01842.pdf, 4096 @ 0

    my $dirTest='/'.$path;
    if($path eq '/' || $path eq '.' || $fs{$path} || $fs{$dirTest}) {   # directory
        $ret=-ENOENT();     # error: this is a dir, mate [NOENT for this read]
    }
    else {
        my $size=$fileSize;
        if(!$size) {
            $ret=-ENOENT();                                 # give FS error if this failed
        }
        elsif($off>$size) {
            $ret=-EINVAL();                                 # invalid FS error if reading beyond end
        }
        elsif($off==$size) {
            $ret=0;                                         # return 0 if we're done reading
        }
        else {
            $ret=$hexVal x $buf;                            # return $buf byte(s) of $hexVal
        }
    }
    return($ret);
}

# e_statfs() -- gives FS stats to OS, but I don't understand it yet
sub e_statfs { return 255, 1, 1, 1, 1, 2 }

# daemonise([$logfile]) -- forks-off so we can play like a daemon
# stolen from 'examples/loopback.pl' from the GitHub repo
# "Required for some edge cases where a simple fork() won't do."
# "from http://perldoc.perl.org/perlipc.html#Complete-Dissociation-of-Child-from-Parent"
sub daemonise {
    my $logfile=shift()||sprintf('%s/log.%s',cwd(),basename($0));       # log file in pwd unless passed
    chdir("/")||die("can't chdir to /: $!");
    open(STDIN,'<','/dev/null')||die("can't read /dev/null: $!");       # redir STDIN (/dev/null)
    open(STDOUT,'>>',$logfile)||die("can't open logfile: $!");          # redir STDOUT to log file
    defined(my $pid=fork())||die("can't fork: $!");                     # when you come to a fork()...
    exit(0) if $pid;                                                    # "non-zero now means I am the parent"
#   (setsid() != -1) || die "Can't start a new session: $!";            # (didn't use this)
    open(STDERR,'>&',\*STDOUT)||die("can't dup stdout: $!");            # STDERR to STDOUT
}

# debug($msg[,$lvl=1]) -- print timestamp and $msg if $debug>=$lvl
sub debug {
    my $msg=shift()||'';
    my $lvl=shift()||1;
    if($debug>=$lvl) {
        chomp($msg);
        print STDERR sprintf("%s\t%d\t%s\n",&ansi(),$$,$msg) if $msg;
    }
}

# ansi($time=time()]) -- return "ANSI" style YYYY-MM-DD HH:mm:ss time
sub ansi {
    my $time=shift()||time();
    my @l=localtime($time);
    return(sprintf('%04d-%02d-%02d %02d:%02d:%02d',
            $l[5]+1900,$l[4]+1,$l[3],$l[2],$l[1],$l[0]));
}
