#!/usr/bin/perl -w
# ------------------------------------------------------------------------------
# | x10.audacious.remote.pl                                                    |
# ------------------------------------------------------------------------------
# We read serial data from a port connected to an X10 JR21A receiver in order to
# receive button presses from the X10 JR20A remote.  MisterHouse says this thing
# should be 1200/8N1, but 2400/8N1 worked for me.  The remote signals will trig-
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
my $volDelta= 10;                   # % to change volume up/down at a time
my $lastCode= '';                   # holds last code received (we get dups)
my $lastTime= time();               # holds epoch time of last code
my $lastVol = &aud( 'get-volume' ); # last volume level (e.g., for unmute)
my %codes   = &initCodesTable();    # hash of 4-byte codes in hexit

die( "fatal: ${audtool} not found" ) if !-e $audtool;
die( "fatal: ${comPort} not found" ) if !-e $comPort;
die( "fatal: failed to get-volume" ) if $lastVol !~ /^\d+$/;
while( my $port = &initPort() ) {   # returns Device::SerialPort object
    warn( &lt() . " debug: listening on ${comPort} (${comBaud}/${comMode})" ) if $debug;
    while( $port ) {
        my( $count, $data ) = $port->read( $bytes );
        if( $count ) {
            # unpack binary to hexits for convenience
            my $code = unpack( 'H*', substr($data, 0, 4));

            # ignore duplicate codes for a second
            if( $code ne $lastCode || time() != $lastTime ) {
                my $f = defined( $codes{$code} ) ?
                    $codes{$code} : '(unknown)';
                printf STDERR ( "%19s [ %-12s ] [ %-8s ]\n",
                                &lt(), $f, $code ) if $debug;

                my($cmd,$arg)=('','');
                if      ( $f eq 'select'      ) { &favourite();                     }
                elsif   ( $f eq 'last'        ) { &lockScreen();                    }
                elsif   ( $f eq 'PC'          ) { &fiatLux();                       }
                elsif   ( $f eq 'upArrow'     ) { &fiatLux( 'non' );                }
                elsif   ( $f eq 'channelUp'   ) { $cmd = 'playlist-advance';        }
                elsif   ( $f eq 'channelDown' ) { $cmd = 'playlist-reverse';        }
                elsif   ( $f eq 'play'        ) { $cmd = 'playback-play';           }
                elsif   ( $f eq 'stop'        ) { $cmd = 'playback-stop';           }
                elsif   ( $f eq 'pause'       ) { $cmd = 'playback-pause';          }
                elsif   ( $f eq 'a-b'         ) { $cmd = 'playlist-shuffle-toggle'; }
                elsif   ( $f eq 'mute'        ) {
                    $cmd = 'set-volume';
                    if( &aud( 'get-volume' ) == 0 ) {   # already muted (toggle)
                        $arg = $lastVol;                # restore to last volume
                    } else {                            # not muted ...
                        $lastVol = &aud( 'get-volume ');# store last volume level
                        $arg = 0;                       # set to 0 (mute)
                    }}
                elsif   ( $f eq 'volumeUp'    ) {
                    $cmd = 'set-volume';
                    $lastVol = &aud( 'get-volume' );
                    if( $lastVol >= 100 - $volDelta ) {
                        $arg = 100;
                    } else {
                        $arg = $lastVol + $volDelta;
                    }}
                elsif   ( $f eq 'volumeDown'  ) {
                    $cmd = 'set-volume';
                    $lastVol = &aud( 'get-volume' );
                    if( $lastVol <= $volDelta ) {
                        $arg = 0;
                    } else {
                        $arg = $lastVol - $volDelta;
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
    warn( &lt() . " error: lost our port! sleeping then regrouping" );
    sleep(1);
}

sub aud {
    my $cmd =  shift() || '';
    my $arg =  shift() || '';
    $cmd    =~ s/[^a-z\-]//g;       # sanitise
    $arg    =~ s/[^\d\-+]//g;       # sanitise
    my @out =  `"${audtool}" "${cmd}" "${arg}"`;
    chomp ( my $ret = defined($out[0]) ? $out[0] : '' );
    warn  ( &lt() . " debug: aud(cmd=${cmd}, arg=${arg}) -> '${ret}'" ) if $debug;
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
    $codes{'669e66fe'} = 'upArrow';
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

sub favourite {
    if( -d $favDir ) {                                      # sanity check
        my $song = &aud( 'current-song-filename' );
        if( !system( '/bin/cp', '-n', $song, $favDir ) ) {
            printf STDERR ("%19s debug: copied '%s' to '%s'\n",
                &lt(), $song, $favDir ) if $debug;
        } else {
            warn( &lt() . " error: cp(1) returned non-zero: '${song}' -> '${favDir}'" );
        }
    } else {
        warn( &lt() . " error: favDir=${favDir} not found" );
    }
}

sub lt {
    my $time= shift() || time();
    my @l   = localtime( $time );
    return(
        sprintf( '%04d-%02d-%02d %02d:%02d:%02d',
            $l[5] + 1900, $l[4] + 1, $l[3], $l[2], $l[1], $l[0] )
    );
}

sub lockScreen {
    my( $cmd, $arg ) = ( 'xdg-screensaver', 'lock' );
    if( !system( $cmd, $arg ) ) {
        warn( &lt() . " debug: locked screen with '${cmd} ${arg}'" ) if $debug;
    } else {
        warn( &lt() . " error: non-zero return from '${cmd} ${arg}' to lock screen: $?" );
    }
}

sub fiatLux {
    my $arg     = shift() || '';
    my $script  = '/usr/local/bin/light.bs';
    if( $arg !~ /^n/i ) { system( $script, 'off' ); }
    else                { system( $script, 'on'  ); }
}
