#!/usr/bin/perl -w
# vim: set ts=4 sw=4 et
#
# pbkdf2.to.john.or.hashcat.pl
# ----------------------------
#
# Generates a passwd file for John the Ripper  or hashcat mode 12000 hashes
# suitable for cracking passwords from PBKDF2-HMAC-SHA1 hashes found in CSV
# files that follow the format:
#
#   iterations:base64(salt):base64(hash)
#
# 2020-06-23.2324.78-75 / 2020-06-27.1343.78-75                @anthonykava
# =========================================================================
#
use strict;                                                 # of course
use warnings;                                               # always
use MIME::Base64 qw/decode_base64/;                         # for decoding Base64-encoded salt/hash
use Text::CSV qw/csv/;                                      # for parsing the CSV (apt install libtext-csv-perl)

# --   example output   --
# $ ./pbkdf2.to.john.or.hashcat.pl john File.csv
# username:$pbkdf2-hmac-sha1$1000.b6603b40174e6a4d4cb7523851aff09adb34cc79bdb6c258.f3e563f3bcb9a0ff23b9fb23427c5ad036a37723c09f5258:1:1:First Last::
#
# $ ./pbkdf2.to.john.or.hashcat.pl hashcat File.csv
# sha1:1000:tmA7QBdOak1Mt1I4Ua/wmts0zHm9tsJY:8+Vj87y5oP8jufsjQnxa0DajdyPAn1JY

# -- example john usage --
# $ ./pbkdf2.to.john.or.hashcat.pl john File.csv | john --format=PBKDF2-HMAC-SHA1 /dev/stdin
# Loaded 1 password hash (PBKDF2-HMAC-SHA1 [PBKDF2-SHA1 256/256 AVX2 8x])
# Cost 1 (iteration count) is 1000 for all loaded hashes
# badger1          (username)
# 1g 0:00:00:01 DONE 2/3 (2020-06-23 23:31) 0.5882g/s 15242p/s 15242c/s 15242C/s Pete..pepper1
# Use the "--show --format=PBKDF2-HMAC-SHA1" options to display all of the cracked passwords reliably
# Session completed

my $format=shift()||'john';                                 # output format, john|hashcat, default john
my $file=shift()||'File.csv';                               # file to read, default File.csv
die("\nUsage: $0 [john|hashcat] [File.csv]\n\n")            # sanity check and usage output
    if(!$file || !$format || $format!~/^[jh]/i || !-e $file);

$format=lc(substr($format,0,1));                            # j or h for output format
if(my $aoh=csv( in => $file, headers => 'lc' )) {           # get an array o' hashes using Text::CSV
    my $id=100000;                                          # base user id if we didn't find one
    foreach my $href (@$aoh) {                              # iterate through array of hashes
        my %h=%$href;                                       # dereference hash ref for convenience
        foreach(keys(%h)) {                                 # iterate through hash to clean values
            $h{$_}='' if !defined($h{$_});                  # init keys we might have missed this row
            $h{$_}=~s/[^\x20-\x7e]//g;                      # strip non-printable ASCII
            $h{$_}=~s/^\s+//;                               # remove leading spaces
            $h{$_}=~s/\s+$//;                               # remote trailing spaces
        }
        if($format eq 'h') {                                # hashcat format (no change, really)
            printf( "sha1:%s\n", $h{'password'} );          # just prepending 'sha1:'
        }
        else {                                              # John the Ripper format (like a passwd file)
            my($iter,$salt,$hash)=                          # get iterations, salt, hash from Password
                &splitPassword($h{'password'});

            my $uid=0;                                      # init user id value -- try to pull one
            if(defined($h{'securityid'})) {                 # for CSV files with Securityid
                $uid=$h{'securityid'};
            }
            elsif(defined($h{'registrationsid'})) {         # for CSV files with Registrationsid
                $uid=$h{'registrationsid'};
            }
            elsif(defined($h{'passwordhistoryid'})){        # for CSV files with PasswordHistoryID
                $uid=$h{'passwordhistoryid'};
            }
            else {
                $uid=++$id;                                 # fallback to $id incrementing value
            }

            my $username='';                                # init username value
            if(defined($h{'userid'})) {                     # for CSV files with Userid
                $username=$h{'userid'};
            }
            elsif(defined($h{'emailaddress'})) {            # for CSV files with EmailAddress
                $username=$h{'emailaddress'};
            }
            else {
                $username=sprintf('user-%d',$uid);          # fallback to user-${uid}
            }

            my $fullname='';                                # try to build a full name if possible
            $fullname.=$h{'firstname'}      if defined($h{'firstname'});
            $fullname.=' '.$h{'lastname'}   if  $fullname && defined($h{'lastname'});
            $fullname.=$h{'lastname'}       if !$fullname && defined($h{'lastname'});

            printf(                                         # john output
                "%s:\$pbkdf2-hmac-sha1\$%d.%s.%s:%d:%d:%s::\n",
                $username, $iter, $salt, $hash, $uid, $uid, $fullname
            );
        }
    }
}
else {                                                     # CSV did not parse
    die("FATAL: Error parsing CSV file='${file}'");
}

# splitPassword(password) -- takes Password string, returns iterations, salt and hash as hex strings
sub splitPassword {
    $_=shift()||'';
    my($iter,$salt,$hash)=(0,'','');                        # init variables
    if(/(\d+):([0-9a-zA-Z\/+=]+):([0-9a-zA-Z\/+=]+)/) {     # format is iterations:salt:hash
        $iter=$1;                                           # iterations (integer)
        $salt=unpack("H*", decode_base64($2));              # hex string for salt value
        $hash=unpack("H*", decode_base64($3));              # hex string for hash value
    }
    return($iter,$salt,$hash);
}
