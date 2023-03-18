package states.editors;

import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUITabMenu;
import flixel.util.FlxColor;

class EditorPanel extends FlxUITabMenu
{
	public function new(?tabs:Array<{name:String, label:String}>)
	{
		super(null, null, tabs);
		for (tab in _tabs)
		{
			var tab:FlxUIButton = cast tab;
			tab.label.setBorderStyle(OUTLINE, FlxColor.BLACK);
		}
		scrollFactor.set();
	}

	function createTab(name:String)
	{
		var tab = new FlxUI();
		tab.name = name;
		return tab;
	}
}
