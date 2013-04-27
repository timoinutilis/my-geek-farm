package game
{
	public class CommandInfo
	{
		public var name:String;
		public var params:String;
		public var help:String;
		public var cmdFunc:Function;
		
		public function CommandInfo(name:String, params:String, help:String, cmdFunc:Function)
		{
			this.name = name;
			this.params = params;
			this.help = help;
			this.cmdFunc = cmdFunc;
		}
	}
}