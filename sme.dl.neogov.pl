#!/usr/bin/perl -w
# ----------------
# sme.dl.neogov.pl
# ----------------
# Downloads HTML job apps and attachments for SME review from NEOGOV,
# saves files according to PersonID (which matches the website
# interface).  Makes SME reviews easier since the web interface is
# painful at present.
#
# Required Modules:
#
#   WWW::Mechanize (Ubuntu: libwww-mechanize-perl)
#   URI::Encode    (Ubuntu: liburi-encode-perl   )
#
# 2016-10-27.1326.ACK (@anthonykava)

use strict;								# of course
use warnings;							# why not?
use URI::Encode qw/uri_decode/;			# for decoding URIs
use WWW::Mechanize;						# our main thing

# Vars
our $debug		= shift()||1;			# debug			0=none, 1=some
my  $jobid		= shift()||'1234567';	# JobID			set or pass (1st arg)
my  $examplanid	= shift()||'7654321';	# examPlanID	set or pass (2nd arg)
my  $outdir		= shift()||'out';		# output dir	set or pass (3rd arg)

# Starters
my $mech=WWW::Mechanize->new();			# do a WWW::Mechanize object
mkdir($outdir) if !-e $outdir;			# create outdir if needed

# Login
$mech->get('https://login.neogov.com/');
&debug("Logging-in");
$mech->submit_form
(
	fields =>
	{
		UserName	=> 'user@name.here',				# <--
		Password	=> 'obviouslySomethingStrongEh?',	# <--
	}
);

# Get resumes and persons list
$mech->get
(
	'https://secure.neogov.com/OHC/SMEcandidates.cfm'.
		'?ExamPlanID='.$examplanid.
		'&JobID='.$jobid
);
my @resumeids=();
my @personids=();
my $i=0;
foreach(split(/[\r\n]+/,$mech->content()))
{
	chomp();
	if(/submitAppForm\((\d+),(\d+)\);">(\d+)/)
	{
		my($localJobID,$resumeid,$personid)=($1,$2,$3);
		if($localJobID eq $jobid)
		{
			$resumeids[$i]=$resumeid;
			$personids[$i++]=$personid;
			&debug("Found ResumeID=$resumeid PersonID=$personid");
		}
	}
}

# Get resumes
foreach ($i=0;$i<=$#resumeids;$i++)
{
	my $resumeid=$resumeids[$i];
	my $personid=$personids[$i];
	&debug("$personid\t$resumeid\tGrabbing resume HTML for ResumeID=$resumeid PersonID=$personid");
	$mech->get
	(
		'https://secure.neogov.com/OHC/view_resume.cfm'.
			'?examPlanID='.$examplanid.
			'&JobID='.$jobid.
			'&ResumeID='.$resumeid.
			'&NeoFormKey=E2636ED525403418982781F6391E6F0054F77A46A445554712D672B1D37C25E77932AE8EB30A8D2AC822691B9976D428'.
			'&GetJSUserIDFromResume=yes'.
			'&fromOHCSMEReview=yes'
	);
	# ^-- Does NeoFormKey change? If so then it may need to be changed.

	my $htmlFile=$personid.'.html';
	my $resumeHtml=$mech->content();
	&writeFile($outdir.'/'.$htmlFile,$resumeHtml);

	# Get attachments
	foreach(split(/[\r\n]+/,$resumeHtml))
	{
		chomp();
		if(/a href="([^"]+)"/)										# find links
		{
			my $url=$1;
			if($url=~/serverFileName=([^"\&]+)/)					# link for attachments
			{
				my $file=uri_decode($1);							# attachment name
				my $path=$outdir.'/'.$personid.'.'.$file;			# our path to save it
				&debug("$personid\t$resumeid\tGrabbing attachment: $file");
				$mech->get($url);									# retrieve
				&writeFile($path,$mech->content());					# save
			}
		}
	}
}

# Fin
$mech=undef();

# writeFile($file,$data) -- write $data to filename $file
sub writeFile
{
	my($file,$data)=@_;
	if(open(my $fh,'>',$file))
	{
		print $fh $data;
		close($fh);
		&debug("Wrote file=$file (".length($data)." bytes)");
	}
}

# debug($msg[,$lvl=0]) -- print a message if $debug>=$lvl
sub debug
{
	my($msg,$lvl)=@_;
	$lvl=0 if !defined($lvl);
	chomp($msg);
	print scalar(localtime())."\t".$$."\t".$msg."\n" if $debug>=$lvl;
}
