<?php
/* vim: set ts=4 sw=4 set noet
 *
 * --------------
 * fair/index.php
 * --------------
 *
 * This PHP-based  website was  built to  provide 5th graders (and other
 * students) with a hands-on Cyber Security / Digital Forensics exercise
 * compatible  with  their school  Chromebooks.  Built and  tested  with
 * Chrome  and Chromium.  Should work  from  any  platform that  can run
 * either browser with JavaScript enabled.
 *
 * Used at the  Council Bluffs (Iowa) Rotary Club 5th  Grade Career Fair
 * in April 2016 and  a presentation to the Woodrow Wilson Middle School
 * Tech Club in October 2016.
 *
 * There's a scoring bug I've  left unfixed after  the happy coincidence
 * of students finding it.  Gave a good example of a vulnerability.
 *
 * Could be cleaner and better-documented.  Such is life.
 *
 *    Last major update: 2016-04-12
 *   Prepped for GitHub: 2016-10-28
 *
 * @anthonykava
 */

// Change for WHOIS look-up command location
$cmd_whois='/usr/bin/whois';

// Start a PHP session
session_start();

// Init session (if new or 'reset' is requested)
if(!isset($_SESSION['stime']) || time()-$_SESSION['stime']>3600 || $_REQUEST['reset']==='1')
{
	session_destroy();							// Destroy our existing PHP session
	session_start();							// Start a new PHP session

	echo "<!-- Init session (stime=".$_SESSION['stime']." // reset=".$_REQUEST['reset']." -->\n";

	$_SESSION['stime']				= time();	// Init stime as now (Unix epoch)
	$_SESSION['score']				= 0;		// Score starts at 0
	$_SESSION['step0.visit']		= 0;		// Reset flag for visit to your site
	$_SESSION['step1.backup']		= 0;		// Reset flag for backup done
	$_SESSION['step2.restore']		= 0;		// Reset flag for restore done
	$_SESSION['step3.patch']		= 0;		// Reset flag for updates installed
	$_SESSION['step4.logs']			= 0;		// Reset flag for log viewed
	$_SESSION['step4.logs.target']	= 0;		// Reset flag for log searched for target
	$_SESSION['step5.whois']		= 0;		// Reset flag for whois query run
	$_SESSION['step5.whois.target']	= 0;		// Reset flag for whois query on target run

/* Never implemented, seemed a bit much for 5th graders in the end
  	$_SESSION['step6.report']		= 0;
	$_SESSION['step7.subpoena']		= 0;
 */

	// Reload ourself now that we've (re-)initialised our session
	header('Refresh:0; url='.$_SERVER['PHP_SELF']);
}

