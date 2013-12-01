<?php
require_once('fb/facebook.php');

if (isset($_GET['gameversion']))
{
	$gameVersion = $_GET['gameversion'];
}
else
{
	$gameVersion = '1.1';
}
$appId = '506892022682269';

$facebook = new Facebook(array(
  'appId'  => $appId,
  'secret' => 'e3e57614dd43fe1618031d8bd8a0bd83'
));

$needsLogin = TRUE;

// Get User ID
$user = $facebook->getUser();

if ($user)
{
	try
	{
		// Proceed knowing you have a logged in user who's authenticated.
		$userProfile = $facebook->api('/me');
		$userFriends = $facebook->api('/me/friends');
		$userPermissions = $facebook->api("/me/permissions");
		$needsLogin = FALSE;
	}
	catch (FacebookApiException $e)
	{
	}
}

?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en"> 
    <head>
        <title></title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <style type="text/css" media="screen"> 
            html, body  { height:100%; }
            body { margin:0; padding:0; overflow:auto; text-align:center; 
                   background-color: #ffffff;
                   font-family: "Helvetica Neue", Arial, Helvetica, "Nimbus Sans L", sans-serif; }   
            object:focus { outline:none; }
            
            table {
            	width: 100%;
            	height: 100%;
            	border-collapse: separate;
				border-spacing: 5px;
            }
            table, tr, td {
            	margin: 0;
            	padding: 0;
            }
            #topBar {
            	height: 25px;
            }
            #topBar td {
            	text-align: left;
            }
            #topBar span {
            	display: inline-block;
            	float: right;
            	font-size: 12px;
            }
            #topBar span a {
            	text-decoration: none;
            	color: black;
            }
            #topBar span a:hover {
            	text-decoration: underline;
            }
            #topBar span img {
            	margin-left: 20px;
            	margin-top: 2px;
            }
            #sideBar {
            	width: 118px;
            }
            #gameContainer {
            	/*width: 100%;*/
            	height: 100%;
            }
        </style>
<?php

if ($needsLogin)
{
	$params = array(
		'redirect_uri' => 'http://apps.facebook.com/MyGeekFarm/'
	);

	$loginUrl = $facebook->getLoginUrl($params);
?>
		<script>top.location.href="<?php echo $loginUrl; ?>"</script>
	</head>
	<body>
	</body>
<?php
}
else
{
	$username = $userProfile["username"];
	$friends = $userFriends["data"];
	$friendIds = array();
	foreach ($friends as $friend) {
		$friendIds[] = $friend["id"];
	}
	$friendList = implode($friendIds, ",");
	$requests = isset($_GET["request_ids"]) ? $_GET["request_ids"] : "";
	$permissionObject = $userPermissions['data'][0];
	$permissionArray = array();
	foreach ($permissionObject as $perm => $value) {
		if ($value == 1) {
			$permissionArray[] = $perm;
		}
	}
	$permissions = implode($permissionArray, ",");
?>
		<script type="text/javascript" src="//connect.facebook.net/en_US/all.js"></script>
        <script type="text/javascript" src="swfobject.js"></script>
        <script type="text/javascript">

            var flashvars = {};
            flashvars.fbuid = '<?php echo $user; ?>';
            flashvars.fbname = '<?php echo $username; ?>';
            flashvars.fbfriends = '<?php echo $friendList; ?>';
            flashvars.fbappid = '<?php echo $appId; ?>';
            flashvars.fbrequests = '<?php echo $requests; ?>';
            flashvars.fbpermissions = '<?php echo $permissions; ?>';
            
            var params = {};
            params.quality = "high";
            params.bgcolor = "#ffffff";
            params.allowscriptaccess = "sameDomain";
            params.allowfullscreen = "true";
            params.allowfullscreeninteractive = "true";
            
            var attributes = {};
            attributes.id = "MyGeekFarm";
            attributes.name = "MyGeekFarm";
            attributes.align = "middle";
            
            swfobject.embedSWF(
                "MyGeekFarm_v<?php echo $gameVersion; ?>.swf", "flashContent", 
                "100%", "100%", 
                "10.2.0",
                "expressInstall.swf", 
                flashvars, params, attributes);
                
        </script>
    </head>
    <body>
        <div id="fb-root"></div>

		<table>
		<tr id="topBar">
		
		<td>
		<iframe src="//www.facebook.com/plugins/like.php?href=http%3A%2F%2Fwww.facebook.com%2FMyGeekFarm&amp;send=false&amp;layout=standard&amp;width=450&amp;show_faces=false&amp;font&amp;colorscheme=light&amp;action=like&amp;height=25&amp;appId=<?php echo $appId; ?>" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:450px; height:25px;" allowTransparency="true"></iframe>
		<span><a href="//www.facebook.com/MyGeekFarm" target="_top">MyGeekFarm news and feedback</a> <a href="http://www.inutilis.com" target="_top"><img src="inutilis.png" /></a></span>
        </td>
        
        </tr>

		<tr>
		<td id="gameContainer">

        <div id="flashContent">
            <p>
                To view this page ensure that Adobe Flash Player version 
                10.2.0 or greater is installed. 
            </p>
        </div>

        </td>
        
        </tr>
        </table>

   </body>
<?php
}
?>
</html>
