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
	
	$sqlResult = NULL;
	if ($type == "player")
	{
		$playerId = $_POST["player_id"];
		$name = $_POST["name"];
		$level = $_POST["level"];
		$xp = $_POST["xp"];
		$coins = $_POST["coins"];
		$farm_size = $_POST["farm_size"];
		$objects = $_POST["objects"];
		$stored_objects = $_POST["stored_objects"];
		$gift_receivers = $_POST["gift_receivers"];
		$query = "UPDATE players SET name = '{$name}', level = {$level}, xp = {$xp}, coins = {$coins}, farm_size = {$farm_size}, modified = CURRENT_TIMESTAMP(), objects = '{$objects}', stored_objects = '{$stored_objects}', gift_receivers = '{$gift_receivers}' WHERE player_id = {$playerId}";
		$sqlResult = mysql_query($query, $con);
	}
	else
	{
		$answerObject->error = "Unknown send type";
	}
	
	// RESULT
	if ($sqlResult)
	{
		$answerObject->isOk = TRUE;
		$answerObject->result = 0;
	}
	else
	{
		$answerObject->error = "Invalid query: " . mysql_error();
	}
}
echo json_encode($answerObject);

mysql_close($con);
?>