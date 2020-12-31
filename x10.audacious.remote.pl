#!/usr/bin/perl -w
# ------------------------------------------------------------------------------
# | x10.audacious.remote.pl                                                    |
# ------------------------------------------------------------------------------
# We read serial data from a port connected to an X10 JR21A receiver in order to
# receive button presses from the X10 JR20A remote.  MisterHouse says this thing
# should be 1200/8N1, but 2400/8N1 worked for me.  We will use the signals trig-
# ger us to send commands to the wonderful Audacious audio player.
# ------------------------------------------------------------------------------
# | https://forensic.coffee                            @anthonykava 2020-12-30 |
# ------------------------------------------------------------------------------

use strict;                         # of course
use warnings;                       # why not?
use Device::SerialPort;             # for serial comms

my $debug   = shift() || 1;         # debug (0=none, 1=some)
my $favDir  = '/musica.favorita/';  # SELECT button copies playing mp3 here
my $audtool = '/usr/bin/audtool';   # location of audtool(1)
my $comPort = '/dev/ttyUSB0';       # our serial device
my $comBaud = 2400;                 # baud rate
my $comMode = '8N1';                # settings (databits, parity, stop bits)
my $bytes   = 4;                    # bytes to read at a time
my %codes   = &initCodesTable();    # hash of 4-byte codes in hexit
my $lastCode= '';                   # holds last code received (we get dups)
my $lastTime= time();               # holds epoch time of last code
my $lastVol = &aud('get-volume');   # last volume level (e.g., for unmute)

die( "fatal: ${audtool} not found" ) if !-e $audtool;
die( "fatal: ${comPort} not found" ) if !-e $comPort;
die( "fatal: failed to get-volume" ) if $lastVol !~ /^\d+$/;
while( my $port = &initPort() ) {   # returns Device::SerialPort object
    warn( "listening on ${comPort} (${comBaud}/${comMode})" ) if $debug;
    while( $port ) {
        my( $count, $data ) = $port->read( $bytes );
        if( $count ) {
            # unpack binary to hexits for convenience
            my $code = unpack( 'H*', substr($data, 0, 4));

            # ignore duplicate codes for a second
            if( $code ne $lastCode || time() != $lastTime ) {
                my $f = defined( $codes{$code} ) ?
                    $codes{$code} : '(unknown)';
                printf STDERR ( "[ %-12s ] [ %-8s ]\n",
                    $f, $code ) if $debug;

                my($cmd,$arg)=('','');
                if      ( $f eq 'select'   )    { &favourite();                     }
                elsif   ( $f eq 'channelUp'   ) { $cmd = 'playlist-advance';        }
                elsif   ( $f eq 'channelDown' ) { $cmd = 'playlist-reverse';        }
                elsif   ( $f eq 'play'        ) { $cmd = 'playback-play';           }
                elsif   ( $f eq 'stop'        ) { $cmd = 'stopback-stop';           }
                elsif   ( $f eq 'pause'       ) { $cmd = 'playback-pause';          }
                elsif   ( $f eq 'a-b'         ) { $cmd = 'playlist-shuffle-toggle'; }
                elsif   ( $f eq 'mute'        ) {
                    $cmd = 'set-volume';
                    if( &aud('get-volume') == 0 ) {     # already muted (toggle)
                        $arg = $lastVol;                # restore to last volume
                    } else {                            # not muted ...
                        $lastVol = &aud('get-volume');  # store last volume level
                        $arg = 0;                       # set to 0 (mute)
                    }}
                elsif   ( $f eq 'volumeUp'    ) {
                    $cmd = 'set-volume';
                    $lastVol = &aud('get-volume');
                    if( $lastVol >= 95 ) {
                        $arg = 100;
                    } else {
                        $arg = $lastVol + 5;
                    }}
                elsif   ( $f eq 'volumeDown'  ) {
                    $cmd = 'set-volume';
                    $lastVol = &aud('get-volume');
                    if( $lastVol <= 5 ) {
                        $arg = 0;
                    } else {
                        $arg = $lastVol - 5;
                    }}
                elsif   ( $f eq 'rewind'      ) { $cmd = 'playback-seek-relative';
                                                  $arg = '-10';                     }
                elsif   ( $f eq 'fastForward' ) { $cmd = 'playback-seek-relative';
                                                  $arg = '+10';                     }

                # perform our office
                &aud( $cmd, $arg ) if $cmd;

                # track for de-dup
                $lastCode = $code;
                $lastTime = time();
            }
        }
    }
    warn( "lost our port! sleeping then regrouping" ) if $debug;
    sleep(1);
}

