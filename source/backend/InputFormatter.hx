package backend;

import backend.settings.PlayerConfig;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class InputFormatter
{
	public static function format(id:Int, device:PlayerConfigDevice):String
	{
		return switch (device)
		{
			case KEYBOARD: getKeyName(id);
			case GAMEPAD(_): getButtonName(id);
			case NONE: '[?]';
		}
	}
	
	public static function getKeyName(id:FlxKey):String
	{
		return switch (id)
		{
			case ZERO: "0";
			case ONE: "1";
			case TWO: "2";
			case THREE: "3";
			case FOUR: "4";
			case FIVE: "5";
			case SIX: "6";
			case SEVEN: "7";
			case EIGHT: "8";
			case NINE: "9";
			case PAGEUP: "PgUp";
			case PAGEDOWN: "PgDown";
			case BACKSPACE: "BckSpc";
			case LBRACKET: "[";
			case RBRACKET: "]";
			case BACKSLASH: "\\";
			case CAPSLOCK: "Caps";
			case SEMICOLON: ";";
			case SCROLL_LOCK: "ScrlLock";
			case NUMLOCK: "NumLock";
			case QUOTE: "'";
			case COMMA: ",";
			case PERIOD: ".";
			case SLASH: "/";
			case GRAVEACCENT: "`";
			case CONTROL: "Ctrl";
			case ALT: "Alt";
			case PRINTSCREEN: "PrtScrn";
			case NUMPADZERO: "#0";
			case NUMPADONE: "#1";
			case NUMPADTWO: "#2";
			case NUMPADTHREE: "#3";
			case NUMPADFOUR: "#4";
			case NUMPADFIVE: "#5";
			case NUMPADSIX: "#6";
			case NUMPADSEVEN: "#7";
			case NUMPADEIGHT: "#8";
			case NUMPADNINE: "#9";
			case NUMPADMINUS: "#-";
			case NUMPADPLUS: "#+";
			case NUMPADPERIOD: "#.";
			case NUMPADMULTIPLY: "#*";
			case NUMPADSLASH: "#/";
			default: titleCase(FlxKey.toStringMap[id]);
		}
	}
	
	inline static public function getButtonName(id:FlxGamepadInputID):String
	{
		return switch (id)
		{
			case NONE: "[?]";
			default: "Button " + (id : Int);
		}
	}
	
	static function titleCase(str:String)
	{
		if (str == null || str.length < 1)
			return '[?]';
		if (str.length < 2)
			return str.toUpperCase();
			
		return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase();
	}
}
