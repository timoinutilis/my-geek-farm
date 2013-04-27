<?php
require_once('Answer.php');
require_once('serverconf.php');

$type = $_POST["type"];

$answerObject = new Answer;
$answerObject->serverTime = time();

// CONNECT

$con = mysql_connect($mysql_host, $mysql_user, $mysql_password);
if (!$con)
{
	$answerObject->error = mysql_error();
}
else
{
	mysql_select_db($mysql_database, $con);
	
	
	// COMMANDS
	
	$query = NULL;
	if ($type == "player")
	{
		$playerId = $_POST["player_id"];
		$query = "SELECT player_id, fb_id, name, level, xp, coins, farm_size, objects, stored_objects, gift_receivers FROM players WHERE player_id = {$playerId}";
	}
	else if ($type == "neighbors")
	{
		$fbIds = $_POST["fb_ids"];
		$query = "SELECT player_id, fb_id, name, level, xp, coins, farm_size FROM players WHERE fb_id IN ({$fbIds})";
	}

	// QUERY AND RESULT
	if ($query != NULL)
	{
		$sqlResult = mysql_query($query, $con);
		$resultArray = array();
		
		while ($row = mysql_fetch_object($sqlResult))
		{
			$resultArray[] = $row;
		}
		
		$answerObject->isOk = TRUE;
		$answerObject->result = $resultArray;
	}
	else
	{
		$answerObject->error = "Unknown request type";
	}
}
echo json_encode($answerObject);

mysql_close($con);
?>