<?php

$mysql_host = "localhost";
$mysql_user = "admin_farm";
$mysql_password = "inutilisgame";
$mysql_database = "admin_farm";

$days = $_GET["days"];

$con = mysql_connect($mysql_host, $mysql_user, $mysql_password);
if ($con)
{
	mysql_select_db($mysql_database, $con);

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
	<head>
		<title>MyGeekFarm Statistics</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	</head>

	<body>
	<h1>Statistics for the last <?php echo $days; ?> days</h1>
	<?php showUsers($con, $days); ?>
	</body>
</html>
<?php
	mysql_close($con);
}
else
{
	echo "Error connecting to server";
}

function showUsers($connection, $numDays)
{
//	$sqlResult = mysql_query("SELECT player_id, fb_id, name, level, xp, coins, farm_size, modified FROM players WHERE modified >= CURRENT_TIMESTAMP() - INTERVAL {$numDays} ORDER BY modified DESC", $connection);
	$sqlResult = mysql_query("SELECT player_id, fb_id, name, level, xp, coins, farm_size, modified FROM players ORDER BY modified DESC", $connection);
	showTable($sqlResult);
}

function showTable($sqlResult)
{
	echo '<table border="1" width="100%">';
	
	$showTitle = TRUE;
	while ($row = mysql_fetch_assoc($sqlResult))
	{
		if ($showTitle)
		{
			echo "<tr>";
			foreach ($row as $key => $value)
			{
				echo "<th>{$key}</th>";
			}
			echo "</tr>";
			$showTitle = FALSE;
		}
		echo "<tr>";
		foreach ($row as $value)
		{
			echo "<td>$value</td>";
		}
		echo "</tr>";
	}
	
	echo "</table>";
} 

?>