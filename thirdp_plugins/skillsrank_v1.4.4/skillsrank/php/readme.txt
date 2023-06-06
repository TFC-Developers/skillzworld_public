Almost all stats from the skillsrank plugin are shown ingame.
These php pages shows stats for each player and the speedrun records.

Installation
============

Make a folder on your webspace and put all php pages there.
Open dbinfo.inc.php and fill in the info about your database.

Update to readme: 07-05-10
==========================

If you use these php pages on a remote host you can get problems with the
pages that creates links to the individual players stats. If this happens
you will get an empty player stats file, because the server didnt receive the
steam id to query for. If this happens to you you can try and apply DAWG's fix to this:


============= Quote DAWG ===========================================
It can be easily fixed by adding this line to each of the .php pages.

ADD THIS: 
Code:
$steamid = $_GET["steamid"]; 

to the top so it looks like this: 

Code:
<?
include("dbinfo.inc.php");
mysql_connect($host,$username,$password);
@mysql_select_db($database) or die( "Unable to select database");
$steamid = $_GET["steamid"];
$query="SELECT `steamId`, `nickNames`, `nFinnished`, `rankTotal`, `primaryRank` FROM `skillrank` ORDER BY ABS(nFinnished) DESC";
$result=mysql_query($query);I added mine right after line #4 (ie:the "mysql_select" line) and all is now working great.

NOTE: Use this method if registering globals on in the .HTACCESS did not fix the problem, (or if you don't/can't want to mess with the
.HTACCESS file)
=====================================================================