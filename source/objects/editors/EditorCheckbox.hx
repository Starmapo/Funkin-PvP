package objects.editors;

import flixel.addons.ui.FlxUICheckBox;
import flixel.util.FlxColor;

class EditorCheckbox extends FlxUICheckBox
{
	public function new(x:Float = 0, y:Float = 0, ?label:String, labelW:Int = 100, ?callback:Void->Void)
	{
		super(x, y, null, null, label, labelW, null, callback);
		button.label.setBorderStyle(OUTLINE, FlxColor.BLACK);
	}
}
