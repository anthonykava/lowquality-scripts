#!/usr/bin/perl -w
# vim: set ts=4 sw=4 et
#
# combine.pbkdf2.pots.pl
# ======================
# Kludge written to combine my hashcat and john pot files so I don't duplicate
# efforts by wasting compute cycles cracking the same hashes again.  This is a
# one-off for a large collection of PBKDF2-HMAC-SHA1 hashes with a ton of long
# salt values.
#
# @anthonykava                                           2020-06-27.1313.78-75
#
use strict;                                                                 # for proper scopeage
use warnings;                                                               # for great justice
use MIME::Base64 qw/encode_base64 decode_base64/;                           # for Base64 encoding/decoding

my $stdout=shift()||'h';                                                    # 1st arg (see usage)
my $stderr=shift()||'';                                                     # 2nd arg (also see usage)
die("\n".                                                                   # talking of usage...
    "Usage: $0 h/j [h/j]\n".
    "\n".
    "      h/j = hashcat -or- john (as in John the Ripper) format\n".
    "  1st arg = format for STDOUT (defaults to hashcat)\n".
    "  2nd arg = format for STDERR (optional)\n".
    "\n".
    "  $0: What is my purpose?\n".
    "                                                   You combine PBKDF2-HMAC-SHA1 hashes from pot files.\n".
    "  $0: Oh, my god.\n".
    "\n".
    "  [ feed this thing pot files in STDIN ]\n".
    "\n".
    "  e.g.:\n".
    "    cat hashcat.potfile john.pot | $0 h j >big.hashcat.potfile 2>big.john.pot\n".
    "\n"
) if !$stdout || $stdout!~/^[hj]/i || ($stderr && $stderr!~/^[hj]/i);

my %out=(                                                                   # to check later, didn't want
    'hstd' => ( $stdout=~/^h/i ? 1 : 0 ),                                   #  to keep checking regen b/c
    'jstd' => ( $stdout=~/^j/i ? 1 : 0 ),                                   #  that's expensive,  and I'm
    'herr' => ( $stderr=~/^h/i ? 1 : 0 ),                                   #  cheap.
    'jerr' => ( $stderr=~/^j/i ? 1 : 0 ),
);

while(<>) {
    # example input:
    #   hashcat -> sha1:1000:O6z3B9X3VDuvJThY/xoLIlEHTHT9IwoV:U1x4ZEodplJJtO1xQSSgCivBufkp/mAu:tiptop
    #   john    -> $pbkdf2-hmac-sha1$1000$8ceb26d5ca278ca874d8e2278df0f98a0435a2348f3846c7$8387fdc5bc8a14f46d5b3e3e5a3c23cfd20caa03d73a840e:5499
    if(/^sha1:(\d+):([0-9a-zA-Z\/+=]+):([0-9a-zA-Z\/+=]+):(.+)$/i) {        # hashcat value
        my($iter,$b64_salt,$b64_hash,$plain)=($1,$2,$3,$4);                 # you gotta keep 'em separated
        print()         if $out{'hstd'};                                    # passthrough si hashcat STDOUT
        print STDERR $_ if $out{'herr'};                                    # passthrough si hashcat STDERR
        if($out{'jstd'} || $out{'jerr'}) {                                  # convert to john if needed
            my $salt=unpack("H*", decode_base64($b64_salt));                # Base64 -> hex string (salt)
            my $hash=unpack("H*", decode_base64($b64_hash));                # Base64 -> hex string (hash)
            printf("\$pbkdf2-hmac-sha1\$%d\$%s\$%s:%s\n",                   # john output STDOUT
                $iter,$salt,$hash,$plain) if $out{'jstd'};
            printf STDERR ("\$pbkdf2-hmac-sha1\$%d\$%s\$%s:%s\n",           # john output STDERR
                $iter,$salt,$hash,$plain) if $out{'jerr'};
        }
    }
    elsif(/^\$pbkdf2-hmac-sha1\$(\d+)\$([a-f0-9]+)\$([a-f0-9]+):(.+)$/i) {  # john value
        my($iter,$hex_salt,$hex_hash,$plain)=($1,$2,$3,$4);                 # split 'em up, up ,up
        print()         if $out{'jstd'};                                    # passthrough si john STDOUT
        print STDERR $_ if $out{'jerr'};                                    # passthrough si john STDERR
        if($out{'hstd'} || $out{'herr'}) {                                  # convert to hashcat if needed
            chomp(my $salt=encode_base64(pack("H*", $hex_salt)));           # hex string -> Base64 (salt)
            chomp(my $hash=encode_base64(pack("H*", $hex_hash)));           # hex string -> Base64 (hash)
            printf("sha1:%d:%s:%s:%s\n",                                    # hashcat output STDOUT
                $iter,$salt,$hash,$plain) if $out{'hstd'};
            printf STDERR ("sha1:%d:%s:%s:%s\n",                            # hashcat output STDERR
                $iter,$salt,$hash,$plain) if $out{'herr'};
        }
    }
}
