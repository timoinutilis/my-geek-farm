<?php
require_once('Answer.php');
require_once('serverconf.php');

$fbUserId = $_POST["fb_user_id"];

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
	
	$sqlResult = mysql_query("SELECT player_id, fb_id, name, level, xp, coins, farm_size, objects, stored_objects, gift_receivers FROM players WHERE fb_id = {$fbUserId}", $con);
	
	if ($sqlResult === FALSE)
	{
		$answerObject->error = "Invalid query: " . mysql_error();
	}
	else if (mysql_num_rows($sqlResult) > 0)
	{
		// existing user
		$row = mysql_fetch_object($sqlResult);
		$answerObject->isOk = TRUE;
		$answerObject->result = $row;
	}
	else
	{
		// create new user modified
		$sqlResult = mysql_query("INSERT INTO players (fb_id, modified) VALUES ('{$fbUserId}', CURRENT_TIMESTAMP())", $con);
		if ($sqlResult)
		{
			$userId = mysql_insert_id();
			
			$answerObject->isOk = TRUE;
			$answerObject->result = array(
				'player_id' => $userId,
				'fb_id' => $fbUserId,
			);
		}
		else
		{
			$answerObject->error = "Invalid query: " . mysql_error();
		}
	}
}
echo json_encode($answerObject);

mysql_close($con);
?>