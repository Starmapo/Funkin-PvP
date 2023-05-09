package data.scripts;

import flixel.util.FlxColor;

class FlxColorHelper
{
	public static inline var TRANSPARENT = FlxColor.TRANSPARENT;
	public static inline var WHITE = FlxColor.WHITE;
	public static inline var GRAY = FlxColor.GRAY;
	public static inline var BLACK = FlxColor.BLACK;

	public static inline var GREEN = FlxColor.GREEN;
	public static inline var LIME = FlxColor.LIME;
	public static inline var YELLOW = FlxColor.YELLOW;
	public static inline var ORANGE = FlxColor.ORANGE;
	public static inline var RED = FlxColor.RED;
	public static inline var PURPLE = FlxColor.PURPLE;
	public static inline var BLUE = FlxColor.BLUE;
	public static inline var BROWN = FlxColor.BROWN;
	public static inline var PINK = FlxColor.PINK;
	public static inline var MAGENTA = FlxColor.MAGENTA;
	public static inline var CYAN = FlxColor.CYAN;

	public static var colorLookup(default, null) = FlxColor.colorLookup;

	public var red(get, set):Int;
	public var blue(get, set):Int;
	public var green(get, set):Int;
	public var alpha(get, set):Int;

	public var redFloat(get, set):Float;
	public var blueFloat(get, set):Float;
	public var greenFloat(get, set):Float;
	public var alphaFloat(get, set):Float;

	public var cyan(get, set):Float;
	public var magenta(get, set):Float;
	public var yellow(get, set):Float;
	public var black(get, set):Float;

	public var rgb(get, set):FlxColor;
	public var hue(get, set):Float;
	public var saturation(get, set):Float;
	public var brightness(get, set):Float;
	public var lightness(get, set):Float;

	public var color(default, null):FlxColor;

	public static inline function fromInt(Value:Int):FlxColor
	{
		return FlxColor.fromInt(Value);
	}

	public static inline function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
	{
		return FlxColor.fromRGB(Red, Green, Blue, Alpha);
	}

	public static inline function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
	{
		return FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);
	}

	public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
	{
		return FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}

	public static inline function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):FlxColor
	{
		return FlxColor.fromHSB(Hue, Saturation, Brightness, Alpha);
	}

	public static inline function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):FlxColor
	{
		return FlxColor.fromHSL(Hue, Saturation, Lightness, Alpha);
	}

	public static inline function fromString(str:String):Null<FlxColor>
	{
		return FlxColor.fromString(str);
	}

	public static inline function getHSBColorWheel(Alpha:Int = 255):Array<FlxColor>
	{
		return FlxColor.getHSBColorWheel(Alpha);
	}

	public static inline function interpolate(Color1:FlxColor, Color2:FlxColor, Factor:Float = 0.5):FlxColor
	{
		return FlxColor.interpolate(Color1, Color2, Factor);
	}

	public static inline function gradient(Color1:FlxColor, Color2:FlxColor, Steps:Int, ?Ease:Float->Float):Array<FlxColor>
	{
		return FlxColor.gradient(Color1, Color2, Steps, Ease);
	}

	public static inline function multiply(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.multiply(lhs, rhs);
	}

	public static inline function add(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.add(lhs, rhs);
	}

	public static inline function subtract(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.subtract(lhs, rhs);
	}

	public function new(value:Int = 0)
	{
		color = new FlxColor(value);
	}

	public inline function getComplementHarmony():FlxColor
	{
		return color.getComplementHarmony();
	}

	public inline function getAnalogousHarmony(Threshold:Int = 30):Harmony
	{
		return color.getAnalogousHarmony(Threshold);
	}

	public inline function getSplitComplementHarmony(Threshold:Int = 30):Harmony
	{
		return color.getSplitComplementHarmony(Threshold);
	}

	public inline function getTriadicHarmony():TriadicHarmony
	{
		return color.getTriadicHarmony();
	}

	public inline function to24Bit():FlxColor
	{
		return color.to24Bit();
	}

	public inline function toHexString(Alpha:Bool = true, Prefix:Bool = true):String
	{
		return color.toHexString(Alpha, Prefix);
	}

	public inline function toWebString():String
	{
		return color.toWebString();
	}

	public inline function getColorInfo():String
	{
		return color.getColorInfo();
	}

	public inline function getDarkened(Factor:Float = 0.2):FlxColor
	{
		return color.getDarkened(Factor);
	}

	public inline function getLightened(Factor:Float = 0.2):FlxColor
	{
		return color.getLightened(Factor);
	}

	public inline function getInverted():FlxColor
	{
		return color.getInverted();
	}

	public inline function setRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
	{
		return color.setRGB(Red, Green, Blue, Alpha);
	}

	public inline function setRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
	{
		return color.setRGBFloat(Red, Green, Blue, Alpha);
	}

	public inline function setCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
	{
		return color.setCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}

	public inline function setHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float):FlxColor
	{
		return color.setHSB(Hue, Saturation, Brightness, Alpha);
	}

	public inline function setHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float):FlxColor
	{
		return color.setHSL(Hue, Saturation, Lightness, Alpha);
	}

	function get_red()
	{
		return color.red;
	}

	function set_red(value:Int)
	{
		return color.red = value;
	}

	function get_blue()
	{
		return color.blue;
	}

	function set_blue(value:Int)
	{
		return color.blue = value;
	}

	function get_green()
	{
		return color.green;
	}

	function set_green(value:Int)
	{
		return color.green = value;
	}

	function get_alpha()
	{
		return color.alpha;
	}

	function set_alpha(value:Int)
	{
		return color.alpha = value;
	}

	function get_redFloat()
	{
		return color.redFloat;
	}

	function set_redFloat(value:Float)
	{
		return color.redFloat = value;
	}

	function get_blueFloat()
	{
		return color.blueFloat;
	}

	function set_blueFloat(value:Float)
	{
		return color.blueFloat = value;
	}

	function get_greenFloat()
	{
		return color.greenFloat;
	}

	function set_greenFloat(value:Float)
	{
		return color.greenFloat = value;
	}

	function get_alphaFloat()
	{
		return color.alphaFloat;
	}

	function set_alphaFloat(value:Float)
	{
		return color.alphaFloat = value;
	}

	function get_cyan()
	{
		return color.cyan;
	}

	function set_cyan(value:Float)
	{
		return color.cyan = value;
	}

	function get_magenta()
	{
		return color.magenta;
	}

	function set_magenta(value:Float)
	{
		return color.magenta = value;
	}

	function get_yellow()
	{
		return color.yellow;
	}

	function set_yellow(value:Float)
	{
		return color.yellow = value;
	}

	function get_black()
	{
		return color.black;
	}

	function set_black(value:Float)
	{
		return color.black = value;
	}

	function get_rgb()
	{
		return color.rgb;
	}

	function set_rgb(value:FlxColor)
	{
		return color.rgb = value;
	}

	function get_hue()
	{
		return color.hue;
	}

	function set_hue(value:Float)
	{
		return color.hue = value;
	}

	function get_saturation()
	{
		return color.saturation;
	}

	function set_saturation(value:Float)
	{
		return color.saturation = value;
	}

	function get_brightness()
	{
		return color.brightness;
	}

	function set_brightness(value:Float)
	{
		return color.brightness = value;
	}

	function get_lightness()
	{
		return color.lightness;
	}

	function set_lightness(value:Float)
	{
		return color.lightness = value;
	}
}
