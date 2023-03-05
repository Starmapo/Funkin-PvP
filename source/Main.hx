package;

import flixel.FlxGame;
import lime.utils.Log;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import states.BootState;

using StringTools;

class Main extends Sprite
{
	public static final TRANSITION_TIME:Float = 0.7;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		Log.level = NONE; // no lime logs

		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		addChild(new FlxGame(0, 0, BootState, 60, 60, true, false));
	}
}
