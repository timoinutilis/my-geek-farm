package game
{
	import com.facebook.graph.Facebook;
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Security;
	import flash.utils.ByteArray;
	
	import gameDef.ItemsManager;
	
	import gameObjects.Player;
	
	import server.LoginService;
	import server.SendPlayerService;
	
	
	[SWF(width = "640", height = "480", frameRate = "30")]
	
	public class MyGeekFarm extends Sprite
	{
		public static const console:Console = new Console();
		public static const itemsManager:ItemsManager = new ItemsManager();
		public static const player:Player = new Player();
		
		public static var fbUid:String;
		public static var fbName:String;
		public static var fbFriends:String;
		public static var fbAppId:String;
		public static var fbRequests:String;
		public static var fbPermissions:String;
		
		private static var _serverTimeDiff:int;

		[Embed(source="items.csv", mimeType="application/octet-stream")]
		private const ItemsTable:Class;
		
		private var _interpreter:Interpreter;
		
		public function MyGeekFarm()
		{
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");
			
			stage.scaleMode = StageScaleMode.EXACT_FIT;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(e:Event):void
		{
			console.onInputCallback = onInput;
			addChild(console);
			
			var csv:CSVParser = new CSVParser();
			var items:Array = csv.parse(new ItemsTable() as ByteArray);
			itemsManager.load(items);
			
			var flashVars:Object = LoaderInfo(this.root.loaderInfo).parameters;
			fbUid = String(flashVars.fbuid);
			fbName = String(flashVars.fbname);
			fbFriends = String(flashVars.fbfriends);
			fbAppId = flashVars.fbappid as String;
			fbRequests = flashVars.fbrequests as String;
			fbPermissions = flashVars.fbpermissions as String;
			
			_interpreter = new Interpreter();
			_interpreter.onFinishExecute = promptInput;
			
			console.autoCompleteCallback = _interpreter.autoComplete;
			
			console.println("   _____          ________               __   ___________                     ");
			console.println("  /     \\ ___.__./  _____/  ____   ____ |  | _\\_   _____/____ _______  _____  ");
			console.println(" /  \\ /  <   |  /   \\  ____/ __ \\_/ __ \\|  |/ /|    __) \\__  \\\\_  __ \\/     \\ ");
			console.println("/    Y    \\___  \\    \\_\\  \\  ___/\\  ___/|    < |     \\   / __ \\|  | \\/  Y Y  \\");
			console.println("\\____|__  / ____|\\______  /\\___  >\\___  >__|_ \\\\___  /  (____  /__|  |__|_|  /");
			console.println("        \\/\\/            \\/     \\/     \\/     \\/    \\/        \\/            \\/ ");
			console.println("Hello at MyGeekFarm v1.1.1 by Inutilis Software!");
			console.println("");
			console.print("Logging in... ");
			var service:LoginService = new LoginService(fbUid, player, onLogin);
			service.request();
		}
		
		private function onLogin(service:LoginService):void
		{
			if (service.isOk)
			{
				console.println("OK");
				var time:int = new Date().getTime() / 1000;
				_serverTimeDiff = service.serverTime - time;
				if (player.name == null)
				{
					player.name = fbName;
				}
				if (fbAppId != null)
				{
					console.print("Facebook init... ");
					Facebook.init(fbAppId, onFbInit);
				}
				else
				{
					start();
				}
			}
			else
			{
				console.println("Error: " + service.error);
			}
		}
		
		private function onFbInit(success:Object, fail:Object):void
		{
			if (success != null)
			{
				if (fbRequests != null && fbRequests.length > 0)
				{
					// handle requests
					var batch:Array = [];
					var requests:Array = fbRequests.split(",");
					for each (var req:String in requests)
					{
						batch.push({"method":"GET", "relative_url":req});
						batch.push({"method":"DELETE", "relative_url":req});
					}
					Facebook.api("/", onFbRequestHandled, {batch: JSON.stringify(batch)}, "POST");
				}
				else
				{
					console.println("OK");
					start();
				}
			}
			else
			{
				console.println("Error: " + fail);
			}
		}

		private function onFbRequestHandled(success:Object, fail:Object):void
		{
			if (success != null)
			{
				console.println("OK");
				
				var gifts:Array = [];
				var batchAnswers:Array = success as Array;
				for each (var answer:Object in batchAnswers)
				{
					if (answer.code == 200)
					{
						var body:String = answer.body;
						if (body == "true")
						{
							// ignore answer from DELETE
						}
						else
						{
							// data from request
							var request:Object = JSON.parse(body);
							if (request.hasOwnProperty("data"))
							{
								var giftData:Object = JSON.parse(request.data);
								gifts.push(giftData);
							}
						}
					}
				}
								
				start(gifts);
			}
			else
			{
				console.println("Error: " + fail);
			}
		}

		private function start(gifts:Array = null):void
		{
			console.println("");
			player.print();
			console.println("");
			
			if (gifts != null && gifts.length > 0)
			{
				// add gifts to storage
				for each (var giftData:Object in gifts)
				{
					var giftID:int = giftData.id;
					player.addToStorage(giftID);
					console.println("- " + giftData.sender + " sent you " + itemsManager.getItem(giftID).name);
				}
				// save player
				var service:SendPlayerService = new SendPlayerService(player, onSaved);
				service.request();

				console.println("Find the items in your storage! And send something back!");
				console.println("");
			}

			console.println("Enter \"help\" to see all commands and \"tutorial\" to get an introduction of how");
			console.println("to play!");
			
			console.println("");
			console.println("Enter command!");
			promptInput();
		}
		
		private function onSaved(service:SendPlayerService):void
		{
			// ignore
		}
		
		private function promptInput():void
		{
			console.print(">");
			console.input();
		}
		
		private function onInput(input:String):void
		{
			_interpreter.execute(input);
		}
		
		public static function get currentTime():int
		{
			return _serverTimeDiff + new Date().getTime() / 1000;
		}

		public static function toggleFullscreen():void
		{
			try
			{
				var stage:Stage = console.stage;
				if (stage.displayState != StageDisplayState.NORMAL)
				{
					stage.displayState = StageDisplayState.NORMAL;
				}
				else
				{
					stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
				}
			}
			catch (e:SecurityError)
			{
				console.println("Error!");
			}
		}
		
		public static function exitFullscreen():void
		{
			var stage:Stage = console.stage;
			if (stage.displayState != StageDisplayState.NORMAL)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
		}
		
		public static function timeString(seconds:int):String
		{
			var hours:int = seconds / 60 / 60;
			var minutes:int = seconds / 60;

			var str:String = "";
			if (hours > 0)
			{
				str += hours + "h";
			}
			if (minutes > 0)
			{
				if (str.length > 0)
				{
					str += " ";
				}
				str += (minutes % 60) + "m";
			}
			if (seconds < 60)
			{
				if (str.length > 0)
				{
					str += " ";
				}
				str += (seconds % 60) + "s";
			}
			return str;
		}
		
		public static function hasPermission(permission:String):Boolean
		{
			return fbPermissions.split(",").indexOf(permission) != -1;
		}
		
	}
}