// VISIT YOUR SITE
if($_REQUEST['screen']==='step0.visit')
{
	if($_SESSION['step2.restore']>0)	// website is restored, show good version
	{
		?>
<html>
	<head>
		<title>Jumping in Business Apparel, Inc.</title>
		<style>
			body { background-color:#fff; color:#000; font-family:Helvetica,Verdana,Arial; text-align:center; }
		</style>
	</head>
	<body>
		<div align="center">
			<img src="good.jpg" width=1280 height=665 alt='Jumping in Business Apparel, Inc. -- We sell things, in theory.' />
			<!-- Last edit by user 'tony' on 2016-04-02 19:21:29 UTC using 'Mozilla/5.0' browser -->
		</div>
	</body>
</html>
		<?php
	}
	else								// website is defaced, show hacked version
	{
		// Score a point
		if($_SESSION['step0.visit']===0)
		{
			$_SESSION['score']+=1;
			$_SESSION['step0.visit']=time();	// XXX
		}
		?>
<html>
	<head>
		<title>LOSERS in Business Apparel, Inc.</title>
		<style>
			body { background-color:#fff; color:#000; font-family:Helvetica,Verdana,Arial; text-align:center; }
		</style>
	</head>
	<body>
		<div align="center">
			<img src="defaced.jpg" width=1280 height=665 alt='LOSERS in Business Apparel, Inc. -- Doom on you!' />
			<!-- Last edit by user 'superadmin' on 2016-04-12 15:12:32 UTC using 'DefacementToolkit/1.0' browser -->
		</div>
	</body>
</html>
		<?php
	}
}
else
{
	?>
<html>
	<head>
		<title>cYbEr SeCuRiTy / DiGiTaL fOrEnSiCs CoNtRoL pAnEl</title> <!-- l33t -->
		<style>
			body	 			{ background-color:#000; color:#dadada; font-family:Helvetica,Verdana,Arial; text-align:center; background-image:url('pcso.dark.bg05.jpg');									}
			h1					{ font-family:Helvetica,Verdana,Arial; font-size:60px; padding:0px; margin:0px;																								}
			h2					{ font-family:Helvetica,Verdana,Arial; font-size:42px; padding:0px;	margin:0px;																								}
			h3					{ font-family:Helvetica,Verdana,Arial; font-size:28px; padding:0px;	margin:0px;																								}
			td					{ font-family:Helvetica,Verdana,Arial; font-size:28px; padding:0px;	margin:0px;																								}
			.dashTable			{ width:100%; border:4px; border-style:dashed; padding:10px; margin:0px; 																									}
			.dashHead			{ font-family:Helvetica,Verdana,Arial; font-size:24px; color:#0f0; font-weight:bold; padding:0px; margin:0px; vertical-align:text-top;										}
			.dashVal			{ font-family:Helvetica,Verdana,Arial; font-size:32px; padding:0px; margin:0px; vertical-align:text-top;																	}
			.menuTd				{ text-align:center;																																						}
			.menuButton			{ font-family:Helvetica,Verdana,Arial; border:4px solid #0f0; width:500px; font-size:36px; padding:16px; margin:0px; background:#dadada; color:#000; border-radius:20px;	}
			.menuButton:hover	{ font-family:Helvetica,Verdana,Arial; font-weight:bold; width:510px; font-size:36px; padding:16px; margin:0px; background:#0f0; color:#000; border-radius:20px;			}
			.badFont			{ font-family:Helvetica,Verdana,Arial; color:#f00; 																															}
			.goodFont			{ font-family:Helvetica,Verdana,Arial; color:#0f0;																															}
			.searchText			{ font-family:Helvetica,Verdana,Arial; border:2px solid #0f0; width:500px; font-size:24px; padding:4px; margin:0px; background:#dadada; color:#000; border-radius:10px;		}
			.searchButton		{ font-family:Helvetica,Verdana,Arial; border:2px solid #0f0; width:120px; font-size:24px; padding:4px; margin:0px; background:#dadada; color:#000; border-radius:10px;		}
			.searchButton:hover	{ font-family:Helvetica,Verdana,Arial; font-weight:bold; width:120px; font-size:24px; padding:4px; margin:0px; background:#0f0; color:#000; border-radius:10px;				}
			.transition
			{
			  -webkit-transition: all 0.5s ease-out;
				 -moz-transition: all 0.5s ease-out;
				   -o-transition: all 0.5s ease-out;
					  transition: all 0.5s ease-out;
			}
			.backupTransition
			{
			  -webkit-transition: all 5.0s ease-out;
				 -moz-transition: all 5.0s ease-out;
				   -o-transition: all 5.0s ease-out;
					  transition: all 5.0s ease-out;
			}
		</style>
	</head>
	<body>
		<script>
			// menuFunction(choice) -- handles button presses on site
			function menuFunction(choice='')
			{
				if(choice==='menu')					// main menu
				{
					window.location='?';
				}
				else if(choice==='reset')			// reset session
				{
					if(confirm("Are you double plus sure you want to reset your session?"))
					{
						window.location='?reset=1';
					}
				}
				else if(choice==='step0.visit')		// VISIT YOUR SITE
				{
					if(<?php echo $_SESSION['step0.visit'] ?>===0) window.score++;	// check session var step0.visit XXX
					document.getElementById('hiddenVisit').click();
				}
				else if								// Other buttons/choices
				(
					choice==='step1.backup'		||
					choice==='step2.restore'	||
					choice==='step3.patch'		||
					choice==='step4.logs'		||
					choice==='step5.whois'		||
					choice==='help'
				)
				{
					window.location='?screen='+choice;
				}
			}

			// secondly() -- updates the web page clocks (runs every second) and update score too
			function secondly()
			{
				// Session time bits
				var epoch=Math.round(new Date().getTime()/1000.0);
				var elapsed=epoch-window.stime;
				var sec=elapsed;
				var min=0;
				if(sec>59)
				{
					min=Math.floor(elapsed/60);
					sec-=min*60;
				}
				if(min<10)		min		= "0" + min;			// zero pad
				if(sec<10)		sec		= "0" + sec;			// "

				// Clock bits
				var currentDate	= new Date()
				var year		= currentDate.getFullYear();
				var month		= currentDate.getMonth() + 1;
				var day			= currentDate.getDate();
				var hours		= currentDate.getHours();
				var minutes		= currentDate.getMinutes();
				var seconds		= currentDate.getSeconds();

				if(month<10)	month		= "0" + month;		// zero pad
				if(day<10)		day			= "0" + day;		// "
				if(hours<10)	hours		= "0" + hours;		// "
				if(minutes<10)	minutes		= "0" + minutes;	// "
				if(seconds<10)	seconds		= "0" + seconds;	// "

				// UTC clock bits
				var uyear		= currentDate.getUTCFullYear();
				var umonth		= currentDate.getUTCMonth() + 1;
				var uday		= currentDate.getUTCDate();
				var uhours		= currentDate.getUTCHours();
				var uminutes	= currentDate.getUTCMinutes();
				var useconds	= currentDate.getUTCSeconds();

				if(umonth<10)	umonth		= "0" + umonth;		// zero pad
				if(uday<10)		uday		= "0" + uday;		// "
				if(uhours<10)	uhours		= "0" + uhours;		// "
				if(uminutes<10)	uminutes	= "0" + uminutes;	// "
				if(useconds<10)	useconds	= "0" + useconds;	// "

				// Update divs
				document.getElementById('clockTime').innerHTML=year + "-" + month + "-" + day + " " + hours + ":" + minutes + ":" + seconds;
				document.getElementById('utcTime').innerHTML=uyear + "-" + umonth + "-" + uday + " " + uhours + ":" + uminutes + ":" + useconds;
				document.getElementById('sessionTime').innerHTML=min + ':' + sec;

				// Update score percentage whilst we're at it
				var perc=window.score/10*100;
				document.getElementById('scoreBoard').innerHTML=window.score + ' / 10 (' + perc + '%)';
			}

			// set JS variables from PHP session variables
			window.stime=<?php echo $_SESSION['stime']?>;		// session start time (Unix epoch)
			window.score=<?php echo $_SESSION['score']?>;		// score
			window.setInterval(secondly,1000);					// Make sure we run secondly() every second
		</script>

		<table class="dashTable" width="100%" align="center">
			<tr>
				<td width="25%" align="left" valign="top">
					<div class="dashHead" align="left">Session Time:<br /></div><div class="dashVal" id="sessionTime" align="center">--:--</div>
				</td>
				<td width="25%" align="left" valign="top">
					<div class="dashHead" align="left">Local:<br /></div><div class="dashVal" id="clockTime" align="center"><?php echo date("Y-m-d H:i:s")?></div>
				</td>
				<td width="25%" align="left" valign="top">
					<div class="dashHead" align="left">UTC:<br /></div><div class="dashVal" id="utcTime" align="center"><?php echo gmdate("Y-m-d H:i:s")?></div>
				</td>
				<td width="25%" align="left" valign="top">
					<div class="dashHead" align="left">Score:<br /></div><div class="dashVal" id="scoreBoard" align="center"><?php echo $_SESSION['score']?> / 10 (<?php echo ($_SESSION['score']/10*100)?>%)</div>
				</td>
			</tr>
		</table>

		<br />
		<h3>CYBER SECURITY / DIGITAL FORENSICS</h3>
		<h1>CONTROL PANEL</h1>

		<?php
			// viewing logs merits a point
			if($_REQUEST['screen']==='step4.logs' && $_SESSION['step4.logs']===0)
			{
				echo "<script>window.score++;</script>\n";
				$_SESSION['score']+=1;
				$_SESSION['step4.logs']=time();
			}


			// searching logs for certain strings is rewarded with points
			if($_REQUEST['screen']==='step4.logs' && $_SESSION['step4.logs.target']===0)
			{
				if(preg_match('/hack|10:12|deface|user|pass|edit|super|admin|jump|tool|15:12|70\.58/i',$_REQUEST['q']))
				{
					echo "<script>window.score++;</script>\n";
					$_SESSION['score']+=2;
					$_SESSION['step4.logs.target']=time();
				}
			}
		?>

		&lt;= <b>Current Status</b> =&gt;&nbsp;
		Evidence: <?php if($_SESSION['step1.backup']===0) { echo '<font class="badFont">NOT SAVED'; } else { echo '<font class="goodFont">Saved!'; } ?></font>&nbsp;|&nbsp;
		Site: <?php if($_SESSION['step2.restore']===0) { echo '<font class="badFont">HACKED'; } else { echo '<font class="goodFont">Restored!'; } ?></font>&nbsp;|&nbsp;
		Updates: <?php if($_SESSION['step3.patch']===0) { echo '<font class="badFont">OUTDATED'; } else { echo '<font class="goodFont">Up to date!'; } ?></font>&nbsp;|&nbsp;
		Logs: <?php if($_SESSION['step4.logs']===0) { echo '<font class="badFont">UNREVIEWED'; } else { echo '<font class="goodFont">Reviewed!'; } ?></font>&nbsp;
		&lt;= <b>Current Status</b> =&gt;<br />

		<hr width="75%" />
<?php

// Screens other than main menu
if(!isset($_REQUEST['screen']) || preg_match('/^s\d/',$_REQUEST['screen']))
{
	?>
		<table class="menuTable" align="center">
			<tr>
				<td class="menuTd">
					<input class="menuButton transition" type="button" onClick="menuFunction('step0.visit');" value="VISIT YOUR SITE" /><br />
				</td><td class="menuTd">
					<a href="?screen=step0.visit" target="_blank"><div id="hiddenVisit" style="display:none;">&nbsp;</div></a>
					<input class="menuButton transition" type="button" onClick="menuFunction('step1.backup');" value="BACKUP SITE" /><br />
				</td>
			</tr><tr>
				<td class="menuTd">
					<input class="menuButton transition" type="button" onClick="menuFunction('step2.restore');" value="RESTORE SITE" /><br />
				</td><td class="menuTd">
					<input class="menuButton transition" type="button" onClick="menuFunction('step3.patch');" value="INSTALL UPDATES" /><br />
				</td>
			</tr><tr>
				<td class="menuTd">
					<input class="menuButton transition" type="button" onClick="menuFunction('step4.logs');" value="SEARCH LOGS" /><br />
				</td><td class="menuTd">
					<input class="menuButton transition" type="button" onClick="menuFunction('step5.whois');" value="WHOIS IP" /><br />
				</td>
			</tr><tr>
				<td class="menuTd">
					<input class="menuButton transition" type="button" onClick="menuFunction('reset');" value="* RESET SESSION *" /><br />
				</td><td class="menuTd">
					<input class="menuButton transition" type="button" onClick="menuFunction('help');" value="* ABOUT *" /><br />
				</td>
			</tr>
		</table>

	<?php
}
elseif($_REQUEST['screen']==='step1.backup')
{
	?>
<style>
	#myProgress {
		position: relative;
		width: 80%;
		height: 30px;
		background-color: grey;
		border-radius:20px;
	}
	#myBar {
		position: absolute;
		width: 1%;
		height: 100%;
		background-color: green;
		border-radius:20px;
	}
	#label {
		text-align: center; /* If you want to center it */
		line-height: 30px; /* Set the line-height to the same as the height of the progress bar container, to center it vertically */
		color: white;
	}
</style>

		<br />
		<h2>BACKUP IN PROGRESS...</h2>

		<br />
		<div align="center">
			<div id="myProgress">
			  <div id="myBar">
			    <div id="label">10%</div>
			  </div>
			</div>
			<br />
			<div id="backupMsg">
			</div>
		</div>

<script>
	// move() -- Fisher Price(tm)-style progress bar and appropriate student feedback
	function move() {
		var elem = document.getElementById("myBar"); 
		var width = 10;
		var id = setInterval(frame, 30);
		function frame() {
			if (width >= 100) {
				clearInterval(id);
				<?php
					if($_SESSION['step2.restore']>0 && $_SESSION['step1.backup']===0)
					{
						echo 'document.getElementById("backupMsg").innerHTML="<h3>Oops!<br />You already restored your site<br />before backing-up.  It is too late.</h3>";'."\n";
						$_SESSION['step1.backup']=0;
					}
					elseif($_SESSION['step1.backup']>0)
					{
						echo 'document.getElementById("backupMsg").innerHTML="<h3>Deja vu?<br />You have already backed-up your site, mate.<br />What should you do next?</h3>";'."\n";
					}
					else
					{
						echo 'document.getElementById("backupMsg").innerHTML="<h3>Congrats!<br />Backing-up your hacked site has preserved<br />evidence for further investigation.</h3>";'."\n".
							"window.score++;\n";
						$_SESSION['score']+=1;
						$_SESSION['step1.backup']=time();
					}
				?>
			} else {
				width++; 
				elem.style.width = width + '%'; 
				document.getElementById("label").innerHTML = width * 1 + '%';
			}
		}
	}
	move();
</script>

	<div align="center">
		<br />
		<br />
		<input class="menuButton transition" type="button" onClick="menuFunction('menu');" value="BACK TO MAIN MENU" /><br />
	</div>

	<?php
}
elseif($_REQUEST['screen']==='step2.restore')
{
	?>
<style>
	#myProgress {
		position: relative;
		width: 80%;
		height: 30px;
		background-color: grey;
		border-radius:20px;
	}
	#myBar {
		position: absolute;
		width: 1%;
		height: 100%;
		background-color: green;
		border-radius:20px;
	}
	#label {
		text-align: center; /* If you want to center it */
		line-height: 30px; /* Set the line-height to the same as the height of the progress bar container, to center it vertically */
		color: white;
	}
</style>

		<br />
		<h2>RESTORE IN PROGRESS...</h2>

		<br />
		<div align="center">
			<div id="myProgress">
			  <div id="myBar">
			    <div id="label">10%</div>
			  </div>
			</div>
			<br />
			<div id="restoreMsg">
			</div>
		</div>

<script>
	// move() -- Fisher Price(tm)-style progress bar and appropriate student feedback
	function move() {
		var elem = document.getElementById("myBar"); 
		var width = 10;
		var id = setInterval(frame, 30);
		function frame() {
			if (width >= 100) {
				clearInterval(id);
				<?php
					if($_SESSION['step1.backup']===0)
					{
						echo 'document.getElementById("restoreMsg").innerHTML="<h3>Oops!<br />You just restored your clean site,<br />but you did not backup the hacked site.<br />You have lost evidence, not to mention points.</h3>";'."\n".
							"window.score--;\n";
						$_SESSION['step2.restore']=time();
						$_SESSION['score']-=1;
					}
					elseif($_SESSION['step2.restore']>0)
					{
						echo 'document.getElementById("restoreMsg").innerHTML="<h3>Deja vu?<br />You have already restored your site, mate.<br />What should you do next?</h3>";'."\n";
					}
					else
					{
						echo 'document.getElementById("restoreMsg").innerHTML="<h3>Congrats!<br />Restoring your site after taking a backup<br />has preserved evidence and gotten you back on-line!</h3>";'."\n".
							"window.score++;\n";
						$_SESSION['score']+=1;
						$_SESSION['step2.restore']=time();
					}
				?>
			} else {
				width++; 
				elem.style.width = width + '%'; 
				document.getElementById("label").innerHTML = width * 1 + '%';
			}
		}
	}
	move();
</script>

	<div align="center">
		<br />
		<br />
		<input class="menuButton transition" type="button" onClick="menuFunction('menu');" value="BACK TO MAIN MENU" /><br />
	</div>

	<?php
}
elseif($_REQUEST['screen']==='step3.patch')
{
	?>
<style>
	#myProgress {
		position: relative;
		width: 80%;
		height: 30px;
		background-color: grey;
		border-radius:20px;
	}
	#myBar {
		position: absolute;
		width: 1%;
		height: 100%;
		background-color: green;
		border-radius:20px;
	}
	#label {
		text-align: center; /* If you want to center it */
		line-height: 30px; /* Set the line-height to the same as the height of the progress bar container, to center it vertically */
		color: white;
	}
</style>

		<br />
		<h2>INSTALLING UPDATES...</h2>

		<br />
		<div align="center">
			<div id="myProgress">
			  <div id="myBar">
			    <div id="label">10%</div>
			  </div>
			</div>
			<br />
			<div id="patchMsg">
			</div>
		</div>

<script>
	// move() -- Fisher Price(tm)-style progress bar and appropriate student feedback
	function move() {
		var elem = document.getElementById("myBar"); 
		var width = 10;
		var id = setInterval(frame, 30);
		function frame() {
			if (width >= 100) {
				clearInterval(id);
				<?php
					if($_SESSION['step3.patch']>0)
					{
						echo 'document.getElementById("patchMsg").innerHTML="<h3>Deja vu?<br />You have already patched your site, mate.<br />What should you do next?</h3>";'."\n";
					}
					else
					{
						echo 'document.getElementById("patchMsg").innerHTML="<h3>Congrats!<br />Installing updates is always a good move!<br />You patched your vulnerability which will keep attackers out for now.</h3>";'."\n".
							"window.score++;\n";
						$_SESSION['score']+=1;
						$_SESSION['step3.patch']=time();
					}
				?>
			} else {
				width++; 
				elem.style.width = width + '%'; 
				document.getElementById("label").innerHTML = width * 1 + '%';
			}
		}
	}
	move();
</script>

	<div align="center">
		<br />
		<br />
		<input class="menuButton transition" type="button" onClick="menuFunction('menu');" value="BACK TO MAIN MENU" /><br />
	</div>

	<?php
}
elseif($_REQUEST['screen']==='step4.logs')
{
	if($_SESSION['step4.logs']===0)
	{
		echo "<script>window.score++;</script>\n";
		$_SESSION['score']+=1;
		$_SESSION['step4.logs']=time();
	}

	$log='66.249.79.223 - - [12/Apr/2016:10:01:34 -0500] "GET /job/jail-administrator/ HTTP/1.1" 200 411543 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.5 - - [12/Apr/2016:10:01:41 -0500] "GET /robots.txt HTTP/1.1" 200 - "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.5 - - [12/Apr/2016:10:01:41 -0500] "GET / HTTP/1.1" 200 422375 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.213 - - [12/Apr/2016:10:01:54 -0500] "GET / HTTP/1.1" 200 422375 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.223 - - [12/Apr/2016:10:02:00 -0500] "GET /departments/animal-control/pet-behavior-information/ HTTP/1.1" 200 427471 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:02:07 -0500] "GET /calendar/action~week/time_limit~1525150800/request_format~html/ HTTP/1.1" 200 441461 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:02:13 -0500] "GET /calendar/action~week/time_limit~1401771600/request_format~html/ HTTP/1.1" 200 441461 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:02:26 -0500] "GET /calendar/action~oneday/time_limit~1246683600/request_format~html/ HTTP/1.1" 200 438365 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.223 - - [12/Apr/2016:10:02:32 -0500] "GET /calendar/action~week/time_limit~1426136400/request_format~html/ HTTP/1.1" 200 441461 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:02:39 -0500] "GET /departments-services/animal-control/index.php HTTP/1.1" 301 - "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:02:58 -0500] "GET /calendar/action~week/time_limit~1470718800/request_format~html/ HTTP/1.1" 200 441461 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:03:05 -0500] "GET /?attachment_id=2712 HTTP/1.1" 200 421900 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.223 - - [12/Apr/2016:10:03:11 -0500] "GET /calendar/action~week/time_limit~1496310739/request_format~html/ HTTP/1.1" 200 441461 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:03:31 -0500] "GET /spotlight/pottawattamie-county-treasurer-2013-annual-tax-sale/ HTTP/1.1" 200 430280 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:03:32 -0500] "GET /departments/auditor/election-results/ HTTP/1.1" 200 422911 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:03:37 -0500] "GET /resources/sheriff-foreclosure-list/ HTTP/1.1" 200 423015 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:03:44 -0500] "GET /departments/animal-control/useful-links/ HTTP/1.1" 200 423382 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:03:51 -0500] "GET /resources/property-taxes/ HTTP/1.1" 200 408261 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.113 - - [12/Apr/2016:10:04:03 -0500] "GET / HTTP/1.1" 200 422375 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.223 - - [12/Apr/2016:10:04:29 -0500] "GET /departments/engineeringroads/county-project-updates/ HTTP/1.1" 200 423898 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:04:42 -0500] "GET /resources/county-code/ HTTP/1.1" 200 414789 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:04:48 -0500] "GET /departments/county-attorney/criminal-division/ HTTP/1.1" 200 435551 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
69.63.121.3 - - [12/Apr/2016:10:05:01 -0500] "GET /quintessential/?i=1&s=b3eb7b43ed990015a8c5474a55187c59128e089f&e=1434693901&d=2 HTTP/1.0" 200 242 "-" "Wget/1.12 (linux-gnu)"
66.249.79.211 - - [12/Apr/2016:10:05:08 -0500] "GET /departments/assessor/ HTTP/1.1" 200 422803 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:05:53 -0500] "GET /departments/planning-and-development/flood-related-bid-letting/ HTTP/1.1" 200 422029 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:06:19 -0500] "GET /calendar/action~oneday/time_limit~1365742800/request_format~html/ HTTP/1.1" 200 438365 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:06:38 -0500] "GET /departments/communications911/overview/ HTTP/1.1" 200 424616 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:06:45 -0500] "GET /departments/engineeringroads/ HTTP/1.1" 200 427485 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
38.121.112.106 - - [12/Apr/2016:10:07:01 -0500] "GET /quintessential/?i=2&s=159ef7d73a75c80c2865e903103dbc4cf9429f7b&e=1434694021 HTTP/1.0" 200 2 "-" "Wget/1.12 (linux-gnu)"
98.188.136.52 - - [12/Apr/2016:10:07:02 -0500] "GET /quintessential/?i=8&s=df36d1c1f2c47d25de7c99f585123aa30715bba5&e=1434694022 HTTP/1.0" 200 2 "-" "Wget/1.10.2 (Red Hat modified)"
180.191.122.95 - - [12/Apr/2016:10:07:11 -0500] "GET /xmlrpc.php HTTP/1.1" 405 42 "-" "Mozilla/5.0 (X11; Linux i686; rv:2.0.1) Gecko/20100101 Firefox/4.0.1"
180.191.122.95 - - [12/Apr/2016:10:07:12 -0500] "GET /wp-login.php HTTP/1.1" 403 214 "-" "Mozilla/5.0 (X11; Linux i686; rv:2.0.1) Gecko/20100101 Firefox/4.0.1"
94.131.14.4 - - [12/Apr/2016:10:07:35 -0500] "POST /wp-content/plugins/work-the-flow-file-upload/public/assets/jQuery-File-Upload-9.5.0/server/php/index.php HTTP/1.1" 404 - "-" "Mozilla/5.0 (Windows NT 6.1; rv:34.0) Gecko/20100101 Firefox/34.0"
66.249.79.211 - - [12/Apr/2016:10:08:09 -0500] "GET /departments/planning-and-development/permit-applications/ HTTP/1.1" 200 438504 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.223 - - [12/Apr/2016:10:08:15 -0500] "GET /departments/communications911/enhanced-9-1-1/ HTTP/1.1" 200 426289 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:08:28 -0500] "GET /departments/community-services/general-assistance/ HTTP/1.1" 200 422586 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
98.188.36.173 - - [12/Apr/2016:10:08:29 -0500] "POST /wp-admin/admin-ajax.php HTTP/1.1" 200 36 "http://www.pottcounty.com/jobs/" "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko"
66.249.79.211 - - [12/Apr/2016:10:08:41 -0500] "GET /departments/county-attorney/victimwitness-division/ HTTP/1.1" 200 436131 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
206.72.26.236 - - [12/Apr/2016:10:09:01 -0500] "GET /quintessential/?i=3&s=9c8ef44a60903ab0323044d5692049e8bfbdf9e5&e=1434694141 HTTP/1.0" 200 2 "-" "Wget/1.12 (linux-gnu)"
66.249.79.211 - - [12/Apr/2016:10:09:39 -0500] "GET /about-the-county/ HTTP/1.1" 200 428224 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
98.188.36.173 - - [12/Apr/2016:10:09:59 -0500] "GET /job/telecommunications-operator-911-dispatcher/ HTTP/1.1" 200 410129 "http://www.pottcounty.com/jobs/" "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko"
98.188.36.173 - - [12/Apr/2016:10:10:01 -0500] "POST /wp-admin/admin-ajax.php HTTP/1.1" 200 36 "http://www.pottcounty.com/job/telecommunications-operator-911-dispatcher/" "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko"
69.63.121.3 - - [12/Apr/2016:10:10:01 -0500] "GET /quintessential/?i=1&s=7353e900653dfd62fb25e787d7c3e7c5128efe16&e=1434694201&d=2 HTTP/1.0" 200 242 "-" "Wget/1.12 (linux-gnu)"
66.249.79.211 - - [12/Apr/2016:10:10:14 -0500] "GET /jobs/all/ HTTP/1.1" 200 410098 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:10:44 -0500] "GET /departments/veteran-affairs/overview/ HTTP/1.1" 200 438825 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:11:10 -0500] "GET /departments/community-services/mental-health-first-aid/mental-health-first-aid/ HTTP/1.1" 200 426699 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:11:29 -0500] "GET /departments/county-attorney/overview/ HTTP/1.1" 200 424395 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:11:42 -0500] "GET /departments/auditor/register-to-vote/ HTTP/1.1" 200 424325 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.32 - - [12/Apr/2016:10:11:49 -0500] "GET /jobs/county-government/ HTTP/1.1" 200 409637 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:11:55 -0500] "GET /departments/animal-control/county-dog-license/ HTTP/1.1" 200 425009 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
70.58.55.23 - - [12/Apr/2016:10:12:30 -0500] "GET /fair/?sql=%20OR%201;-- HTTP/1.1" 200 425027 "-" "Mozilla/5.0 (compatible; DefacementToolkit/1.0; +http://pott.co/fair)"
70.58.55.23 - - [12/Apr/2016:10:12:31 -0500] "GET /fair/?hackable=yes.please HTTP/1.1" 200 425027 "-" "Mozilla/5.0 (compatible; DefacementToolkit/1.0; +http://pott.co/fair)"
70.58.55.23 - - [12/Apr/2016:10:12:32 -0500] "GET /fair/?edit=jumping&user=superadmin&pass=superadmin HTTP/1.1" 200 425027 "-" "Mozilla/5.0 (compatible; DefacementToolkit/1.0; +http://pott.co/fair)"
70.58.55.23 - - [12/Apr/2016:10:12:33 -0500] "GET /fair/?score=10 HTTP/1.1" 200 425027 "-" "Mozilla/5.0 (compatible; DefacementToolkit/1.0; +http://pott.co/fair)"
70.58.55.23 - - [12/Apr/2016:10:12:34 -0500] "GET /fair/?reset=1 HTTP/1.1" 200 425027 "-" "Mozilla/5.0 (compatible; DefacementToolkit/1.0; +http://pott.co/fair)"
66.249.79.223 - - [12/Apr/2016:10:12:34 -0500] "GET /departments/board-of-supervisors/overview/ HTTP/1.1" 200 425027 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:12:40 -0500] "GET /departments/animal-control/report-dog-fighting/ HTTP/1.1" 200 426344 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
104.239.197.165 - - [12/Apr/2016:10:12:50 -0500] "GET /government/board-supervisors/rep-appointments.php HTTP/1.1" 404 - "-" "Java/1.7.0_45"
66.249.79.211 - - [12/Apr/2016:10:12:53 -0500] "GET /departments/community-services/central-point-of-coordination/ HTTP/1.1" 200 422685 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.223 - - [12/Apr/2016:10:12:59 -0500] "GET /departments/county-attorney/juvenile-division/ HTTP/1.1" 200 435670 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:13:48 -0500] "GET /departments/county-attorney/victimwitness-division/ HTTP/1.1" 200 436131 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
68.180.228.234 - - [12/Apr/2016:10:13:49 -0500] "GET /departments/county-attorney/check-enforcement-program/ HTTP/1.1" 200 423290 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
66.249.79.235 - - [12/Apr/2016:10:13:55 -0500] "GET /departments/planning-and-development/land-use-plans/ HTTP/1.1" 200 433041 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:13:59 -0500] "GET /departments/information-technology/ HTTP/1.1" 200 423331 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.223 - - [12/Apr/2016:10:14:01 -0500] "GET /contact/ HTTP/1.1" 200 438497 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:14:03 -0500] "GET /job/seasonal-roadside-mowing-operator/ HTTP/1.1" 200 410213 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
23.253.161.172 - - [12/Apr/2016:10:14:05 -0500] "GET /government/meetings-minutes/index.php HTTP/1.1" 301 - "-" "Java/1.7.0_45"
23.253.161.172 - - [12/Apr/2016:10:14:06 -0500] "GET /government/meetings-minutes/ HTTP/1.1" 404 - "-" "Java/1.7.0_45"
66.249.79.235 - - [12/Apr/2016:10:14:25 -0500] "GET /departments/gis/gis-printable-maps/ HTTP/1.1" 404 - "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
69.63.121.3 - - [12/Apr/2016:10:15:02 -0500] "GET /quintessential/?i=1&s=09ae386aa12d5b9a9a8f0e9bf5c2fa6635faaf6e&e=1434694502&d=2 HTTP/1.0" 200 242 "-" "Wget/1.12 (linux-gnu)"
66.249.79.223 - - [12/Apr/2016:10:15:15 -0500] "GET /departments/auditor/find-your-polling-place/ HTTP/1.1" 301 - "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
157.55.39.140 - - [12/Apr/2016:10:15:17 -0500] "GET /departments/planning-and-development/overview/ HTTP/1.1" 200 425041 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
207.46.13.12 - - [12/Apr/2016:10:15:32 -0500] "GET /robots.txt HTTP/1.1" 302 222 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
68.180.228.234 - - [12/Apr/2016:10:16:37 -0500] "GET /?p=1208 HTTP/1.1" 301 - "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
66.249.79.211 - - [12/Apr/2016:10:17:02 -0500] "GET /calendar/action~month/exact_date~1559442502/request_format~html/ HTTP/1.1" 200 441096 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.235 - - [12/Apr/2016:10:17:20 -0500] "GET /calendar/action~week/exact_date~1630904400/request_format~html/ HTTP/1.1" 200 441364 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
70.167.225.100 - - [12/Apr/2016:10:18:00 -0500] "GET /quintessential/?i=4&s=4901948ca309d3138599af64f59a6fabafb88e18&e=1434694681 HTTP/1.0" 200 2 "-" "Wget/1.11.4 Red Hat modified"
66.249.79.235 - - [12/Apr/2016:10:18:13 -0500] "GET /calendar/action~month/exact_date~1533132649/request_format~html/ HTTP/1.1" 200 441418 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
173.57.239.187 - - [12/Apr/2016:10:18:26 -0500] "GET /xmlrpc.php HTTP/1.1" 405 42 "-" "Mozilla/5.0 (X11; Linux i686; rv:2.0.1) Gecko/20100101 Firefox/4.0.1"
173.57.239.187 - - [12/Apr/2016:10:18:26 -0500] "GET /wp-login.php HTTP/1.1" 403 214 "-" "Mozilla/5.0 (X11; Linux i686; rv:2.0.1) Gecko/20100101 Firefox/4.0.1"
66.249.79.223 - - [12/Apr/2016:10:18:36 -0500] "GET /departments/animal-control/spayneuter-information/ HTTP/1.1" 200 428337 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.211 - - [12/Apr/2016:10:19:27 -0500] "GET /departments/building-and-grounds/ HTTP/1.1" 200 422821 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.79.223 - - [12/Apr/2016:10:19:44 -0500] "GET /calendar/action~month/exact_date~1506842560/request_format~html/ HTTP/1.1" 200 441940 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
';
	?>
