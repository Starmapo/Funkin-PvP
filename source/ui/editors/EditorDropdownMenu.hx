package ui.editors;

import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.StrNameLabel;

class EditorDropdownMenu extends FlxUIDropDownMenu
{
	public function new(x:Float = 0, y:Float = 0, ?dataList:Array<StrNameLabel>, ?callback:String->Void)
	{
		super(x, y, dataList, callback);
	}

	public static function makeStrIdLabelArray(StringArray:Array<String>, UseIndexID:Bool = false):Array<StrNameLabel>
	{
		var strIdArray:Array<StrNameLabel> = [];
		for (i in 0...StringArray.length)
		{
			var ID:String = StringArray[i];
			if (UseIndexID)
			{
				ID = Std.string(i);
			}
			strIdArray[i] = new StrNameLabel(ID, StringArray[i]);
		}
		return strIdArray;
	}
}
