package server
{
	public class RequestService extends Service
	{
		public function RequestService(type:String, onCompleteFunc:Function)
		{
			super(onCompleteFunc);
			
			_variables.type = type;
		}
		
		override protected function get serviceUrl():String
		{
			return "http://apps.timokloss.com/mygeekfarm/backend/request.php";
		}

	}
}