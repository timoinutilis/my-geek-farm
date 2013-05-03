package game
{
	public class CommandInfo
	{
		public var name:String;
		public var params:String;
		public var help:String;
		public var cmdFunc:Function;
		public var allowedInScript:Boolean;
		
		public function CommandInfo(name:String, params:String, help:String, cmdFunc:Function, allowedInScript:Boolean)
		{
			this.name = name;
			this.params = params;
			this.help = help;
			this.cmdFunc = cmdFunc;
			this.allowedInScript = allowedInScript;
		}
	}
}