sub aud {
    my $cmd =  shift() || '';
    my $arg =  shift() || '';
    $cmd    =~ s/[^a-z\-]//g;       # sanitise
    $arg    =~ s/[^\d]//g;          # sanitise
    my @out =  `"${audtool}" "${cmd}" "${arg}"`;
    chomp ( my $ret = defined($out[0]) ? $out[0] : '' );
    warn  ( "debug: aud(cmd=${cmd}, arg=${arg}) -> ${ret}" ) if $debug;
    return( $ret );
}

sub initCodesTable {
    my %codes = ();
    $codes{'6018fefe'} = 'channelUp';
    $codes{'601efefe'} = 'channelDown';
    $codes{'6066fefe'} = 'mute';
    $codes{'6078fefe'} = 'volumeUp';
    $codes{'607efefe'} = 'volumeDown';
    $codes{'609e66fe'} = 'PC';
    $codes{'60e098fe'} = 'rewind';
    $codes{'60e660fe'} = 'play';
    $codes{'60e698fe'} = 'fastForward';
    $codes{'60f860fe'} = 'stop';
    $codes{'66e698fe'} = 'a-b';
    $codes{'66f860fe'} = 'pause';
    $codes{'66fe60fe'} = 'last';
    $codes{'781e98fe'} = 'select';
    # there are more -- these were enough for me
    return( %codes );
}

sub initPort {
    # default to 8N1 ...
    my $dataBits    = 8;
    my $parity      = 'none';
    my $stopBits    = 1;

    # ... but parse $comMode if different
    $dataBits = $1 if $comMode =~ /^(\d)/;
    if($comMode =~ /^.([neo])/i) {
        $parity = 'even' if $1 =~ /^e$/i;
        $parity = 'odd'  if $1 =~ /^o$/i;
    }
    $stopBits = $1 if $comMode=~/^..(\d)$/;

    my $port = Device::SerialPort->new( $comPort );
    die( "fatal: could not open port ${comPort}" ) if !$port;
    $port->read_char_time  (         0 );
    $port->read_const_time (      1000 );
    $port->baudrate        (  $comBaud );
    $port->databits        ( $dataBits );
    $port->parity          (   $parity );
    $port->stopbits        ( $stopBits );
    return( $port );
}

# goofy method to copy favourite songs to a special location
sub favourite {
    if( -d $favDir ) {                                      # sanity check
        chomp( my $audPID = `pidof audacious` );            # simple attempt to audacious PID
        if(!$audPID) {
            chomp( my $audPath = `which audacious` );       # get full path to audacious
            chomp( $audPID = `pidof "${audPath}"` );        # if we failed try full path
        }

        foreach my $pid ( $audPID =~ /\b(\d+)\b/mg ) {      # iterate through PIDs
            printf STDERR ( " PID: %d\n", $pid ) if $debug;
            foreach(`lsof -MblPnp "${pid}" 2>/dev/null`) {  # get list of open files
                chomp();
                if(/\d+\s+(\/.+\.mp3$)/i) {                     # find an MP3
                    my $mp3 = $1;
                    printf STDERR ( " MP3: %s\n", $mp3 ) if $debug;
                    printf STDERR ( "COPY: %s -> %s\n", $mp3, $favDir ) if $debug;
                    if( !system( '/bin/cp', '-n', $mp3, $favDir ) ) {
                        printf STDERR ("  OK: cp(1) returned zero\n") if $debug;
                    } else {
                        warn(" ERR: cp(1) returned non-zero\n") if $debug;
                    }
                }
            }
        }
    }
}
