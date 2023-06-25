package ui.editors;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.events.FocusEvent;

class EditorInputText extends FlxSpriteGroup
{
	public var text(get, set):String;
	public var focusLost:FlxTypedSignal<String->Void> = new FlxTypedSignal();
	public var textChanged:FlxTypedSignal<String->String->Void> = new FlxTypedSignal();
	public var forceCase(default, set):LetterCase = ALL_CASES;
	public var filterMode(default, set):FilterMode = NO_FILTER;
	public var maxLength(default, set):Int = 0;
	public var displayText(get, set):String;
	public var multiline(get, set):Bool;
	public var size(get, set):Int;
	public var textField(default, null):EditorInputTextField;

	var textBorder:FlxSprite;
	var textBG:FlxSprite;
	var hasFocus:Bool = false;
	var lastText:String;
	var _displayText:String;
	var lastVolumeUpKeys:Array<FlxKey>;
	var lastVolumeDownKeys:Array<FlxKey>;
	var lastMuteKeys:Array<FlxKey>;
	var lastDebugToggleKeys:Array<FlxKey>;

	#if FLX_RECORD
	var lastVCRCancelKeys:Array<FlxKey>;
	#end

	public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, size:Int = 8, embeddedFont:Bool = true, ?textFieldCamera:FlxCamera)
	{
		super(x, y);
		if (fieldWidth <= 0)
			fieldWidth = 150;
		if (text == null)
			text = '';
		if (textFieldCamera == null)
			textFieldCamera = FlxG.camera;
		lastText = text;

		textField = new EditorInputTextField(1, 1, fieldWidth, text, size, embeddedFont, textFieldCamera);
		textField.color = FlxColor.BLACK;

		textBorder = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);

		textBG = new FlxSprite(1, 1).makeGraphic(1, 1, FlxColor.WHITE);

		updateBGSize();

		add(textBorder);
		add(textBG);
		add(textField);

		scrollFactor.set();

		textField.textField.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
		textField.textField.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
	}

	override function update(elapsed:Float) {}

	override function destroy()
	{
		FlxDestroyUtil.destroy(focusLost);
		FlxDestroyUtil.destroy(textChanged);
		textBorder = null;
		textBG = null;
		textField.textField.removeEventListener(FocusEvent.FOCUS_IN, onFocusIn);
		textField.textField.removeEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
		textField = null;
		lastVolumeUpKeys = null;
		lastVolumeDownKeys = null;
		lastMuteKeys = null;
		lastDebugToggleKeys = null;
		super.destroy();
	}

	public function updateBGSize()
	{
		textBorder.setGraphicSize(textField.width + 2, textField.height + 2);
		textBorder.updateHitbox();
		textBG.setGraphicSize(textField.width, textField.height);
		textBG.updateHitbox();
	}

	public function resize(width:Float, height:Float)
	{
		if (width <= 0)
			width = textField.width;
		if (height <= 0)
			height = textField.height;

		textField.width = textField.textField.width = width;
		textField.height = textField.textField.height = height;
		updateBGSize();
	}

	function onFocusIn(event:FocusEvent)
	{
		lastVolumeUpKeys = FlxG.sound.volumeUpKeys;
		lastVolumeDownKeys = FlxG.sound.volumeDownKeys;
		lastMuteKeys = FlxG.sound.muteKeys;
		lastDebugToggleKeys = FlxG.debugger.toggleKeys;
		#if FLX_RECORD
		lastVCRCancelKeys = FlxG.vcr.cancelKeys;
		#end

		FlxG.sound.volumeUpKeys = null;
		FlxG.sound.volumeDownKeys = null;
		FlxG.sound.muteKeys = null;
		FlxG.debugger.toggleKeys = null;
		#if FLX_RECORD
		FlxG.vcr.cancelKeys = null;
		#end

		if (_displayText != null)
		{
			text = '';
			_displayText = null;
		}
	}

	function onFocusOut(event:FocusEvent)
	{
		textField.text = filter(text);
		focusLost.dispatch(text);

		if (lastText != text)
		{
			textChanged.dispatch(text, lastText);
			lastText = text;
		}

		FlxG.sound.volumeUpKeys = lastVolumeUpKeys;
		FlxG.sound.volumeDownKeys = lastVolumeDownKeys;
		FlxG.sound.muteKeys = lastMuteKeys;
		FlxG.debugger.toggleKeys = lastDebugToggleKeys;
		#if FLX_RECORD
		FlxG.vcr.cancelKeys = lastVCRCancelKeys;
		#end
	}

	function filter(text:String)
	{
		if (forceCase == UPPER_CASE)
			text = text.toUpperCase();
		else if (forceCase == LOWER_CASE)
			text = text.toLowerCase();

		var pattern:EReg = switch (filterMode)
		{
			case ONLY_ALPHA:
				~/[^a-zA-Z]*/g;
			case ONLY_NUMERIC:
				~/[^0-9eE.\-+]*/g;
			case ONLY_ALPHANUMERIC:
				~/[^a-zA-Z0-9.\-+]*/g;
			case CUSTOM_FILTER(p):
				p;
			default:
				null;
		};
		if (pattern != null)
			text = pattern.replace(text, "");

		if (maxLength > 0)
			text = text.substr(0, maxLength);

		return text;
	}

	function get_text()
	{
		return textField.textField.text;
	}

	function set_text(value:String)
	{
		return lastText = textField.text = filter(value);
	}

	function set_forceCase(value:LetterCase)
	{
		if (forceCase != value)
		{
			forceCase = value;
			text = text;
		}
		return value;
	}

	function set_filterMode(value:FilterMode)
	{
		if (filterMode != value)
		{
			filterMode = value;
			text = text;
		}
		return value;
	}

	function set_maxLength(value:Int)
	{
		if (maxLength != value && value >= 0)
		{
			maxLength = value;
			if (maxLength > 0)
				text = text.substr(0, maxLength);
			textField.textField.maxChars = value;
		}
		return value;
	}

	function get_displayText()
	{
		return _displayText;
	}

	function set_displayText(value:String)
	{
		_displayText = value;
		textField.text = _displayText;
		return value;
	}

	function get_multiline()
	{
		return textField.textField.multiline;
	}

	function set_multiline(value:Bool)
	{
		textField.textField.multiline = value;
		textField.textField.wordWrap = value;
		return value;
	}

	function get_size()
	{
		return textField.size;
	}

	function set_size(value:Int)
	{
		textField.size = value;
		updateBGSize();
		return textField.size;
	}

	override function set_color(value:FlxColor)
	{
		textBorder.color = value;
		textBG.color = value;
		return color = value;
	}
}

