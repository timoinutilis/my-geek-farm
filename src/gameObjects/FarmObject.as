package gameObjects
{
	import game.MyGeekFarm;
	
	import gameDef.ItemDef;
	import gameDef.ItemsManager;

	public class FarmObject
	{
		public static const STATE_PLOWED:int = 0;
		public static const STATE_UNPLOWED:int = 1;
		public static const STATE_GROWING:int = 2;
		public static const STATE_READY:int = 3;
		public static const STATE_WITHERED:int = 4;
		public static const STATE_KILLED:int = 5;
		public static const STATE_BEING_THERE:int = 6;
		
		public static const MIN_WITHER_HOURS:int = 48;
		
		private var _id:int;
		
		public var itemId:int;
		public var state:int;
		public var timestamp:int;
		public var name:String;
		public var text:String;
		
		public static function create(object:Object):FarmObject
		{
			var farmObject:FarmObject = new FarmObject(int(object.id));
			farmObject.itemId = object.iid;
			farmObject.state = object.st;
			farmObject.timestamp = object.ts;
			farmObject.name = object.na;
			farmObject.text = object.tx;
			return farmObject;
		}
		
		public function FarmObject(id:int)
		{
			_id = id;
		}
		
		public function toObject():Object
		{
			var object:Object = {
				id: _id,
				iid: itemId,
				st: state,
				ts: timestamp
			};
			if (name != null)
			{
				object.na = name;
			}
			if (text != null)
			{
				object.tx = text;
			}
			return object;
		}
		
		public function get id():int
		{
			return _id;
		}
		
		public function get itemDef():ItemDef
		{
			return MyGeekFarm.itemsManager.getItem(itemId);
		}
		
		public function get fullName():String
		{
			var fullName:String = itemDef.name;
			if (name != null)
			{
				fullName += " \"" + name + "\"";
			}
			return fullName;
		}
		
		public function print():void
		{
			var stateStr:String;
			
			switch (state)
			{
				case STATE_PLOWED:
					stateStr = "Plowed";
					break;
				case STATE_UNPLOWED:
					stateStr = "Unplowed";
					break;
				case STATE_GROWING:
					var growTime:int = itemDef.timeSeconds;
					var passedTime:int = MyGeekFarm.currentTime - timestamp;
					stateStr = "Growing (" + MyGeekFarm.timeString(growTime - passedTime) + ")";
					break;
				case STATE_READY:
					stateStr = "Ready";
					break;
				case STATE_WITHERED:
					stateStr = "Withered";
					break;
				case STATE_BEING_THERE:
					stateStr = "Being There";
					break;
				case STATE_KILLED:
					stateStr = "Killed";
					break;
			}
			
			MyGeekFarm.console.printTableLn(["[" + id + "]", fullName, stateStr], [0, 6, 40]);
		}

		public function update():void
		{
			var category:String = itemDef.category;
			
			if (category != ItemDef.CAT_DECORATIONS)
			{
				var passedTime:int = MyGeekFarm.currentTime - timestamp;
				var growTime:int = itemDef.timeSeconds;
	
				if (state == STATE_GROWING || state == STATE_READY)
				{
					var witherTime:int = Math.max(growTime, MIN_WITHER_HOURS * 60 * 60);
					if (category != ItemDef.CAT_ANIMALS && passedTime >= growTime + witherTime)
					{
						state = STATE_WITHERED;
					}
					else if (passedTime >= growTime)
					{
						state = STATE_READY;
					}
				}
			}
		}
		
		public function init(def:ItemDef):void
		{
			itemId = def.id;
			if (def.category == ItemDef.CAT_ROBOTS)
			{
				state = STATE_BEING_THERE;
				timestamp = 0;
				name = "Unnamed";
			}
			else if (def.category == ItemDef.CAT_DECORATIONS)
			{
				state = STATE_BEING_THERE;
				timestamp = 0;
			}
			else
			{
				state = STATE_GROWING;
				timestamp = MyGeekFarm.currentTime;
			}
			print();
		}

		public function plow():void
		{
			itemId = ItemsManager.ID_PLOT;
			state = STATE_PLOWED;
			timestamp = 0;
			print();
		}
		
		public function collect():void
		{
			var category:String = itemDef.category;
			if (category == ItemDef.CAT_SEEDS)
			{
				MyGeekFarm.console.println("Plant harvested and sold.");
				itemId = ItemsManager.ID_PLOT;
				state = STATE_UNPLOWED;
				timestamp = 0;
			}
			if (category == ItemDef.CAT_ANIMALS)
			{
				MyGeekFarm.console.println("Animal killed and sold.");
				state = STATE_KILLED;
				timestamp = 0;
			}
			else if (category == ItemDef.CAT_TREES)
			{
				if (state == STATE_READY)
				{
					MyGeekFarm.console.println("Fruits collected and sold.");
				}
				else
				{
					MyGeekFarm.console.println("Withered fruits removed.");
				}
				state = STATE_GROWING;
				timestamp = MyGeekFarm.currentTime;
			}
			print();
		}
	}
}