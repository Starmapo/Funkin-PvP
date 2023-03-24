package ui.editors;

import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.StrNameLabel;

class EditorDropdownMenu extends FlxUIDropDownMenu
{
	public function new(x:Float = 0, y:Float = 0, ?dataList:Array<StrNameLabel>, ?callback:String->Void)
	{
		super(x, y, dataList, callback);
	}

	public static function makeStrIdLabelArray(stringArray:Array<String>, useIndexID:Bool = false):Array<StrNameLabel>
	{
		return FlxUIDropDownMenu.makeStrIdLabelArray(stringArray, useIndexID);
	}
}