class EditorInputTextField extends FlxText
{
	var textFieldCamera:FlxCamera;

	public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, size:Int = 8, embeddedFont:Bool = true, textFieldCamera:FlxCamera)
	{
		super(x, y, fieldWidth, text, size, embeddedFont);
		this.textFieldCamera = textFieldCamera;

		scrollFactor.set();
		textField.text = text;
		textField.selectable = true;
		textField.type = INPUT;
		textField.multiline = false;
		textField.wordWrap = false;
		textField.tabEnabled = false;
		FlxG.game.addChildAt(textField, FlxG.game.getChildIndex(textFieldCamera.flashSprite) + 1);
		FlxG.signals.gameResized.add(onGameResized);
		this.text = textField.text;
	}

	override function update(elapsed:Float)
	{
		text = textField.text;
	}

	override function draw()
	{
		updateTextField();
	}

	override function destroy()
	{
		FlxG.game.removeChild(textField);
		FlxG.signals.gameResized.remove(onGameResized);
		super.destroy();
	}

	public function updateTextField()
	{
		if (textField == null)
			return;

		textField.x = (x - offset.x) * camera.totalScaleX;
		textField.y = (y - offset.y) * camera.totalScaleY;

		textField.scaleX = camera.totalScaleX * scale.x;
		textField.scaleY = camera.totalScaleY * scale.y;

		#if !web
		textField.x -= 1;
		textField.y -= 1;
		#end

		textField.visible = visible && textFieldCamera.visible;
	}

	function onGameResized(_, _)
	{
		updateTextField();
	}

	override function set_active(value:Bool)
	{
		if (textField != null)
			textField.type = value ? INPUT : DYNAMIC;
		return super.set_active(value);
	}

	override function set_visible(value:Bool)
	{
		if (textField != null)
			textField.visible = value && textFieldCamera.visible;
		return super.set_visible(value);
	}

	override function set_alpha(value:Float)
	{
		value = FlxMath.bound(value, 0, 1);
		if (textField != null)
			textField.alpha = value;
		return super.set_alpha(value);
	}

	override function set_text(value:String)
	{
		text = value;
		if (textField != null)
			textField.text = text;
		return value;
	}
}

enum LetterCase
{
	ALL_CASES;
	UPPER_CASE;
	LOWER_CASE;
}

enum FilterMode
{
	NO_FILTER;
	ONLY_ALPHA;
	ONLY_NUMERIC;
	ONLY_ALPHANUMERIC;
	CUSTOM_FILTER(pattern:EReg);
}
