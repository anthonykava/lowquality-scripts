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

# most variables
my $debug   = shift() || 1;         # debug (0=none, 1=some)
my $favDir  = '/musica.favorita/';  # SELECT button copies playing mp3 here
my $audtool = '/usr/bin/audtool';   # location of audtool(1)
my $pactl   = '/usr/bin/pactl';     # location of pactl(1)
my $comPort = '/dev/ttyUSB0';       # our serial device
my $comBaud = 2400;                 # baud rate
my $comMode = '8N1';                # settings (databits, parity, stop bits)
my $bytes   = 4;                    # bytes to read at a time
my $volMax  = 70;                   # maximum allowed volume (%)
my $volDelta= 5;                    # % to change volume up/down at a time
my $lastCode= '';                   # holds last code received (we get dups)
my $lastTime= time();               # holds epoch time of last code
my $volLast = &paGetVol();          # last volume level (e.g., for unmute)
my %codes   = &initCodesTable();    # hash of 4-byte codes in hexit

# sanity checks
die( "fatal: ${audtool} not found" ) if !-e $audtool;
die( "fatal: ${comPort} not found" ) if !-e $comPort;
die( "fatal: failed to get volume" ) if $volLast !~ /^\d+$/;

# nearly-infinite loop
while( my $port = &initPort() ) {   # returns Device::SerialPort object
    &debug( "listening on ${comPort} (${comBaud}/${comMode}) -- volLast=${volLast} / volMax=${volMax}" );
    while( $port ) {
        my( $count, $data ) = $port->read( $bytes );
        if( $count == 4 ) {         # only care if we have 4 bytes
            # unpack binary to hexits for convenience
            my $code = unpack( 'H*', substr($data, 0, 4));

            # ignore duplicate codes for about a second
            if( $code ne $lastCode || time() > $lastTime + 1 ) {
                #  $f is our button pressed, if known, based on %codes
                my $f = defined( $codes{$code} ) ? $codes{$code} : '(unknown)';
                &debug( sprintf( '[ %-12s ] [ %-8s ]', $f, $code ) );

                my( $cmd, $arg ) = ( '', '' );
                if      ( $f eq 'select'      ) { &favourite();                                     }
                elsif   ( $f eq 'last'        ) { &lockScreen();                                    }
                elsif   ( $f eq 'PC'          ) { $cmd = 'set-volume';              $arg = '100';   }
                elsif   ( $f eq 'numUp'       ) { &fiatLux( 'on'    );                              }
                elsif   ( $f eq 'numENT'      ) { &fiatLux( 'off'   );                              }
                elsif   ( $f eq '1'           ) { &fiatLux( '25%'   );                              }
                elsif   ( $f eq '2'           ) { &fiatLux( '50%'   );                              }
                elsif   ( $f eq '3'           ) { &fiatLux( '75%'   );                              }
                elsif   ( $f eq '4'           ) { &fiatLux( '100%'  );                              }
                elsif   ( $f eq '5'           ) { &fiatLux( 'disco' );                              }
                elsif   ( $f eq '6'           ) { &fiatLux( 'green' );                              }
                elsif   ( $f eq '7'           ) { &fiatLux( 'blue'  );                              }
                elsif   ( $f eq '8'           ) { &fiatLux( 'red'   );                              }
                elsif   ( $f eq '9'           ) { &fiatLux( 'soft'  );                              }
                elsif   ( $f eq '0'           ) { &fiatLux( 'white' );                              }
                elsif   ( $f eq 'channelUp'   ) { $cmd = 'playlist-advance';                        }
                elsif   ( $f eq 'channelDown' ) { $cmd = 'playlist-reverse';                        }
                elsif   ( $f eq 'play'        ) { $cmd = 'playback-play';                           }
                elsif   ( $f eq 'stop'        ) { $cmd = 'playback-stop';                           }
                elsif   ( $f eq 'pause'       ) { $cmd = 'playback-pause';                          }
                elsif   ( $f eq 'a-b'         ) { $cmd = 'playlist-shuffle-toggle';                 }
                elsif   ( $f eq 'rewind'      ) { $cmd = 'playback-seek-relative';  $arg = '-10';   }
                elsif   ( $f eq 'fastForward' ) { $cmd = 'playback-seek-relative';  $arg = '+10';   }
                elsif   ( $f eq 'mute'        ) { &vol( 'mute' );                                   }
                elsif   ( $f eq 'volumeUp'    ) { &vol( 'up'   );                                   }
                elsif   ( $f eq 'volumeDown'  ) { &vol( 'down' );                                   }

                # perform our office
                &aud( $cmd, $arg ) if $cmd;
                &debug( "now playing: " . &aud( 'current-song' ) );

                # track for de-dup (it's RF, after all)
                $lastCode = $code;
                $lastTime = time();
            }
        }
    }

    # this should happen rarely
    &error( "lost our port! sleeping then regrouping" );
    sleep(1);
}

# aud( $cmd='', $arg='' ) -- runs audtool(1) and passes $arg; returns 1st line of output
sub aud {
    my $cmd =  shift() || '';
    my $arg =  shift() || '';
    $cmd    =~ s/[^a-z\-]//g;       # sanitise
    $arg    =~ s/[^\d\-+]//g;       # sanitise
    my @out =  `"${audtool}" "${cmd}" "${arg}"`;
    chomp( my $ret = defined($out[0]) ? $out[0] : '' );
    &debug( "aud(cmd=${cmd}, arg=${arg}) -> '${ret}'" );
    return( $ret );
}

