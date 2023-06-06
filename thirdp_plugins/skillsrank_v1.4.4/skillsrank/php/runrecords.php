<?
include("dbinfo.inc.php");
mysql_connect($host,$username,$password);
@mysql_select_db($database) or die( "Unable to select database");
$query="SELECT `nickNames`, `mapName`, `curDate`, `runTime` FROM `skillmaps` ORDER BY `mapName` ASC";
$result=mysql_query($query);

$num=mysql_numrows($result); 

mysql_close();

echo "<b><br><center><u><font face=verdana size=3 color=F4A21B>Skill@TFC4ever.de - Speed Run Records</b></u></font><br><br><br>";
?>

<title>Skill@TFC4ever.de - Speed run records</title>
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
<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2">  Mapname </font></th>
<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#00FF00">  Nickname  </font></th>
<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#00FFFF">  Record Date </font></th>
<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#FF0000">  Runtime  </font></th>
</tr>

<?
$i=0;
while ($i < $num) {
	$mapname=mysql_result($result,$i,"mapName");
	$nextmap=mysql_result($result,$i,"mapName");
	$recordtime = 0;
	$recordset = 0;
	
	while (($mapname == $nextmap) && ($i < $num)) {
		$runtime=mysql_result($result,$i,"runTime");
		if ($recordset == 0) {
			if ($runtime > 0) {
				$recordtime = $runtime;
				$recordset = 1;
				$nickname=mysql_result($result,$i,"nickNames");
				$curdate=mysql_result($result,$i,"curDate");
			}
		}
		if ($i < $num) {
			if ($i != $num-1) {
				$nexttime=mysql_result($result,$i+1,"runTime");
				$nextmap=mysql_result($result,$i+1,"mapName");
			} else {
				$nexttime=mysql_result($result,$i,"runTime");
				$nextmap=mysql_result($result,$i,"mapName");
			}
			if ($mapname == $nextmap && $i < $num-1) {
				if ($nexttime < $recordtime && $nexttime > 0) {
					$recordtime = $nexttime;
					$nickname=mysql_result($result,$i+1,"nickNames");
					$curdate=mysql_result($result,$i+1,"curDate");
				}
			} else {
				if ($recordtime > 0) {
					$hours = ($recordtime / 3600) % 24;
					if ($hours < 10)
						$hours = "0" . $hours;
					$minutes = ($recordtime / 60) % 60;
					if ($minutes < 10)
						$minutes = "0" . $minutes;
					$seconds = $recordtime % 60;
					if ($seconds < 10)
						$seconds = "0" . $seconds;
					$formatTime = $hours . ":" . $minutes . ":" . $seconds;
					
					?>
					<tr>
					<td align="left" bgcolor="#4C5844"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$mapname"; ?></font></td>
					<td align="center" bgcolor="#4c4d43"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$nickname"; ?></font></td>
					<td align="center" bgcolor="#4C5844"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$curdate"; ?></font></td>
					<td align="center" bgcolor="#4c4d43"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$formatTime"; ?></font></td>
					</tr>
					<?
				}
			}
		}
		++$i;
	}
}
echo "</table>";
?>
