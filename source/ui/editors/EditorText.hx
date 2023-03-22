package ui.editors;

import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;

class EditorText extends FlxUIText
{
	public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, size:Int = 8, embeddedFont:Bool = true)
	{
		super(x, y, fieldWidth, text, size, embeddedFont);
		setBorderStyle(OUTLINE, FlxColor.BLACK);
	}
}
