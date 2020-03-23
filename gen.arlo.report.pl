#!/usr/bin/perl -w
# vim: set ts=4 sw=4 et
#
# gen.arlo.report.pl -- generate HTML report from Arlo downloads
#                       saved using simple 'Save As...' in Chromium
#                       and manual video download from the website
#                       (so, yeah, semi-auto only but fine for need)
# @anthonykava                                2019-11-30.1250.78-75

use strict;
use warnings;

my $inFile      = shift()||'';          # HTML file
my $caseNumber  = shift()||'';          # case number for report
my $outType     = shift()||'tsv';       # output format: tsv -or- html
my $thumbsDir   = shift()||'thumbs';    # dir containing thumbnails
my $videosDir   = shift()||'videos';    # dir containing videos
$outType='tsv' if $outType ne 'html';   # default to tsv output

# test arguments, show usage if wrong
if(!$inFile || !$caseNumber || !-e $inFile) {
    die("\nUsage: $0 inFile caseNumber [outType=tsv/html] [thumbsDir='thumbs'] [videosDir='videos']\n\n");
}
else {
    if(open(my $fh,$inFile)) {
        # TSV header
        print join("\t",'key','msepoch','tnFile','cam','shortTime','duration','info')."\n"
            if $outType eq 'tsv';

        # HTML header
        print << "END" if $outType eq 'html';
<html>
    <head>
        <title>${caseNumber} Arlo Video Report</title>
    </head>
    <style>
        body        { font-family:Helvetica,Arial,Verdana,sans-serif; font-size:14px; color:#000; background:#dadada; text-align:center; }
        h1          { font-family:Helvetica,Arial,Verdana,sans-serif; font-weight:bold; font-size:36px; color:#000; }
        table       { margin:auto; width:auto; }
        td          { padding:15px; }
        img         { width:240px; border:1px #000 solid; }
        a           { text-decoration:none; }
        a:hover     { text-decoration:underline; }
        .head       { font-family:Helvetica,Arial,Verdana,sans-serif; font-size:24px; font-weight:bold; color:#fff; background:#00f; text-align:center; }
        .data       { font-family:Helvetica,Arial,Verdana,sans-serif; font-size:24px; color:#000; background:#fff; }
        .right      { text-align:right; }
        .center     { text-align:center; }
        .filename   { font-family:Helvetica,Arial,Verdana,sans-serif; font-size:16px; font-weight:bold; color:#000; }
        .footnote   { font-family:Helvetica,Arial,Verdana,sans-serif; font-size:12px; font-weight:bold; color:#000; }
    </style>
    <body>
        <h1>${caseNumber} Arlo Video Report</h1>
        <table>
            <tr>
                <td class="head">#</td>
                <td class="head">Time</td>
                <td class="head">Camera</td>
                <td class="head">Duration</td>
                <td class="head">Info</td>
                <td class="head">Video</td>
            </tr>
END

        # iterate through input HTML file
        foreach(<$fh>) {
            #<div _ngcontent-tce-c36="" class="timeline-record" id="day_record_0">
            #<img _ngcontent-tce-c36="" alt="" appcamerathumbnail="" crossorigin="anonymous" src="./Arlo Web Portal_Smart Home Security_files/1575123302749_thumb.jpg" data-img-url="https...
            #<span _ngcontent-tce-c36="" class="record-camera-name arlo-fs18">Driveway ABCD1234EFGH5</span>
            #<span _ngcontent-tce-c36="" class="recording-short-time"> 8:15 AM</span>
            #<span _ngcontent-tce-c36="" class="recording-info-duration">
            #<!---->00:00:09</span>
            #<span _ngcontent-tce-c36="" class="recording-info-type" style="color: rgb(153, 153, 153); cursor: default;"> Motion </span>

            s/></>\n</g;													# add new lines to split on ><
            my($key,$msepoch,$tnFile,$cam,$shortTime,$duration,$info,$ll)=	# init variables
                ('',0,'','','','','','');
            foreach(split(/[\r\n]+/)) {										# iterate through lines
                if(/<div .+ class="timeline-record" id="([^"]+)">/) {
                    $key=$1;
                }
                elsif(/<img .+ appcamerathumbnail=.+ src=".+\/(\d+)(_thumb\.jpg)"/) {
                    ($msepoch,$tnFile)=($1,$1.$2);
                }
                elsif(/<span .+ class="record-camera-name.+>([^<]+)<\/span>/) {
                    $cam=$1;
                }
                elsif(/<span .+ class="recording-short-time">([^<]+)<\/span>/) {
                    $shortTime=$1;
                }
                elsif($ll=~/<span .+ class="recording-info-duration">/ && /(\d{2}:\d{2}:\d{2})<\/span>/) {
                    $duration=$1;
                }
                elsif(/<span .+ class="recording-info-type" [^>]+>([^<]+)<\/span>/) {
                    $info=$1;
                }

                if($key && $msepoch && $tnFile && $cam && $shortTime && $duration && $info) {
					# TSV output
					print join("\t",$key,$msepoch,$tnFile,$cam,$shortTime,$duration,$info)."\n"
						if $outType eq 'tsv';

					# HTML output
                    my $num=-1;
                    $num=sprintf('%03d',$1) if $key=~/_(\d+)$/;
                    my $time=&ansi($msepoch/1000);
                    my $vidFile=sprintf('%d.mp4',$msepoch);
                    my $vidPath=$videosDir.'/'.$vidFile;
                    print STDERR "ERROR: Could not find vidPath=$vidPath\n" if !-e $vidPath;
                    print << "END" if $outType eq 'html';
            <tr>
                <td class="data right">${num}</td>
                <td class="data right">${time}</td>
                <td class="data center">${cam}</td>
                <!-- <td class="data">${shortTime}</td> -->
                <td class="data right">${duration}</td>
                <td class="data center">${info}</td>
                <td class="data center">
                    <a href="${vidPath}">
                        <img src="${thumbsDir}/${tnFile}"><br />
                        <div class="filename">${vidFile}</div>
                    </a>
                </td>
            </tr>
END
					# reset variables
                    ($key,$msepoch,$tnFile,$cam,$shortTime,$duration,$info,$ll)=
                        ('',0,'','','','','','');
                }
                $ll=$_;		# holds our last line of input
            }
        }
        close($fh);

        my $genTime=&ansi();
        print << "END" if $outType eq 'html';
        </table>
    </body>

    <br />
    <br />
    <div class="footnote">
        Report Generated ${genTime}<br />
    </div>
    <br />
    <br />

</html>
END
    }
    else {
        die("FATAL: Could not open inFile=$inFile");
    }
}

# ansi($time=time()) -- returns YYYY-MM-DD HH:mm:ss from epoch
sub ansi {
    my $time=shift()||time();
    my @l=localtime($time);
    return(sprintf('%04d-%02d-%02d %02d:%02d:%02d',
            $l[5]+1900,$l[4]+1,$l[3],$l[2],$l[1],$l[0]));
}
