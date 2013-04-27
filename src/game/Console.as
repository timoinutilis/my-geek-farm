package game
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.Font;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	
	public class Console extends Sprite
	{
		[Embed(source="topaz8.png")]
		private var FontImage:Class;

		[Embed(source="screen_filter.png")]
		private var ScreenFilter:Class;

		[Embed(source="beam.png")]
		private var Beam:Class;

		public static const CHAR_WIDTH:int = 8;
		public static const CHAR_HEIGHT:int = 8;
		
		public static const COLOR_BG:uint = 0x00241E;
		public static const CURSOR_COLOR:uint = 0x23FAD8;
		
		private var _onInputCallback:Function;
		private var _column:int;
		private var _row:int;
		private var _numColumns:int;
		private var _numRows:int;
		private var _queuedLines:Vector.<String>;
		private var _pageLines:int;
		private var _input:String;
		private var _active:Boolean;
		private var _clickVisible:Boolean;
		private var _inputHistory:Vector.<String>;
		private var _inputHistoryIndex:int;
		private var _autoCompleteCallback:Function;
		
		private var _screenContainer:Sprite;
		private var _font:BitmapData;
		private var _bitmap:Bitmap;
		private var _beam:Bitmap;
		private var _sourceRect:Rectangle;
		private var _destPoint:Point;
		private var _cursorRect:Rectangle;
		private var _cursorCounter:int;
		
		private var _fxBitmap:Bitmap;
		private var _distortionRate:Number = 0.005;
		
		public function Console()
		{
			super();
			
			// font
			var font:Bitmap = new FontImage() as Bitmap;
			_font = font.bitmapData;
			
			var bg:Shape = new Shape();
			bg.graphics.beginFill(0x000000);
			bg.graphics.drawRect(0, 0, 640, 480);
			addChild(bg);
			
			_screenContainer = new Sprite();
			addChild(_screenContainer);
			
			// screen text
			var bmd:BitmapData = new BitmapData(640, 240, false, 0x000000);
			_bitmap = new Bitmap(bmd);
			_bitmap.scaleY = 2;
			_bitmap.smoothing = true;
			_screenContainer.addChild(_bitmap);

			_numColumns = bmd.width / CHAR_WIDTH;
			_numRows = bmd.height / CHAR_HEIGHT;
			
			// beam
			_beam = new Beam() as Bitmap;
			_beam.blendMode = BlendMode.ADD;
			_beam.scaleY = 0.5;
			_beam.alpha = 0.25;
			_beam.y = -_beam.height;
			_screenContainer.addChild(_beam);

			// scanlines
			bmd = new BitmapData(640, 480, true, 0x000000);
			var rect:Rectangle = new Rectangle(0, 0, 640, 1);
			for (var i:int = 0; i < 480; i += 2)
			{
				rect.y = i;
				bmd.fillRect(rect, 0x88000000);
			}
			_fxBitmap = new Bitmap(bmd);
			_fxBitmap.smoothing = true;
			_screenContainer.addChild(_fxBitmap);
			
			// screen reflections
			var screenFilter:Bitmap = new ScreenFilter() as Bitmap;
			screenFilter.blendMode = BlendMode.ADD;
			addChild(screenFilter);
			
			// other stuff
			_sourceRect = new Rectangle(0, 0, CHAR_WIDTH, CHAR_HEIGHT);
			_destPoint = new Point();
			_cursorRect = new Rectangle(0, 0, CHAR_WIDTH, CHAR_HEIGHT);
			
			_queuedLines = new Vector.<String>();
			_inputHistory = new Vector.<String>();
			
			addEventListener(Event.ACTIVATE, onActivate);
			addEventListener(Event.DEACTIVATE, onDeactivate);
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			clear();
			
			setTimeout(start, 500);
		}
		
		private function start():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function clear():void
		{
			_column = 0;
			_row = 0;
			var bmd:BitmapData = _bitmap.bitmapData;
			bmd.fillRect(new Rectangle(0, 0, bmd.width, bmd.height), COLOR_BG);
			renderCursor(true);
		}

		public function print(text:String):void
		{
			_queuedLines.push(text);
		}
		
		public function println(text:String):void
		{
			if (_queuedLines.length == 0)
			{
				_pageLines = 0;
			}
			_queuedLines.push(text);
			_queuedLines.push(null);
		}
		
		public function printWrapped(text:String):void
		{
			var lines:Array = [];
			var line:String;
			while (text.length > 80)
			{
				var endIndex:int = text.lastIndexOf(" ", 79);
				line = text.substr(0, endIndex);
				lines.push(line);
				text = text.substr(line.length + 1);
			}
			lines.push(text);
			
			for each (line in lines)
			{
				println(line);
			}
		}
		
		public function printTableLn(cells:Array, positions:Array):void
		{
			var line:String = "";
			for (var i:int = 0; i < cells.length; i++)
			{
				while (line.length < positions[i])
				{
					line += " ";
				}
				line += cells[i];
			}
			println(line);
		}
		
		public function input():void
		{
			_input = "";
			_inputHistoryIndex = -1;
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			checkActive();
		}
		
		private function onEnterFrame(e:Event):void
		{
			// text output
			if (_pageLines + 1 < _numRows)
			{
				var line:String = _queuedLines.shift();
				if (line != null)
				{
					renderChars(line);
					if (_queuedLines.length > 0 && _queuedLines[0] == null)
					{
						_queuedLines.shift();
						renderCursor(false);
						nextLine();
						renderCursor(true);
						
						_pageLines++;
						if (_pageLines + 1 >= _numRows)
						{
							renderChars("(press key to continue!)");
						}
					}
					checkActive();
				}
			}
			
			// beam FX
			_beam.y += 4;
			if (_beam.y >= _bitmap.height)
			{
				_beam.y = -_beam.height;
			}
			
			// distortions, yeah!
			if (Math.random() < _distortionRate)
			{
				var rand:Number = 0.5 + Math.random() * 0.5;
				_screenContainer.scaleY = rand;
				_screenContainer.y = (480 - 480 * rand) * 0.5 + (Math.random() * 160 - 80);
				_distortionRate = Math.max(0.001, _distortionRate - 0.002);
			}
			else
			{
				_screenContainer.scaleX = (1 + _screenContainer.scaleX) * 0.5;
				_screenContainer.scaleY = (1 + _screenContainer.scaleY) * 0.5;
				_screenContainer.x = _screenContainer.x * 0.5 + (Math.random() * 0.2);
				_screenContainer.y = _screenContainer.y * 0.5;
			}
			if (Math.random() < 0.003)
			{
				_screenContainer.alpha = 0.5 + Math.random() * 0.5;
			}
			else
			{
				_screenContainer.alpha = 1;
			}
		}
		
		private function isRendering():Boolean
		{
			return _queuedLines.length > 0;
		}

		private function renderChars(text:String):void
		{
			renderCursor(false);
			for (var i:int = 0; i < text.length; i++)
			{
				var ascii:int = text.charCodeAt(i);
				renderChar(ascii);
				nextColumn();
			}
			renderCursor(true);
		}
		
		private function clearChars(num:int):void
		{
			renderCursor(false);
			for (var i:int = 0; i < num; i++)
			{
				prevColumn();
				renderChar(32);
			}
			renderCursor(true);
		}
		
		public function set onInputCallback(value:Function):void
		{
			_onInputCallback = value;
		}
		
		private function renderChar(ascii:int):void
		{
			_sourceRect.x = (ascii - 32) * CHAR_WIDTH;
			_destPoint.x = _column * CHAR_WIDTH;
			_destPoint.y = _row * CHAR_HEIGHT;
			_bitmap.bitmapData.copyPixels(_font, _sourceRect, _destPoint);
		}
		
		private function renderLine(ascii:int):void
		{
			renderCursor(false);
			while (_column < _numColumns)
			{
				renderChar(ascii);
				_column++;
			}
			_column = 0;
			renderCursor(true);
		}
		
		private function nextColumn():void
		{
			_column++;
			if (_column >= _numColumns)
			{
				nextLine();
			}
		}

		private function prevColumn():void
		{
			_column--;
			if (_column < 0)
			{
				_column = _numColumns - 1;
				_row--;
			}
		}

		private function nextLine():void
		{
			_column = 0;
			if (_row + 1 < _numRows)
			{
				_row++;
			}
			else
			{
				_bitmap.bitmapData.scroll(0, -CHAR_HEIGHT);
				renderLine(32);
			}
		}
		
		private function renderCursor(visible:Boolean = true):void
		{
			_cursorRect.x = _column * CHAR_WIDTH;
			_cursorRect.y = _row * CHAR_HEIGHT;
			_bitmap.bitmapData.fillRect(_cursorRect, visible ? CURSOR_COLOR : COLOR_BG);
		}
		
		private function onKeyDown(e:KeyboardEvent):void
		{
			var ascii:uint = e.charCode;
			var keyCode:uint = e.keyCode;
			
			if (_pageLines + 1 >= _numRows)
			{
				_pageLines = 0;
				clearChars(24);
			}

			if (_queuedLines.length > 0)
			{
				return;
			}
			
			if (!_active)
			{
				_active = true;
				checkActive();
			}
			
			if (ascii >= 32 && ascii < 127)
			{
				renderCursor(false);
				renderChar(ascii);
				_input += String.fromCharCode(ascii);
				nextColumn();
				renderCursor(true);
			}
			else if (keyCode == Keyboard.ENTER)
			{
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				renderCursor(false);
				nextLine();
				renderCursor(true);
				if (_inputHistory.length == 0 || _inputHistory[0] != _input)
				{
					_inputHistory.unshift(_input);
				}
				var thisInput:String = _input;
				_input = null;
				if (_onInputCallback != null)
				{
					_onInputCallback(thisInput);
				}
			}
			else if (keyCode == Keyboard.BACKSPACE && _input.length > 0)
			{
				_input = _input.substr(0, _input.length - 1);
				clearChars(1);
			}
			else if (keyCode == Keyboard.UP && _inputHistoryIndex + 1 < _inputHistory.length)
			{
				_inputHistoryIndex++;
				clearChars(_input.length);
				_input = _inputHistory[_inputHistoryIndex];
				renderChars(_input);
			}
			else if (keyCode == Keyboard.DOWN && _inputHistoryIndex >= 0)
			{
				_inputHistoryIndex--;
				clearChars(_input.length);
				if (_inputHistoryIndex >= 0)
				{
					_input = _inputHistory[_inputHistoryIndex];
					renderChars(_input);
				}
				else
				{
					_input = "";
				}
			}
			else if (keyCode == Keyboard.TAB && _autoCompleteCallback != null && _input.length > 0)
			{
				var result:String = _autoCompleteCallback(_input);
				if (result != null)
				{
					clearChars(_input.length);
					_input = result;
					renderChars(_input);
				}
			}
		}
		
		public function set autoCompleteCallback(callback:Function):void
		{
			_autoCompleteCallback = callback;
		}
		
		private function onActivate(e:Event):void
		{
			_active = true;
			checkActive();
		}
		
		private function onDeactivate(e:Event):void
		{
			_active = false;
			checkActive();
		}
		
		private function checkActive():void
		{
			if (!isRendering() && _input != null)
			{
				if (!_active && !_clickVisible)
				{
					renderChars(" (CLICK TO ACTIVATE!)");
					_clickVisible = true;
				}
				else if (_active && _clickVisible)
				{
					clearChars(21);
					_clickVisible = false;
				}
			}
		}
		
		private function onAdded(e:Event):void
		{
			_screenContainer.scaleX = 0.1;
			_screenContainer.scaleY = 0;
			_screenContainer.x = (640 - 640 * _screenContainer.scaleX) * 0.5; 
			_screenContainer.y = (480 - 480 * _screenContainer.scaleY) * 0.5; 
		}
		
		public function createScreenshot():BitmapData
		{
			_screenContainer.scaleX = 1;
			_screenContainer.scaleY = 1;
			_screenContainer.x = 0;
			_screenContainer.y = 0;
			var screenshot:BitmapData = new BitmapData(_bitmap.width, _bitmap.height);
			screenshot.draw(this);
			return screenshot;
		}
		
	}
}