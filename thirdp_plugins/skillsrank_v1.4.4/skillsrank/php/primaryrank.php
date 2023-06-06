<?
include("dbinfo.inc.php");
mysql_connect($host,$username,$password);
@mysql_select_db($database) or die( "Unable to select database");
$query="SELECT `steamId`, `nickNames`, `nFinnished`, `rankTotal`, `primaryRank` FROM `skillrank` ORDER BY ABS(primaryRank) DESC";
$result=mysql_query($query);

$num=mysql_numrows($result); 

mysql_close();

echo "<b><br><center><u><font face=verdana size=3 color=F4A21B>Skill@TFC4ever.de - Skillsrank</b></u></font><br><br>
<font face=verdana size=2>Ordered by average difficulty of finished maps</center></font><br>
<center><font face=verdana size=2>
Sort by <a href=index.php>Nickname</a> | <a href=nfinished.php>Finished times</a> | <a href=ranktotal.php>Collected Points</a>
</font><br><br></center><br>";

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
<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2">  Nickname  </font></th>
<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#00FF00">  Finished Times  </font></th>
<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#00FFFF">  Collected Points </font></th>
<th align="center" bgcolor="#403F2E"><font face="verdana, Arial, Helvetica, sans-serif" size="2" color="#FF0000">  Average Difficulty  </font></th>
</tr>

<?
$i=0;
while ($i < $num) {
	$steamid=mysql_result($result,$i,"steamId");
	$nickname=mysql_result($result,$i,"nickNames");
	$nfinished=mysql_result($result,$i,"nFinnished");
	$totalrank=mysql_result($result,$i,"rankTotal");
	$primaryrank=mysql_result($result,$i,"primaryRank");
	$nicknameurl="<a href=playerstats.php?steamid=" . $steamid . "&nickname=" . urlencode($nickname) . "&nfinished=" . $nfinished . "&totalrank=" . $totalrank . "&primaryrank=" . $primaryrank . " style=\"text-decoration:none\">" . $nickname . "</a>";
	?>
	<tr> 
	<td align="left" bgcolor="#4C5844"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo $nicknameurl; ?></font></td>
	<td align="center" bgcolor="#4c4d43"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$nfinished"; ?></font></td>
	<td align="center" bgcolor="#4C5844"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$totalrank"; ?></font></td>
	<td align="center" bgcolor="#4c4d43"><font face="verdana, Arial, Helvetica, sans-serif" size="2"><? echo "$primaryrank"; ?></font></td>
	</tr>
	<?
	++$i;
} 
echo "</table>";
?>
