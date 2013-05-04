package server
{
	import gameObjects.Player;

	public class LoginService extends Service
	{
		private var _player:Player;
		
		public function LoginService(fbUid:String, player:Player, onCompleteFunc:Function)
		{
			super(onCompleteFunc);
			
			_variables.fb_user_id = fbUid;
			
			_player = player;
		}
		
		override protected function get serviceUrl():String
		{
			return "http://api.inutilis.de/farm/login.php";
		}
		
		override protected function parseResult(result:Object):void
		{
			_player.playerId = int(result.player_id);
			_player.fbUid = String(result.fb_id);

			if (result.name)
			{
				// loaded player
				_player.name = String(result.name);
				_player.level = int(result.level);
				_player.xp = int(result.xp);
				_player.coins = int(result.coins);
				_player.farmSize = int(result.farm_size);
				_player.loadFarm(parseJSON(result.objects) as Array);
				_player.loadStorage(result.stored_objects ? parseJSON(result.stored_objects) as Object : {});
				_player.loadGiftReceivers(result.gift_receivers ? parseJSON(result.gift_receivers) as Object : {});
			}
			else
			{
				// create default player
				_player.loadFarm([]);
				
				_player.addReadyFarmObject(100);
				_player.addReadyFarmObject(101);
			}
		}
		
	}
}