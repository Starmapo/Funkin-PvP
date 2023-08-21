package backend.util;

import flixel.group.FlxGroup;
import haxe.ui.Toolkit;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;

class HaxeUIUtil
{
	public static function initToolkit()
	{
		// Toolkit.theme = "dark";
		Toolkit.init();
	}
	
	public static function addView(group:FlxGroup, ?component:Component)
	{
		var box = new Box();
		box.width = Screen.instance.width;
		box.height = Screen.instance.height;
		
		if (component != null)
			box.addComponent(component);
			
		group.add(box);
		return box;
	}
}
