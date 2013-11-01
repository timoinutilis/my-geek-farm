package server
{
	public class SendService extends Service
	{
		public function SendService(type:String, onCompleteFunc:Function)
		{
			super(onCompleteFunc);
			
			_variables.type = type;
		}

		override protected function get serviceUrl():String
		{
			return "http://apps.timokloss.com/mygeekfarm/backend/send.php";
		}
		
	}
}