package server
{
	import gameObjects.Player;

	public class RequestPlayerService extends RequestService
	{
		public var player:Player;

		public function RequestPlayerService(playerId:int, onCompleteFunc:Function)
		{
			super("player", onCompleteFunc);
			
			_variables.player_id = playerId;
		}
		
		override protected function parseResult(result:Object):void
		{
			var playersData:Array = result as Array;
			
			if (playersData.length > 0)
			{
				var data:Object = playersData[0];
				if (data.name)
				{
					player = new Player();
					player.playerId = int(data.player_id);
					player.fbUid = String(data.fb_id);
					player.name = String(data.name);
					player.level = int(data.level);
					player.xp = int(data.xp);
					player.coins = int(data.coins);
					player.farmSize = int(data.farm_size);
					player.loadFarm(parseJSON(data.objects) as Array);
				}
			}
		}

	}
}