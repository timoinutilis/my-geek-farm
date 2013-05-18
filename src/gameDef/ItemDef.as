package gameDef
{
	public class ItemDef
	{
		public static const CAT_MONEY:String = "Money";
		public static const CAT_SEEDS:String = "Seeds";
		public static const CAT_TREES:String = "Trees";
		public static const CAT_ANIMALS:String = "Animals";
		public static const CAT_DECORATIONS:String = "Decorations";
		public static const CAT_EXTENSIONS:String = "Extensions";
		public static const CAT_ROBOTS:String = "Robots";
		
		public static const CAT_SORT_ORDER:Array = [CAT_SEEDS, CAT_TREES, CAT_ANIMALS, CAT_DECORATIONS, CAT_ROBOTS];
		
		private var _id:int;
		private var _category:String;
		private var _name:String;
		private var _price:int;
		private var _xp:int;
		private var _level:int;
		private var _collect:int;
		private var _time:int;
		private var _size:int;
		private var _data:int;
		private var _shop:Boolean;
		private var _gift:Boolean;
		
		public function ItemDef(object:Object)
		{
			_id = int(object.id);
			_category = String(object.category);
			_name = String(object.name);
			_price = int(object.price);
			_xp = int(object.xp);
			_level = int(object.level);
			_collect = int(object.collect);
			_time = int(object.time);
			_size = int(object.size);
			_data = int(object.data);
			_shop = Boolean(int(object.shop));
			_gift = Boolean(int(object.gift));
		}
		
		public function get id():int
		{
			return _id;
		}
		
		public function get category():String
		{
			return _category;
		}
		
		public function get name():String
		{
			return _name;
		}
		
		public function get price():int
		{
			return _price;
		}
		
		public function get xp():int
		{
			return _xp;
		}
		
		public function get level():int
		{
			return _level;
		}
		
		public function get collect():int
		{
			return _collect;
		}
		
		public function get time():int
		{
			return _time;
		}
		
		public function get timeSeconds():int
		{
			return _time * 60 * 60;
		}
		
		public function get size():int
		{
			return _size;
		}

		public function get data():int
		{
			return _data;
		}

		public function get shop():Boolean
		{
			return _shop;
		}

		public function get gift():Boolean
		{
			return _gift;
		}

		
	}
}