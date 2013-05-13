package game
{
	import com.facebook.graph.Facebook;
	
	import flash.display.BitmapData;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import gameDef.ItemDef;
	import gameDef.ItemsManager;
	
	import gameObjects.FarmObject;
	import gameObjects.Player;
	
	import server.RequestNeighborsService;
	import server.RequestPlayerService;
	import server.SendPlayerService;
	

	public class Interpreter
	{
		[Embed(source="tutorial.txt", mimeType="application/octet-stream")]
		private const TutorialText:Class;
		
		public static const AUTO_SAVE_SECONDS:int = 5;

		private static const OK:int = 0;
		private static const INCORRECT:int = 1;
		private static const WAIT:int = 2;

		public var onFinishExecute:Function;
		
		private var _commandsByName:Object;
		private var _commands:Array;
		private var _sendPlayerService:SendPlayerService;
		private var _autoSaveTimer:Timer;

		
		public function Interpreter()
		{
			_autoSaveTimer = new Timer(AUTO_SAVE_SECONDS * 1000, 1);
			_autoSaveTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAutoSaveTimer);
			
			initCommands();
		}
		
		public function execute(line:String, isScripted:Boolean = false):void
		{
			var cmdResult:int = OK;
			var parts:Array = line.split(" ");
			var commandName:String = (parts[0] as String).toLowerCase();
			var command:CommandInfo = _commandsByName[commandName];
			if (command != null)
			{
				if (isScripted && !command.allowedInScript)
				{
					println("Command not allowed in script!");
				}
				else if (parts.length > 1 && (parts[1] as String).toLowerCase() == "h")
				{
					if (command.params != null)
					{
						println(command.name + " " + command.params);
					}
					printwr(command.help);
				}
				else
				{
					MyGeekFarm.player.update();
					cmdResult = command.cmdFunc(parts);
					if (cmdResult == INCORRECT)
					{
						println("Incorrect parameters. Enter \"" + command.name + " h\" to get help for command.");
					}
				}
			}
			else
			{
				println("Unknown command. Enter \"help\" to see all commands!");
			}
			
			if (!isScripted && cmdResult != WAIT)
			{
				onFinishExecute();
			}
		}
		
		public function autoComplete(input:String):String
		{
			var lowInput:String = input.toLowerCase();
			var bestMatch:String = null;
			var indexSpace:int = lowInput.indexOf(" ");
			if (indexSpace != -1)
			{
				var cmdName:String = lowInput.substr(0, indexSpace);
				var rest:String = lowInput.substr(indexSpace + 1);
				var restMatch:String = null;
				if (cmdName == "shop")
				{
					restMatch = findMatch(rest, [ItemDef.CAT_ANIMALS, ItemDef.CAT_DECORATIONS, ItemDef.CAT_EXTENSIONS, ItemDef.CAT_SEEDS, ItemDef.CAT_TREES, ItemDef.CAT_ROBOTS]);
				}
				else if (cmdName == "plow")
				{
					restMatch = findMatch(rest, ["new"]);
				}
				if (restMatch != null)
				{
					bestMatch = cmdName + " " + restMatch;
				}
			}
			else
			{
				for each (var cmd:CommandInfo in _commands)
				{
					if (   lowInput == cmd.name.substr(0, lowInput.length)
						&& (bestMatch == null || lowInput.length > bestMatch.length) )
					{
						bestMatch = cmd.name;
					}
				}
			}
			return bestMatch;
		}
		
		private function findMatch(input:String, options:Array):String
		{
			var bestMatch:String = null;
			for each (var option:String in options)
			{
				if (   input == option.substr(0, input.length).toLowerCase()
					&& (bestMatch == null || input.length > bestMatch.length) )
				{
					bestMatch = option;
				}
			}
			return bestMatch;
		}
		
		private function initCommands():void
		{
			_commands = [];
			_commandsByName = {};
			
			addCommand("help", null, "Show all available commands.", cmdHelp);
			addCommand("shop", "(<category>)", "Show all shop items or only from category.", cmdShop);
			addCommand("buy", "<itemID> (<plotID>)", "Buy item from shop. If it's a seed, put it on plot.", cmdBuy);
			addCommand("player", null, "Show status of player.", cmdPlayer);
			addCommand("farm", null, "Show all items on farm.", cmdFarm);
			addCommand("plow", "<plotID>/new", "Plow existing or new plot.", cmdPlow);
			addCommand("collect", "<ID>", "Harvest plot or collect from item.", cmdCollect);
			addCommand("fullscreen", null, "Toggle between full screen and window.", cmdFullscreen);
			addCommand("neighbors", null, "Show your neighbors.", cmdNeighbors, false);
			addCommand("visit", "<neighborID>", "Show all items on farm of neighbor.", cmdVisit, false);
			addCommand("save", null, "Save current game. Anyway game is auto-saving every " + AUTO_SAVE_SECONDS + " seconds.", cmdSave, false);
			addCommand("remove", "<ID>", "Remove item from farm.", cmdRemove);
			addCommand("invite", null, "Invite friends.", cmdInvite, false);
			addCommand("clear", null, "Clears the screen.", cmdClear);
			addCommand("tutorial", null, "Show an introduction of how to play the game.", cmdTutorial);
			addCommand("photo", null, "Publish a screenshot in Facebook.", cmdPhoto, false);
			addCommand("gifts", null, "Show all items you can send as gifts for free.", cmdGifts);
			addCommand("sendgift", "<itemID>", "Send item from gifts to neighbors for free.", cmdSendGift, false);
			addCommand("storage", null, "Show all items in your storage. Use \"take\" command to get something from there.", cmdStorage);
			addCommand("take", "<storageItemID> (<plotID>)", "Take item from storage to farm. If it's a seed, put it on plot.", cmdTake);
			
			addCommand("robot.program", "<robotID> <comma separated commands...>", "Store given command calls (with parameters) in the robot. Example: \"robot.program 5 collect 1, collect 2, plow 1, plow 2\"", cmdRobotProgram, false);
			addCommand("robot.run", "<robotID>", "Execute all stored commands of the robot.", cmdRobotRun, false);
			addCommand("robot.show", "<robotID>", "Show stored commands of the robot.", cmdRobotShow);
			addCommand("robot.name", "<robotID> <name>", "Change the name of the robot.", cmdRobotName);
//			addCommand("xp", "<xp>", "Give XP", cmdXP);
			
			_commands.sortOn("name");
		}
		
		private function addCommand(name:String, params:String, help:String, cmdFunc:Function, allowedInScript:Boolean = true):void
		{
			var cmd:CommandInfo = new CommandInfo(name, params, help, cmdFunc, allowedInScript);
			_commands.push(cmd);
			_commandsByName[name] = cmd;
		}
		
		private function print(text:String):void
		{
			MyGeekFarm.console.print(text);
		}
		
		private function println(text:String):void
		{
			MyGeekFarm.console.println(text);
		}

		private function printwr(text:String):void
		{
			MyGeekFarm.console.printWrapped(text);
		}

		private function printTableLn(cells:Array, positions:Array):void
		{
			MyGeekFarm.console.printTableLn(cells, positions);
		}
		
		private function getString(parts:Array, index:int):String
		{
			return (parts.length > index) ? (parts[index] as String) : null;
		}

		private function getLowerString(parts:Array, index:int):String
		{
			return (parts.length > index) ? (parts[index] as String).toLowerCase() : null;
		}
		
		private function getInt(parts:Array, index:int):int
		{
			return (parts.length > index) ? parseInt(parts[index] as String) : -1;
		}
		
		private function cmdHelp(parts:Array):int
		{
			for each (var command:CommandInfo in _commands)
			{
				println(command.name);
			}
			println("To get help for a command, enter command name and \"h\" (e.g. \"buy h\")!");
			return OK;
		}
		
		private function cmdSave(parts:Array):int
		{
			_sendPlayerService = null;
			_autoSaveTimer.reset();
			
			print("Saving... ");
			var service:SendPlayerService = new SendPlayerService(MyGeekFarm.player, onSaved);
			service.request();
			return WAIT;
		}
		
		private function onSaved(service:SendPlayerService):void
		{
			if (service.isOk)
			{
				println("OK");
			}
			else
			{
				println("Error: " + service.error);
			}
			onFinishExecute();
		}
		
		private function cmdFullscreen(parts:Array):int
		{
			MyGeekFarm.toggleFullscreen();
			return OK;
		}
		
		private function cmdNeighbors(parts:Array):int
		{
			print("Loading... ");
			var service:RequestNeighborsService = new RequestNeighborsService(MyGeekFarm.fbFriends, onLoadedNeighbors);
			service.request();
			return WAIT;
		}
		
		private function onLoadedNeighbors(service:RequestNeighborsService):void
		{
			if (service.isOk)
			{
				println("OK");
				var first:Boolean = true;
				for each (var neighbor:Player in service.neighbors)
				{
					neighbor.print(first);
					first = false;
				}
			}
			else
			{
				println("Error: " + service.error);
			}
			onFinishExecute();
		}

		private function cmdVisit(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			
			if (id > 0)
			{
				print("Loading... ");
				var service:RequestPlayerService = new RequestPlayerService(id, onLoadedNeighbor);
				service.request();
				return WAIT;
			}
			return INCORRECT;
		}
		
		private function onLoadedNeighbor(service:RequestPlayerService):void
		{
			if (service.isOk)
			{
				if (service.player == null)
				{
					println("Unknown ID");
				}
				else
				{
					println("OK");
					service.player.print();
					println("");
					service.player.update();
					service.player.printFarm();
				}
			}
			else
			{
				println("Error: " + service.error);
			}
			onFinishExecute();
		}

		private function cmdShop(parts:Array):int
		{
			var category:String = getLowerString(parts, 1);
			
//			MyGeekFarm.itemsManager.items.sortOn(["category", "id"], [0, Array.NUMERIC]);
			var currentCategory:String = null;

			printTableLn(["ID", "NAME", "PRICE", "XP", "EARN", "GROW TIME", "SIZE"], [0, 8, 38, 46, 54, 62, 74]);
			for each (var def:ItemDef in MyGeekFarm.itemsManager.items)
			{
				if (def.shop && MyGeekFarm.player.isItemAvailable(def, true) && (category == null || category == def.category.toLocaleLowerCase()))
				{
					if (def.category != currentCategory)
					{
						println("");
						println(def.category);
						currentCategory = def.category;
					}
					if (def.level <= MyGeekFarm.player.level)
					{
						printTableLn(["[" + def.id + "]", def.name, def.price + "c", def.xp, def.collect + "c", def.time + "h", def.size], [0, 8, 38, 46, 54, 62, 74]);
					}
					else
					{
						// NEXT LEVEL!
						printTableLn(["[---]", def.name, "--UNLOCK AT NEXT LEVEL!--"], [0, 8, 38]);
					}
				}
			}
			return OK;
		}

		private function cmdBuy(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			
			if (id < 0)
			{
				println("Missing ID!");
			}
			else
			{
				var def:ItemDef = MyGeekFarm.itemsManager.getItem(id);
				if (def == null || def.id == ItemsManager.ID_PLOT)
				{
					println("Unknown item ID!");
				}
				else
				{
					if (!def.shop || !MyGeekFarm.player.isItemAvailable(def))
					{
						println("Item is not available now!");
					}
					else if (def.price > MyGeekFarm.player.coins)
					{
						println("Not enough coins!");
					}
					else if (def.category == ItemDef.CAT_SEEDS)
					{
						var plotId:int = getInt(parts, 2);
						if (plotId < 0)
						{
							println("ID of plot missing!");
						}
						else
						{
							var plot:FarmObject = MyGeekFarm.player.getFarmObject(plotId);
							if (plot == null)
							{
								println("Unknown plot ID!");
							}
							else
							{
								if (plot.itemDef.category == ItemDef.CAT_SEEDS)
								{
									println("Plot is in use already!");
								}
								else if (plot.itemId != ItemsManager.ID_PLOT)
								{
									println("Not a plot!");
								}
								else if (plot.state != FarmObject.STATE_PLOWED)
								{
									println("Plot is not plowed!");
								}
								else
								{
									MyGeekFarm.player.pay(def);
									plot.init(def);
									onPlayerChange();
								}
								return OK;
							}
						}
						return INCORRECT;
					}
					else if (def.category == ItemDef.CAT_EXTENSIONS)
					{
						MyGeekFarm.player.pay(def);
						MyGeekFarm.player.expand(def.size);
						onPlayerChange();
						return OK;
					}
					else if (MyGeekFarm.player.hasSpace(def))
					{
						println("Not enough space on farm!");
					}
					else
					{
						var object:FarmObject = new FarmObject(MyGeekFarm.player.nextFreeId);
						MyGeekFarm.player.addFarmObject(object);
						MyGeekFarm.player.pay(def);
						object.init(def);
						onPlayerChange();
					}
					return OK;
				}
			}
			return INCORRECT;
		}

		private function cmdPlayer(parts:Array):int
		{
			MyGeekFarm.player.print();
			return OK;
		}

		private function cmdFarm(parts:Array):int
		{
			MyGeekFarm.player.printFarm();
			return OK;
		}
		
		private function cmdPlow(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			var param:String = getLowerString(parts, 1);

			var def:ItemDef = MyGeekFarm.itemsManager.getItem(ItemsManager.ID_PLOT);
			var object:FarmObject;
			
			if (def.price > MyGeekFarm.player.coins)
			{
				println("Not enough coins!");
				return OK;
			}
			else if (param == "new")
			{
				if (MyGeekFarm.player.hasSpace(def))
				{
					println("Not enough space on farm!");
					return OK;
				}
				object = new FarmObject(MyGeekFarm.player.nextFreeId);
				MyGeekFarm.player.addFarmObject(object);
			}
			else if (id < 0)
			{
				println("ID of plot or \"new\" missing!");
			}
			else
			{
				object = MyGeekFarm.player.getFarmObject(id);
				if (object == null)
				{
					println("Unknown plot ID!");
				}
				else
				{
					if (object.itemId != ItemsManager.ID_PLOT && object.itemDef.category != ItemDef.CAT_SEEDS)
					{
						println("Not a plot!");
						return OK;
					}
					else if (object.itemDef.category == ItemDef.CAT_SEEDS && (object.state == FarmObject.STATE_GROWING || object.state == FarmObject.STATE_READY))
					{
						println("Still a nice plant!");
						return OK;
					}
					else if (object.state == FarmObject.STATE_PLOWED)
					{
						println("Already plowed!");
						return OK;
					}
				}
			}

			if (object != null)
			{
				MyGeekFarm.player.pay(def);
				object.plow();
				onPlayerChange();
				return OK;
			}
			return INCORRECT;
		}
		
		private function cmdCollect(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			
			if (id < 0)
			{
				println("ID missing!");
			}
			else
			{
				var object:FarmObject = MyGeekFarm.player.getFarmObject(id);
				if (object == null)
				{
					println("Unknown ID!");
				}
				else
				{
					if (object.itemDef.category == ItemDef.CAT_SEEDS && object.state == FarmObject.STATE_WITHERED)
					{
						println("Plot needs to be plowed!");
					}
					else if (object.state != FarmObject.STATE_READY && object.state != FarmObject.STATE_WITHERED)
					{
						println("Cannot be harvested/collected (yet)!");
					}
					else
					{
						if (object.state == FarmObject.STATE_READY)
						{
							MyGeekFarm.player.earn(object.itemDef);
						}
						object.collect();
						if (object.state == FarmObject.STATE_KILLED)
						{
							MyGeekFarm.player.removeFarmObject(object);
						}
						onPlayerChange();
					}
					return OK;
				}
			}
			
			return INCORRECT;
		}
		
		private function cmdRemove(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			
			if (id < 0)
			{
				println("ID missing!");
			}
			else
			{
				var object:FarmObject = MyGeekFarm.player.getFarmObject(id);
				if (object == null)
				{
					println("Unknown ID!");
				}
				else
				{
					MyGeekFarm.player.removeFarmObject(object);
					println("Removed " + object.itemDef.name);
					onPlayerChange();
					return OK;
				}
			}
			
			return INCORRECT;
		}
		
		private function cmdInvite(parts:Array):int
		{
			if (MyGeekFarm.fbAppId != null)
			{
				MyGeekFarm.exitFullscreen();
				var params:Object = {
					title: "Invite people (can be friends) to play MyGeekFarm!",
					message: "I would like to have you as a geek neighbor.",
					filters: ["app_non_users"]
				};
				Facebook.ui("apprequests", params);
			}
			return OK;
		}
		
		private function cmdClear(parts:Array):int
		{
			MyGeekFarm.console.clear();
			return OK;
		}
		
		private function cmdTutorial(parts:Array):int
		{
			var textBytes:ByteArray = new TutorialText() as ByteArray;
			var text:String = textBytes.toString();
			
			var paraphs:Array = text.split("\n");
			for each (var paraph:String in paraphs)
			{
				printwr(paraph);
			}
			return OK;
		}
		
		private function cmdPhoto(parts:Array):int
		{
			if (MyGeekFarm.hasPermission("publish_actions"))
			{
				print("Publishing photo... ");
				var bmd:BitmapData = MyGeekFarm.console.createScreenshot();
				Facebook.api("/me/photos", onPhoto, {"source":bmd, "fileName":"MyGeekFarm_" + MyGeekFarm.currentTime + ".png"}, "POST");
			}
			else
			{
				print("Getting permission... ");
				MyGeekFarm.exitFullscreen();
				Facebook.ui("permissions.request", {"perms":"publish_actions"}, onPermissions);
			}
			return WAIT;
		}
		
		private function onPhoto(success:Object, fail:Object):void
		{
			if (success != null)
			{
				println("OK");
			}
			else
			{
				println("Error: " + fail);
			}
			onFinishExecute();
		}
		
		private function onPermissions(response:Object):void
		{
			if (response != null && response.perms)
			{
				MyGeekFarm.fbPermissions = response.perms as String;
				if (MyGeekFarm.hasPermission("publish_actions"))
				{
					println("OK");
					println("No photo made yet. Enter \"photo\" again!");
				}
				else
				{
					println("Failed");
				}
			}
			else
			{
				println("Failed");
			}
			onFinishExecute();
		}
		
		private function cmdGifts(parts:Array):int
		{
			var currentCategory:String = null;
			printTableLn(["ID", "NAME"], [0, 8]);
			for each (var def:ItemDef in MyGeekFarm.itemsManager.items)
			{
				if (def.gift && MyGeekFarm.player.isItemAvailable(def, true))
				{
					if (def.category != currentCategory)
					{
						println("");
						println(def.category);
						currentCategory = def.category;
					}
					if (def.level <= MyGeekFarm.player.level)
					{
						printTableLn(["[" + def.id + "]", def.name], [0, 8]);
					}
					else
					{
						printTableLn(["[---]", def.name, "--UNLOCK AT NEXT LEVEL!--"], [0, 8, 40]);
					}
				}
			}
			return OK;
		}
		
		private function cmdSendGift(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			
			if (id < 0)
			{
				println("Missing ID!");
			}
			else
			{
				var def:ItemDef = MyGeekFarm.itemsManager.getItem(id);
				if (def == null || def.id == ItemsManager.ID_PLOT)
				{
					println("Unknown item ID!");
				}
				else
				{
					if (!MyGeekFarm.player.isItemAvailable(def))
					{
						println("Item is not available now!");
					}
					else if (!def.gift)
					{
						println("Item cannot be sent as free gift!");
					}
					else
					{
						if (MyGeekFarm.fbAppId != null)
						{
							print("Sending... ");
							var lastReceivers:Array = MyGeekFarm.player.getGiftReceivers(23 * 60 * 60); // receivers of the last 23 hours
							
							MyGeekFarm.exitFullscreen();
							var params:Object = {
								title: "Send " + def.name + " to...",
								message: "I sent you " + def.name + " as a gift.",
								data: {sender: MyGeekFarm.player.name.substr(0, 30), id: id},
								filters: ["app_users"],
								exclude_ids: lastReceivers
							};
							Facebook.ui("apprequests", params, onGiftsSent);
						}
						return WAIT;
					}
				}
			}
			return INCORRECT;
		}
		
		private function onGiftsSent(response:Object):void
		{
			if (response != null && response.to)
			{
				var toIDs:Array = response.to;
				for each (var id:String in toIDs)
				{
					MyGeekFarm.player.addGiftReceiver(id);
				}
				println(toIDs.length + " gift(s) sent");
				onPlayerChange();
			}
			else
			{
				println("Nothing sent");
			}
			onFinishExecute();
		}
		
		private function cmdStorage(parts:Array):int
		{
			MyGeekFarm.player.printStorage();
			return OK;
		}
		
		private function cmdTake(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			
			if (id < 0)
			{
				println("Missing ID!");
			}
			else
			{
				if (MyGeekFarm.player.getStoredObjectAmount(id) == 0)
				{
					println("Not available in storage!");
				}
				else
				{
					var def:ItemDef = MyGeekFarm.itemsManager.getItem(id);
					if (def.category == ItemDef.CAT_MONEY)
					{
						// add money
						MyGeekFarm.player.earn(def);
						MyGeekFarm.player.removeFromStorage(id);
						onPlayerChange();
					}
					else if (def.category == ItemDef.CAT_SEEDS)
					{
						var plotId:int = getInt(parts, 2);
						if (plotId < 0)
						{
							println("ID of plot missing!");
						}
						else
						{
							var plot:FarmObject = MyGeekFarm.player.getFarmObject(plotId);
							if (plot == null)
							{
								println("Unknown plot ID!");
							}
							else
							{
								if (plot.itemDef.category == ItemDef.CAT_SEEDS)
								{
									println("Plot is in use already!");
								}
								else if (plot.itemId != ItemsManager.ID_PLOT)
								{
									println("Not a plot!");
								}
								else if (plot.state != FarmObject.STATE_PLOWED)
								{
									println("Plot is not plowed!");
								}
								else
								{
									MyGeekFarm.player.removeFromStorage(id);
									plot.init(def);
									onPlayerChange();
								}
								return OK;
							}
						}
						return INCORRECT;
					}
					else if (MyGeekFarm.player.hasSpace(def))
					{
						println("Not enough space on farm!");
					}
					else
					{
						// add normal item to farm
						MyGeekFarm.player.removeFromStorage(id);
						var object:FarmObject = new FarmObject(MyGeekFarm.player.nextFreeId);
						MyGeekFarm.player.addFarmObject(object);
						object.init(def);
						onPlayerChange();
					}
					return OK;
				}
			}
			return INCORRECT;
		}
		
		private function cmdRobotProgram(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			
			if (id < 0)
			{
				println("Missing ID!");
			}
			else
			{
				var object:FarmObject = MyGeekFarm.player.getFarmObject(id);
				if (object == null)
				{
					println("Unknown ID!");
				}
				else if (object.itemDef.category != ItemDef.CAT_ROBOTS)
				{
					println("Not a robot!");
					return OK;
				}
				else
				{
					var macro:String = parts.slice(2).join(" ");
					var commands:Array = macro.split(",");
					if (commands.length > object.itemDef.data)
					{
						println("Error: " + object.itemDef.name + " can only store up to " + object.itemDef.data + " commands!");
					}
					else
					{
						object.text = macro;
						println("Program stored by " + object.fullName + " (" + commands.length + " commands).");
						onPlayerChange();
					}
					return OK;
				}
			}
			return INCORRECT;
		}
		
		private function cmdRobotRun(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			
			if (id < 0)
			{
				println("Missing ID!");
			}
			else
			{
				var object:FarmObject = MyGeekFarm.player.getFarmObject(id);
				if (object == null)
				{
					println("Unknown ID!");
				}
				else if (object.itemDef.category != ItemDef.CAT_ROBOTS)
				{
					println("Not a robot!");
					return OK;
				}
				else if (object.text == null || object.text.length == 0)
				{
					println("Robot is not programmed yet!");
					return OK;
				}
				else
				{
					var lines:Array = object.text.split(",");
					var trim:RegExp = /^\s+|\s+$/g;
					for each (var line:String in lines)
					{
						line = line.replace(trim, "");
						println("=>" + line);
						execute(line, true);
					}
					return OK;
				}
			}
			return INCORRECT;
		}
		
		private function cmdRobotShow(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			
			if (id < 0)
			{
				println("Missing ID!");
			}
			else
			{
				var object:FarmObject = MyGeekFarm.player.getFarmObject(id);
				if (object == null)
				{
					println("Unknown ID!");
				}
				else if (object.itemDef.category != ItemDef.CAT_ROBOTS)
				{
					println("Not a robot!");
					return OK;
				}
				else if (object.text == null || object.text.length == 0)
				{
					println("Robot is not programmed yet!");
					return OK;
				}
				else
				{
					printwr(object.text);
					return OK;
				}
			}
			return INCORRECT;
		}

		private function cmdRobotName(parts:Array):int
		{
			var id:int = getInt(parts, 1);
			var name:String = getString(parts, 2);
			
			if (id < 0)
			{
				println("Missing ID!");
			}
			else
			{
				var object:FarmObject = MyGeekFarm.player.getFarmObject(id);
				if (object == null)
				{
					println("Unknown ID!");
				}
				else if (object.itemDef.category != ItemDef.CAT_ROBOTS)
				{
					println("Not a robot!");
					return OK;
				}
				else if (name == null || name.length == 0)
				{
					println("Missing name!");
				}
				else
				{
					var completeName:String = parts.slice(2).join(" ");
					object.name = completeName.substr(0, 20);
					object.print();
					onPlayerChange();
					return OK;
				}
			}
			return INCORRECT;
		}
		
		private function cmdXP(parts:Array):void
		{
			var xp:int = getInt(parts, 1);
			MyGeekFarm.player.xp += xp;
			MyGeekFarm.player.checkLevelUp();
		}
		
		private function onPlayerChange():void
		{
			if (_sendPlayerService == null)
			{
				_autoSaveTimer.start();
			}
			_sendPlayerService = new SendPlayerService(MyGeekFarm.player, onAutoSaved);
			trace("Player Changed");
		}
		
		private function onAutoSaveTimer(e:TimerEvent):void
		{
			_autoSaveTimer.reset();
			if (_sendPlayerService != null)
			{
				_sendPlayerService.request();
				_sendPlayerService = null;
			}
		}
		
		private function onAutoSaved(service:SendPlayerService):void
		{
			// ignore
			trace("Autosaved");
		}

	}
}