<h3>Log Search: Who's in Your Server?</h3>
<form>
	<input type="hidden" name="screen" value="step4.logs" />
	<input style="width:600px;" class="searchText" type="text" name="q" value="<?php echo $_REQUEST['q']?>" />&nbsp;<input class="searchButton" type="submit" value="Search" />&nbsp;<input class="searchButton transition" type="button" onClick="menuFunction('step4.logs');" value="Show All" /><br />
</form>

<br />
<div align="left">
<pre style="font-size:18px;">
<?php
	if(!isset($_REQUEST['q']))
	{
		echo $log;
	}
	else
	{
		$hits=0;
		foreach(preg_split('/[\r\n]+/',$log) as $line)
		{
			if(preg_match('/'.$_REQUEST['q'].'/i',$line))
			{
				echo $line."\n";
				$hits++;
			}
		}
		if($hits===0)
		{
			echo "Sorry, but your search returned zero (0) hits.\n";
		}
	}
?>
</pre>
</div>

	<div align="center">
		<br />
		<br />
		<input class="menuButton transition" type="button" onClick="menuFunction('menu');" value="BACK TO MAIN MENU" /><br />
	</div>
	<?php
}
elseif($_REQUEST['screen']==='step5.whois')
{
	if($_SESSION['step5.whois']===0)
	{
		echo "<script>window.score++;</script>\n";
		$_SESSION['score']+=1;
		$_SESSION['step5.whois']=time();
	}
	if($_SESSION['step5.whois.target']===0 && preg_match('/70\.58\.55\.23/',$_REQUEST['q']))
	{
		echo "<script>window.score+=2;</script>\n";
		$_SESSION['score']+=2;
		$_SESSION['step5.whois.target']=time();
	}

	?>
<h3>IP WHOIS SEARCH: See Who Owns an IP</h3>
<form>
	<input type="hidden" name="screen" value="step5.whois" />
	<input style="width:600px;" class="searchText" type="text" name="q" value="<?php echo $_REQUEST['q']?>" />&nbsp;<input class="searchButton" type="submit" value="Search" /><br />
</form>

<br />
<div align="left">
<pre style="font-size:18px;">
<?php
	if(!isset($_REQUEST['q']))
	{
		echo "Please enter an IP address for which to search.\n";
	}
	else
	{
		// Only do a WHOIS on a dotted-quad IP address (for simplicity and safety)
		if(preg_match('/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/',$_REQUEST['q'],$matches))
		{
			$safeIp=$matches[1];
			$whoisKey='whois.'.$safeIp;
			if(isset($_SESSION[$whoisKey]))											// show cached WHOIS data if we have it
			{
				echo "(from cache)\n";
				echo $_SESSION[$whoisKey];
			}
			else
			{
				$cmd=escapeshellcmd($cmd_whois).' "'.escapeshellcmd($safeIp).'"';	// build command (paranoid escaping)
				$_SESSION[$whoisKey]=shell_exec($cmd);								// run WHOIS command
				echo $_SESSION[$whoisKey];											// save output to PHP session var (cache)
			}
		}
		else
		{
			echo "Malformed query.  Please enter an IP address for which to search.\n";
		}
	}
?>
</pre>
</div>

	<div align="center">
		<br />
		<br />
		<input class="menuButton transition" type="button" onClick="menuFunction('menu');" value="BACK TO MAIN MENU" /><br />
	</div>
		<?php
	}
	elseif($_REQUEST['screen']==='help')	// About
	{
		?>
	<div align="center">
		<div align="justify" style="width:75%;">
			<p>This site is written in PHP, HTML, JavaScript, and CSS to teach some very basic cybersecurity incident response skills.  The points are worth nothing.  No warranty is given nor implied.  This site was built for use by 5th graders attending the Rotary Club 5th Grade Career Fair on 12 April 2016 at the Mid-America Center.  Cybersecurity / Digital Forensics as a career is presented by Special Deputy Anthony Kava of the Pottawattamie County Sheriff's Office, also IT Supervisor / Information Security Officer at Pottawattamie County.</p>

			<div align="right">akava //at// sheriff.pottcounty-ia.gov</div>
		</div>
	</div>

	<div align="center">
		<br />
		<br />
		<input class="menuButton transition" type="button" onClick="menuFunction('menu');" value="BACK TO MAIN MENU" /><br />
	</div>
		<?php
	}
	else									// Invalid choice
	{
		?>
		I'm sorry, Dave.  I'm afraid I can't do that.<br />
		<?php
	}
}
?>
