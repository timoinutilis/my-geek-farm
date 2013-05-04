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
			_variables.objects = stringifyJSON(player.farmToObjects());
			_variables.stored_objects = stringifyJSON(player.storedObjects);
			_variables.gift_receivers = stringifyJSON(player.giftReceivers);
		}
	}
}