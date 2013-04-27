package server
{
	import gameObjects.Player;

	public class SendPlayerService extends SendService
	{
		public function SendPlayerService(player:Player, onCompleteFunc:Function)
		{
			super("player", onCompleteFunc);
			
			_variables.player_id = player.playerId;
			_variables.name = player.name;
			_variables.level = player.level;
			_variables.xp = player.xp;
			_variables.coins = player.coins;
			_variables.farm_size = player.farmSize;
			_variables.objects = JSON.stringify(player.farmToObjects());
			_variables.stored_objects = JSON.stringify(player.storedObjects);
			_variables.gift_receivers = JSON.stringify(player.giftReceivers);
		}
	}
}