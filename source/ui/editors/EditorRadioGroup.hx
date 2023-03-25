package ui.editors;

import flixel.addons.ui.FlxUIRadioGroup;
import flixel.util.FlxColor;

class EditorRadioGroup extends FlxUIRadioGroup
{
	public function new(x:Float = 0, y:Float = 0, ?ids:Array<String>, ?labels:Array<String>, ?callback:String->Void = null, ySpace:Float = 25,
			width:Int = 100, height:Int = 20, labelWidth:Int = 100)
	{
		super(x, y, ids, labels, callback, ySpace, width, height, labelWidth);
		_refreshRadios();
		for (radio in _list_radios)
		{
			radio.button.label.setBorderStyle(OUTLINE, FlxColor.BLACK);
		}
	}
}
