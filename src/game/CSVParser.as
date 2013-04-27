package game
{
	import flash.utils.ByteArray;

	public class CSVParser
	{
		public function CSVParser()
		{
		}
		
		public function parse(data:ByteArray):Array
		{
			var string:String = data.readUTFBytes(data.length);
			var lines:Array = string.split(/\n/);
			var fields:Array = null;
			var objects:Array = [];
			for each (var line:String in lines)
			{
				var cells:Array = line.split(/,/);
				if (fields == null)
				{
					fields = cells;
				}
				else if (cells.length == fields.length)
				{
					var object:Object = {};
					for (var i:int = 0; i < fields.length; i++)
					{
						object[fields[i]] = cells[i];
					}
					objects.push(object);
				}
			}
			return objects;
		}
	}
}