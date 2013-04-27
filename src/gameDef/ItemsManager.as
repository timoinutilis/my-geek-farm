package gameDef
{
	public class ItemsManager
	{
		public static const ID_PLOT:int = 1;
		
		private var _items:Array;
		private var _itemsById:Object;
		
		public function ItemsManager()
		{
		}
		
		public function load(array:Array):void
		{
			_items = new Array();
			_itemsById = new Object();
			
			for each (var itemObj:Object in array)
			{
				var item:ItemDef = new ItemDef(itemObj);
				_items.push(item);
				_itemsById[item.id] = item;
			}
		}
		
		public function getItem(id:int):ItemDef
		{
			return _itemsById[id] as ItemDef;
		}
		
		public function get items():Array
		{
			return _items;
		}

	}
}