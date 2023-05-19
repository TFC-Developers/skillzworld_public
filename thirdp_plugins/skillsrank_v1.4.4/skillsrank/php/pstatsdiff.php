<?
include("dbinfo.inc.php");
mysql_connect($host,$username,$password);
@mysql_select_db($database) or die( "Unable to select database");
$query="SELECT `steamId`, `mapName`, `curDate`, `difficulty`, `runTime` FROM `skillmaps` WHERE `steamId` = \"$steamid\" ORDER BY difficulty ASC";
$result=mysql_query($query);

$num=mysql_numrows($result); 

mysql_close();

echo "<b><br><center><u><font face=verdana size=3 color=F4A21B>Skill@TFC4ever.de - Player Stats</b></u></font><br><br>
<b><font face=verdana size=4>$nickname</center><b></font><br><br>";
?>

<title>Skill@TFC4ever.de - Skillsrank</title>
<head>
<STYLE type="text/css">
BODY {scrollbar-3dlight-color:#2E8B57;
	scrollbar-arrow-color:#F4A21B;
	scrollbar-base-color:#4D5546;
	scrollbar-track-color:#33382E;
	scrollbar-darkshadow-color:#000000;
	scrollbar-face-color:#4D5546;
	scrollbar-highlight-color:#000000;
scrollbar-shadow-color:#404040;}
</STYLE>
</head>

<BODY BGCOLOR="#4D5546" TEXT="#FFFFFF" LINK="#ff9900" VLINK="#ff9900" ALINK="#ff9900" leftmargin=0 rightmargin=0 topmargin=0 bottommargin=0 marginheight=0 marginwidth=0>
<div align="center">
<table border="1" bordercolor="#000000" cellspacing="0" cellpadding="0" width="570" style="border-collapse: collapse">
<tr> 
	<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#FFFFFF"> Finished maps </font></th>
	<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#00FF00"> Collected points    </font></th>
	<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#00FFFF">  Average Difficulty </font></th>
</tr>
<tr> 
	<td align="center" bgcolor="#4c4d43"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$nfinished"; ?></font></td>
	<td align="center" bgcolor="#4C5844"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$totalrank"; ?></font></td>
	<td align="center" bgcolor="#4c4d43"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$primaryrank"; ?></font></td>
</tr>
</table><br><br>

<b><br><center><font face=verdana size=3 color=F4A21B>Finished Maps</b></font><br><br>
Ordered by difficulty</center><br>
<center><font face=verdana size=2>
<?
	$stats1url="<a href=playerstats.php?steamid=" . $steamid . "&nickname=" . urlencode($nickname) . "&nfinished=" . $nfinished . "&totalrank=" . $totalrank . "&primaryrank=" . $primaryrank . " style=\"text-decoration:none\"> Mapname </a>";
	$stats2url="<a href=pstatsdate.php?steamid=" . $steamid . "&nickname=" . urlencode($nickname) . "&nfinished=" . $nfinished . "&totalrank=" . $totalrank . "&primaryrank=" . $primaryrank . " style=\"text-decoration:none\"> Date </a>";
	$stats3url="<a href=pstatsdiff.php?steamid=" . $steamid . "&nickname=" . urlencode($nickname) . "&nfinished=" . $nfinished . "&totalrank=" . $totalrank . "&primaryrank=" . $primaryrank . " style=\"text-decoration:none\"> Difficulty </a>";
	$stats4url="<a href=pstatsruntime.php?steamid=" . $steamid . "&nickname=" . urlencode($nickname) . "&nfinished=" . $nfinished . "&totalrank=" . $totalrank . "&primaryrank=" . $primaryrank . " style=\"text-decoration:none\"> Runtime </a>";
?>
Sort by <? echo $stats1url; ?> | <? echo $stats2url; ?> | <? echo $stats3url; ?> | <? echo $stats4url; ?> 
</font><br><br></center><br>

<div align="center">
<table border="1" bordercolor="#000000" cellspacing="0" cellpadding="0" width="570" style="border-collapse: collapse">
<tr> 
	<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#FFFFFF"> Mapname </font></th>
	<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#00FF00"> Date finished </font></th>
	<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#00FFFF"> Difficulty </font></th>
	<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="##FF0000"> Runtime </font></th>
</tr>

<?
$i=0;
while ($i < $num) {
	$mapname=mysql_result($result,$i,"mapName");
	$curdate=mysql_result($result,$i,"curDate");
	$difficulty=mysql_result($result,$i,"difficulty");
	$runtime=mysql_result($result,$i,"runTime");
	if ($runtime == 0) {
		$formatTime = "00:00:00";
	} else {
		$hours = ($runtime / 3600) % 24;
			if ($hours < 10)
				$hours = "0" . $hours;
		$minutes = ($runtime / 60) % 60;
			if ($minutes < 10)
				$minutes = "0" . $minutes;
		$seconds = $runtime % 60;
			if ($seconds < 10)
				$seconds = "0" . $seconds;
		$formatTime = $hours . ":" . $minutes . ":" . $seconds;
	}
	?>
	<tr> 
	<td align="left" bgcolor="#4C5844"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$mapname"; ?></font></td>
	<td align="center" bgcolor="#4c4d43"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$curdate"; ?></font></td>
	<td align="center" bgcolor="#4C5844"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$difficulty"; ?></font></td>
	<td align="center" bgcolor="#4c4d43"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$formatTime"; ?></font></td>
	</tr>
	<?
	++$i;
} 
echo "</table>";
?>
