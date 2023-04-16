package ui.editors;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
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

	var textBorder:FlxSprite;
	var textBG:FlxSprite;
	var textField:EditorInputTextField;
	var hasFocus:Bool = false;
	var lastText:String;
	var _displayText:String;

	public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, size:Int = 8, embeddedFont:Bool = true, ?textFieldCamera:FlxCamera)
	{
		super(x, y);
		if (textFieldCamera == null)
			textFieldCamera = FlxG.camera;

		textField = new EditorInputTextField(1, 1, fieldWidth, text, size, embeddedFont, textFieldCamera);
		textField.color = FlxColor.BLACK;

		textBorder = new FlxSprite().makeGraphic(Std.int(textField.width) + 2, Std.int(textField.height) + 2, FlxColor.BLACK);

		textBG = new FlxSprite(1, 1).makeGraphic(Std.int(textField.width), Std.int(textField.height), FlxColor.WHITE);

		add(textBorder);
		add(textBG);
		add(textField);

		scrollFactor.set();

		textField.textField.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
		textField.textField.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
		lastText = text;
	}

	override function update(elapsed:Float) {}

	override function destroy()
	{
		textField.textField.removeEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
		FlxDestroyUtil.destroy(focusLost);
		FlxDestroyUtil.destroy(textChanged);
		super.destroy();
	}

	function onFocusIn(event:FocusEvent)
	{
		if (_displayText != null)
		{
			lastText = textField.text = '';
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
				~/[^0-9.]*/g;
			case ONLY_ALPHANUMERIC:
				~/[^a-zA-Z0-9.]*/g;
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
		return textField.text = filter(value);
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
		if (maxLength != value)
		{
			maxLength = value;
			if (maxLength > 0)
				text = text.substr(0, maxLength);
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
}

class EditorInputTextField extends FlxText
{
	public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, size:Int = 8, embeddedFont:Bool = true, textFieldCamera:FlxCamera)
	{
		super(x, y, fieldWidth, text, size, embeddedFont);
		scrollFactor.set();
		textField.selectable = true;
		textField.type = INPUT;
		textField.multiline = false;
		FlxG.game.addChildAt(textField, FlxG.game.getChildIndex(textFieldCamera.flashSprite) + 1);
		FlxG.signals.gameResized.add(onGameResized);
		text = textField.text;
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

	function updateTextField()
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
			textField.visible = value;
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
