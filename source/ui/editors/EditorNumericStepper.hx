package ui.editors;

import flixel.FlxSprite;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUITypedButton;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxStringUtil;

class EditorNumericStepper extends FlxSpriteGroup
{
	public var stepSize:Float;
	public var defaultValue:Float;
	public var min:Float;
	public var max:Float;
	public var decimals:Int;
	public var value(get, set):Float;
	public var valueChanged:FlxTypedSignal<Float->Float->Void> = new FlxTypedSignal();

	var inputText:EditorInputText;
	var buttonPlus:FlxUITypedButton<FlxSprite>;
	var buttonMinus:FlxUITypedButton<FlxSprite>;

	public function new(x:Float = 0, y:Float = 0, stepSize:Float = 0, defaultValue:Float = 0, min:Float = -999, max:Float = 999, decimals:Int = 0)
	{
		super(x, y);
		this.stepSize = stepSize;
		this.defaultValue = defaultValue;
		this.min = min;
		this.max = max;
		this.decimals = decimals;

		inputText = new EditorInputText(0, 0, 40);
		inputText.focusLost.add(onFocusLost);
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
		super.destroy();
	}

	function onFocusLost(text)
	{
		if (text.length < 1)
		{
			inputText.text = Std.string(defaultValue);
		}
		value = value;
	}

	function onPlus()
	{
		value += stepSize;
	}

	function onMinus()
	{
		value -= stepSize;
	}

	function get_value()
	{
		return Std.parseFloat(inputText.text);
	}

	function set_value(newValue:Float)
	{
		var oldValue = value;
		newValue = FlxMath.bound(FlxMath.roundDecimal(newValue, decimals), min, max);
		inputText.text = Std.string(newValue);
		if (newValue != oldValue)
		{
			valueChanged.dispatch(newValue, oldValue);
		}
		return newValue;
	}
}
