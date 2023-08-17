package backend.util;

import haxe.ui.Toolkit;

class HaxeUIUtil
{
	public static function initToolkit()
	{
		if (!Toolkit.initialized)
		{
			Toolkit.theme = "flixel-ui";
			Toolkit.init();
		}
	}
}
