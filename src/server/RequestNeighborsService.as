package server
{
	import com.adobe.serialization.json.JSON;
	
	import gameObjects.Player;

	public class RequestNeighborsService extends RequestService
	{
		public var neighbors:Vector.<Player>;
		
		public function RequestNeighborsService(friends:String, onCompleteFunc:Function)
		{
			super("neighbors", onCompleteFunc);
			
			_variables.fb_ids = friends;
		}
		
		override protected function parseResult(result:Object):void
		{
			neighbors = new Vector.<Player>();
			
			var neighborsData:Array = result as Array;
			
			for each (var data:Object in neighborsData)
			{
				if (data.name)
				{
					var neighbor:Player = new Player();
					neighbor.playerId = int(data.player_id);
					neighbor.fbUid = String(data.fb_id);
					neighbor.name = String(data.name);
					neighbor.level = int(data.level);
					neighbor.xp = int(data.xp);
					neighbor.coins = int(data.coins);
					neighbor.farmSize = int(data.farm_size);
					neighbors.push(neighbor);
				}
			}
		}

	}
}