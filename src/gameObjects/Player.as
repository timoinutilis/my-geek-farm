package gameObjects
{
	import game.MyGeekFarm;
	
	import gameDef.ItemDef;
	import gameDef.ItemsManager;

	public class Player
	{
		public static const SORT_COLUMNS:Array = ["category", "id", "name", "state"];

		public var fbUid:String;
		public var playerId:int;
		public var name:String;
		public var level:int = 1;
		public var xp:int = 0;
		public var coins:int = 20;
		public var farmSize:int = 20;
		
		private var _objects:Vector.<FarmObject> = new <FarmObject>[];
		private var _objectsById:Object = {};
		private var _nextFreeId:int = 1;
		private var _farmLoaded:Boolean;
		
		private var _storedObjects:Object = {};
		private var _storageLoaded:Boolean;
		private var _giftReceivers:Object = {};
		
		public function Player()
		{
		}
		
		// FARM
		
		public function loadFarm(objects:Array):void
		{
			for each (var obj:Object in objects)
			{
				var farmObject:FarmObject = FarmObject.create(obj);
				addFarmObject(farmObject);
			}
			_farmLoaded = true;
		}
		
		public function farmToObjects():Array
		{
			var objects:Array = [];
			
			for each (var farmObject:FarmObject in _objects)
			{
				objects.push(farmObject.toObject());
			}
			
			return objects;
		}
		
		public function get farmObjects():Vector.<FarmObject>
		{
			return _objects;
		}
		
		public function getFarmObject(id:int):FarmObject
		{
			return _objectsById[id] as FarmObject;
		}
		
		public function addFarmObject(object:FarmObject):void
		{
			_objects.push(object);
			_objectsById[object.id] = object;
			if (object.id >= _nextFreeId)
			{
				_nextFreeId = object.id + 1;
			}
		}
		
		public function removeFarmObject(object:FarmObject):void
		{
			var index:int = _objects.indexOf(object);
			_objects.splice(index, 1);
			delete _objectsById[object.id];
		}
		
		public function get nextFreeId():int
		{
			return _nextFreeId;
		}
		
		public function addReadyFarmObject(itemId:int):void
		{
			var obj:FarmObject = new FarmObject(nextFreeId);
			obj.itemId = itemId;
			obj.state = FarmObject.STATE_GROWING;
			obj.timestamp = MyGeekFarm.currentTime - obj.itemDef.timeSeconds;
			addFarmObject(obj);
		}
		
		public function sortFarm(column:String):void
		{
			if (column == "category")
			{
				_objects.sort(function(a:FarmObject, b:FarmObject):int {
					if (a.itemDef.category == b.itemDef.category)
					{
						return a.id - b.id;
					}
					return ItemDef.CAT_SORT_ORDER.indexOf(a.itemDef.category) - ItemDef.CAT_SORT_ORDER.indexOf(b.itemDef.category);
				});
			}
			if (column == "id")
			{
				_objects.sort(function(a:FarmObject, b:FarmObject):int {
					return a.id - b.id;
				});
			}
			if (column == "name")
			{
				_objects.sort(function(a:FarmObject, b:FarmObject):int {
					if (a.itemDef.name < b.itemDef.name)
					{
						return -1;
					}
					if (a.itemDef.name > b.itemDef.name)
					{
						return 1;
					}
					return a.id - b.id;
				});
			}
			if (column == "state")
			{
				_objects.sort(function(a:FarmObject, b:FarmObject):int {
					if (a.state == b.state)
					{
						if (a.state == FarmObject.STATE_GROWING)
						{
							return a.remainingTime - b.remainingTime;
						}
						return a.id - b.id;
					}
					return FarmObject.STATE_SORT_ORDER.indexOf(a.state) - FarmObject.STATE_SORT_ORDER.indexOf(b.state);
				});
			}
		}
		
		// STORAGE
		
		public function loadStorage(objects:Object):void
		{
			_storedObjects = objects;
			_storageLoaded = true;
		}
		
		public function get storedObjects():Object
		{
			return _storedObjects;
		}
		
		public function getStoredObjectAmount(itemId:int):int
		{
			if (_storedObjects.hasOwnProperty(itemId))
			{
				return _storedObjects[itemId];
			}
			return 0;
		}
		
		public function addToStorage(itemId:int):void
		{
			if (_storedObjects.hasOwnProperty(itemId))
			{
				_storedObjects[itemId]++;
			}
			else
			{
				_storedObjects[itemId] = 1;
			}
		}
		
		public function removeFromStorage(itemId:int):void
		{
			var amount:int = getStoredObjectAmount(itemId);
			if (amount > 1)
			{
				_storedObjects[itemId]--;
			}
			else
			{
				delete _storedObjects[itemId];
			}
		}
		
		// GIFTS
		
		public function loadGiftReceivers(objects:Object):void
		{
			_giftReceivers = objects;
		}
		
		public function addGiftReceiver(id:String):void
		{
			_giftReceivers[id] = MyGeekFarm.currentTime;
		}
		
		public function getGiftReceivers(time:int):Array
		{
			var receivers:Array = [];
			var minTime:int = MyGeekFarm.currentTime - time;
			for (var id:String in _giftReceivers)
			{
				if (_giftReceivers[id] >= minTime)
				{
					receivers.push(id);
				}
			}
			return receivers;
		}
		
		public function get giftReceivers():Object
		{
			return _giftReceivers;
		}
		
		// PLAYER
		
		public function print(header:Boolean = true):void
		{
			if (header)
			{
				MyGeekFarm.console.printTableLn(["ID", "NAME", "COINS", "LEVEL", "XP / NEXT", "USED / FARM SIZE"], [0, 8, 30, 40, 48, 62]);
			}
			var usedSpace:String = _farmLoaded ? calcUsedSpace().toString() : "?"
			MyGeekFarm.console.printTableLn(["[" + playerId + "]", name, coins, level, xp + " / " + levelUpXp(level), usedSpace + " / " + farmSize], [0, 8, 30, 40, 48, 62]);
		}
		
		public function printFarm():void
		{
			MyGeekFarm.console.printTableLn(["ID", "NAME", "STATE"], [0, 6, 40]);
			for each (var object:FarmObject in farmObjects)
			{
				object.print();
			}
		}
		
		public function printStorage():void
		{
			MyGeekFarm.console.printTableLn(["ID", "NAME", "AMOUNT"], [0, 6, 40]);
			for (var idString:String in storedObjects)
			{
				var id:int = int(idString);
				var def:ItemDef = MyGeekFarm.itemsManager.getItem(id);
				MyGeekFarm.console.printTableLn([id, def.name, getStoredObjectAmount(id)], [0, 6, 40]);
			}
		}

		public function calcUsedSpace():int
		{
			var used:int = 0;
			for each (var object:FarmObject in farmObjects)
			{
				used += object.itemDef.size;
			}
			return used;
		}
		
		public function hasSpace(def:ItemDef):Boolean
		{
			return (calcUsedSpace() + def.size > farmSize);
		}

		public function update():void
		{
			for each (var object:FarmObject in _objects)
			{
				object.update();
			}
		}
		
		public function pay(def:ItemDef):void
		{
			coins -= def.price;
			xp += def.xp;
			MyGeekFarm.console.println("-" + def.price + " Coins, +" + def.xp + " XP");
			checkLevelUp();
		}
		
		public function earn(def:ItemDef):void
		{
			coins += def.collect;
			if (def.category == ItemDef.CAT_TREES)
			{
				xp += def.xp;
				MyGeekFarm.console.println("+" + def.collect + " Coins, +" + def.xp + " XP");
				checkLevelUp();
			}
			else
			{
				MyGeekFarm.console.println("+" + def.collect + " Coins");
			}
		}
		
		public function expand(size:int):void
		{
			farmSize = size;
			MyGeekFarm.console.println("Farm Size: " + farmSize + ", used: " + calcUsedSpace());
		}
		
		public function levelUpXp(fromLevel:int):int
		{
			return (1 + fromLevel * fromLevel) * 10;
		}
		
		public function checkLevelUp():void
		{
			while (xp >= levelUpXp(level))
			{
				level++;
				MyGeekFarm.console.println("  _                _   _   _      ");
				MyGeekFarm.console.println(" | |   _____ _____| | | | | |_ __ ");
				MyGeekFarm.console.println(" | |__/ -_) V / -_) | | |_| | '_ \\");
				MyGeekFarm.console.println(" |____\\___|\\_/\\___|_|  \\___/| .__/");
				MyGeekFarm.console.println("                            |_|   ");
				MyGeekFarm.console.println("You are now level " + level + ". Check the shop for new items!");
			}
		}
		
		public function isItemAvailable(def:ItemDef, allowNextLevel:Boolean = false):Boolean
		{
			if (def.id == ItemsManager.ID_PLOT)
			{
				return false;
			}
			if (def.level > (allowNextLevel ? (level + 1) : level))
			{
				return false;
			}
			if (def.category == ItemDef.CAT_EXTENSIONS && (def.size <= farmSize || def.size > farmSize * 2))
			{
				return false;
			}
			return true;
		}
		
	}
}