package objects.editors;

import flixel.FlxSprite;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.StrNameLabel;
import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IFlxUIWidget;

class EditorDropdownMenu extends FlxUIDropDownMenu implements IFlxUIClickable implements IFlxUIWidget
{
	public static function makeStrIdLabelArray(stringArray:Array<String>, useIndexID:Bool = false):Array<StrNameLabel>
	{
		return FlxUIDropDownMenu.makeStrIdLabelArray(stringArray, useIndexID);
	}
	
	var tabMenu:FlxUITabMenu;
	
	public function new(x:Float = 0, y:Float = 0, ?dataList:Array<StrNameLabel>, ?callback:String->Void, ?tabMenu:FlxUITabMenu, width:Int = 120)
	{
		super(x, y, dataList, callback, new FlxUIDropDownHeader(width));
		this.tabMenu = tabMenu;
	}
	
	override function destroy()
	{
		super.destroy();
		tabMenu = null;
	}
	
	override function showList(b:Bool)
	{
		super.showList(b);
		if (tabMenu != null)
		{
			for (asset in tabMenu)
			{
				setWidgetSuppression(asset, b);
			}
			skipButtonUpdate = false;
		}
	}
	
	function setWidgetSuppression(asset:FlxSprite, suppressed:Bool = true):Void
	{
		if ((asset is IFlxUIClickable))
		{
			var skip:Bool = false;
			if ((asset is FlxUIDropDownMenu))
			{
				var ddasset:FlxUIDropDownMenu = cast asset;
				if (ddasset == this)
					skip = true;
			}
			if (!skip)
			{
				var ibtn:IFlxUIClickable = cast asset;
				ibtn.skipButtonUpdate = suppressed; // skip button updates until further notice
			}
		}
		else if ((asset is FlxUIGroup))
		{
			var g:FlxUIGroup = cast asset;
			for (groupAsset in g.members)
				setWidgetSuppression(groupAsset, suppressed);
		}
	}
}
