package ui.editors;

import flixel.FlxSprite;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUITypedButton;
import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxStringUtil;

class EditorNumericStepper extends FlxUIGroup implements IFlxUIClickable
{
	public var stepSize:Float;
	public var defaultValue:Float;
	public var min:Null<Float>;
	public var max:Null<Float>;
	public var decimals:Null<Int>;
	public var value(get, set):Float;
	public var valueChanged:FlxTypedSignal<Float->Float->Void> = new FlxTypedSignal();
	public var skipButtonUpdate(default, set):Bool;
	public var inputText:EditorInputText;

	var buttonPlus:FlxUITypedButton<FlxSprite>;
	var buttonMinus:FlxUITypedButton<FlxSprite>;
	var _value:Float = Math.NaN;

	public function new(x:Float = 0, y:Float = 0, stepSize:Float = 1, defaultValue:Float = 0, ?min:Float, ?max:Float, ?decimals:Int)
	{
		super(x, y);
		this.stepSize = stepSize;
		this.defaultValue = defaultValue;
		this.min = min;
		this.max = max;
		this.decimals = decimals;

		inputText = new EditorInputText(0, 0, 40);
		inputText.filterMode = ONLY_NUMERIC;
		inputText.textChanged.add(onTextChanged);
		add(inputText);

		var btnSize = Std.int(inputText.height);

		buttonPlus = new FlxUITypedButton<FlxSprite>(inputText.width, 0, onPlus);
		buttonPlus.loadGraphicSlice9([FlxUIAssets.IMG_BUTTON_THIN], btnSize, btnSize, [FlxStringUtil.toIntArray(FlxUIAssets.SLICE9_BUTTON_THIN)],
			FlxUI9SliceSprite.TILE_NONE, -1, false, FlxUIAssets.IMG_BUTTON_SIZE, FlxUIAssets.IMG_BUTTON_SIZE);
		buttonPlus.label = new FlxSprite(0, 0, FlxUIAssets.IMG_PLUS);
		buttonPlus.autoCenterLabel();
		add(buttonPlus);

		buttonMinus = new FlxUITypedButton<FlxSprite>(inputText.width + buttonPlus.width, 0, onMinus);
		buttonMinus.loadGraphicSlice9([FlxUIAssets.IMG_BUTTON_THIN], btnSize, btnSize, [FlxStringUtil.toIntArray(FlxUIAssets.SLICE9_BUTTON_THIN)],
			FlxUI9SliceSprite.TILE_NONE, -1, false, FlxUIAssets.IMG_BUTTON_SIZE, FlxUIAssets.IMG_BUTTON_SIZE);
		buttonMinus.label = new FlxSprite(0, 0, FlxUIAssets.IMG_MINUS);
		buttonMinus.autoCenterLabel();
		add(buttonMinus);

		value = defaultValue;
	}

	override function destroy()
	{
		FlxDestroyUtil.destroy(valueChanged);
		inputText = null;
		buttonPlus = null;
		buttonMinus = null;
		super.destroy();
	}

	public function setDisplayText(value:String)
	{
		_value = Math.NaN;
		return inputText.displayText = value;
	}

	public function resizeInput(width:Float)
	{
		if (width <= 0)
			width = 40;
		inputText.resize(width, inputText.height);
		buttonPlus.x = inputText.x + inputText.width;
		buttonMinus.x = buttonPlus.x + buttonPlus.width;
	}

	function onTextChanged(text, _)
	{
		var oldValue = _value;
		var parsedText = Std.parseFloat(text);
		if (text.length < 1 || !Math.isFinite(parsedText))
			value = defaultValue;
		else
			value = parsedText;
		if (_value != oldValue)
			valueChanged.dispatch(_value, oldValue);
	}

	function onPlus()
	{
		var oldValue = _value;
		value += stepSize;
		if (_value != oldValue)
			valueChanged.dispatch(_value, oldValue);
	}

	function onMinus()
	{
		var oldValue = _value;
		value -= stepSize;
		if (_value != oldValue)
			valueChanged.dispatch(_value, oldValue);
	}

	function get_value()
	{
		return _value;
	}

	function set_value(newValue:Float)
	{
		if (_value != newValue)
		{
			if (decimals != null && decimals >= 0)
				newValue = FlxMath.roundDecimal(newValue, decimals);
			newValue = FlxMath.bound(newValue, min, max);
			inputText.text = Std.string(newValue);
			_value = newValue;
		}
		return _value;
	}

	function set_skipButtonUpdate(b:Bool)
	{
		skipButtonUpdate = b;
		buttonPlus.skipButtonUpdate = b;
		buttonMinus.skipButtonUpdate = b;
		return b;
	}
}
