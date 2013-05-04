package server
{
	import com.adobe.serialization.json.JSON;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	public class Service
	{
		protected var _variables:URLVariables;
		
		private var _onCompleteFunc:Function;
		private var _loader:URLLoader;
		private var _isOk:Boolean;
		private var _error:String;
		private var _serverTime:int;
		
		public function Service(onCompleteFunc:Function)
		{
			_onCompleteFunc = onCompleteFunc;
			
			_variables = new URLVariables();
		}
		
		public function request():void
		{
			var request:URLRequest = new URLRequest(serviceUrl);
			request.method = URLRequestMethod.POST;
			request.data = _variables;
			
			_loader = new URLLoader();
			_loader.addEventListener(Event.COMPLETE, onComplete);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			
			_loader.load(request);
		}
		
		protected function get serviceUrl():String
		{
			return null;
		}
		
		protected function parseResult(result:Object):void
		{
			
		}
		
		private function onComplete(event:Event):void
		{
			removeListeners();
			
			var jsonData:String = _loader.data as String;
			var data:* = parseJSON(jsonData);
			_isOk = data.isOk as Boolean;
			_error = data.error as String;
			_serverTime = data.serverTime as int;
			parseResult(data.result);
			_onCompleteFunc(this);
		}

		private function onError(event:ErrorEvent):void
		{
			removeListeners();
			
			_isOk = false;
			_error = event.text;
			_onCompleteFunc(this);
		}
		
		private function removeListeners():void
		{
			_loader.removeEventListener(Event.COMPLETE, onComplete);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
		}

		public function get isOk():Boolean
		{
			return _isOk;
		}
		
		public function get error():String
		{
			return _error;
		}

		public function get serverTime():int
		{
			return _serverTime;
		}
		
		public static function parseJSON(s:String):*
		{
			return com.adobe.serialization.json.JSON.decode(s);
		}
		
		public static function stringifyJSON(o:Object):String
		{
			return com.adobe.serialization.json.JSON.encode(o);
		}

	}
}