# initCodesTable() -- returns a hash of hexit codes -> button names
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
    $codes{'669e66fe'} = 'numUp';
    $codes{'6606fefe'} = '1';
    $codes{'6618fefe'} = '2';
    $codes{'661efefe'} = '3';
    $codes{'6660fefe'} = '4';
    $codes{'6666fefe'} = '5';
    $codes{'6678fefe'} = '6';
    $codes{'667efefe'} = '7';
    $codes{'668060fe'} = '8';
    $codes{'668660fe'} = '9';
    $codes{'6600fefe'} = '0';
    $codes{'669860fe'} = 'numENT';
    # there are more -- these were enough for me
    return( %codes );
}

# initPort() -- sets-up a Device::SerialPort object and returns it
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

# favourite() -- reads the current song filename and copies it to $favDir
sub favourite {
    if( -d $favDir ) {                                      # sanity check
        my $song = &aud( 'current-song-filename' );
        if( !system( '/bin/cp', '-n', $song, $favDir ) ) {
            &debug( "copied '${song}' to '${favDir}'" );
        } else {
            &error( "cp(1) returned non-zero: '${song}' -> '${favDir}'" );
        }
    } else {
        &error( "favDir=${favDir} not found" );
    }
}

# lt( $time=time() ) -- returns 'YYYY-MM-DD HH:mm:ss' localtime($time)
sub lt {
    my $time= shift() || time();
    my @l   = localtime( $time );
    return(
        sprintf( '%04d-%02d-%02d %02d:%02d:%02d',
            $l[5] + 1900, $l[4] + 1, $l[3], $l[2], $l[1], $l[0] )
    );
}

# lockScreen() -- locks the screen with xdg-screensaver(1)
sub lockScreen {
    my( $cmd, $arg ) = ( 'xdg-screensaver', 'lock' );
    if( !system( $cmd, $arg ) ) {
        &debug( "locked screen with '${cmd} ${arg}'" );
    } else {
        &error( "non-zero return from '${cmd} ${arg}' to lock screen: $?" );
    }
}

# fiatLux( $arg='' ) -- launches a second script to control a light, fork()s to be non-blocking
sub fiatLux {
    my $arg = shift() || '';
    my $cmd = '/usr/local/bin/light.bs';
    &debug( "pid=$$ fiatLux( ${cmd} ${arg} ) pre-fork" );
    my $pid = fork();
    if( !$pid ) {
        system( $cmd, $arg );
        &debug( "pid=$$ fiatLux( ${cmd} ${arg} ) forked" );
        exit();
    }
}

# debug( $msg ) -- prints $msg to STDERR if $debug is true
sub debug {
    my $msg=join( ' ', @_ );
    printf STDERR ( "%19s  %5d  debug: %s\n", &lt(), $$, $msg ) if $debug;
}

# error( $msg ) -- does a warn() with $msg
sub error {
    my $msg=join( ' ', @_ );
    warn(  sprintf( '%19s  %5d  error: %s', &lt(), $$, $msg ) );
}

# vol( $task ) -- adjusts volume, $task should be 'mute' (toggles), 'up', or 'down'
sub vol {
    my $task    = shift() || '';
    my $sink    = &paGetSink();
    my $vol     = &paGetVol( $sink );
    my $ret     = 1;
    &debug( "vol( '${task}' ) -- sink=${sink}, vol=${vol}" );

    if( $task eq 'mute' ) {
        if( $vol == 0 ) {                           # already muted (toggle)
            $ret = &paSetVol( $sink, $volLast );    # restore to last volume
        } else {                                    # not muted ...
            $volLast = $vol;                        # store last volume level
            $ret = &paSetVol( $sink, 0 );           # set to 0 (mute)
        }
    } elsif( $task eq 'up' ) {
        if( $vol >= $volMax - $volDelta ) {         # can't turn it up to 11
            &paSetVol( $sink, $volMax );
        } else {
            $ret = &paSetVol( $sink, $vol + $volDelta );
        }
        $volLast = &paGetVol( $sink );
    } elsif( $task eq 'down' ) {
        if( $vol <= $volDelta ) {                   # can't be quieter than silent
            &paSetVol( $sink, 0 );
        } else {
            $ret = &paSetVol( $sink, $volLast - $volDelta );
        }
        $volLast = &paGetVol( $sink );
    }
    return($ret);
}

# paGetSink() -- returns RUNNING pulseaudio sink number
sub paGetSink {
    my $ret = -1;
    my @out = `"${pactl}" list short sinks`;
    if( $out[0] =~ /^(\d+)\s+.+RUNNING/i ) {
        $ret = $1;
    }
    return( $ret );
}

# paGetVol( $sink ) -- returns current volume (%) for pulseaudio sink $sink
sub paGetVol {
    my $sink=shift();
    $sink = &paGetSink() if !defined( $sink );
    my $ret=-1;
    my $currentSink = 0;
    #&debug( "paGetVol(${sink})" );
    if( $sink >= 0 ) {
        foreach( `"${pactl}" list sinks` ) {
            if( /^\s+Volume: .+\/\s+(\d+)%\s+\// ) {
                $ret = $1 if $currentSink == $sink;
                last() if $ret != -1;
                $currentSink++;
            }
        }
    }
    return( $ret );
}

# paSetVol( $sink, $vol=50% ) -- sets volume to $vol % on sink $sink
sub paSetVol {
    my $sink=shift();
    my $vol=shift();
    &debug( "paSetVol(${sink}, ${vol})" );
    return ( system( $pactl, 'set-sink-volume', $sink, $vol.'%' ) );
}
