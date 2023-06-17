import data.Settings;
import flixel.FlxG;
import flixel.FlxGame;
import lime.utils.Log;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;
import openfl.ui.Keyboard;
import states.BootState;
import ui.StatsDisplay;

using StringTools;

class Main extends Sprite
{
	public static final TRANSITION_TIME:Float = 0.7;

	public static var audioDisconnected:Bool = false;

	static var gameFilters:Array<BitmapFilter> = [];
	static var colorFilter:ColorMatrixFilter;
	static var hueFilter:ColorMatrixFilter;
	static var statsDisplay:StatsDisplay;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public static function updateFilters()
	{
		updateColorFilter();
		updateHueFilter();

		gameFilters = [colorFilter, hueFilter];
		FlxG.game.filtersEnabled = true;
		FlxG.game.setFilters(gameFilters);
	}

	public static function updateColorFilter()
	{
		if (colorFilter == null)
			colorFilter = new ColorMatrixFilter();

		colorFilter.matrix = switch (Settings.filter)
		{
			case NONE:
				[
					1 * Settings.gamma,                  0,                  0, 0, Settings.brightness,
					                 0, 1 * Settings.gamma,                  0, 0, Settings.brightness,
					                 0,                  0, 1 * Settings.gamma, 0, Settings.brightness,
					                 0,                  0,                  0, 1,                   0,
				];
			case DEUTERANOPIA:
				[
					0.43 * Settings.gamma, 0.72 * Settings.gamma, -.15 * Settings.gamma, 0, Settings.brightness,
					0.34 * Settings.gamma, 0.57 * Settings.gamma, 0.09 * Settings.gamma, 0, Settings.brightness,
					-.02 * Settings.gamma, 0.03 * Settings.gamma,    1 * Settings.gamma, 0, Settings.brightness,
					                    0,                     0,                     0, 1,                   0,
				];
			case PROTANOPIA:
				[
					0.20 * Settings.gamma, 0.99 * Settings.gamma, -.19 * Settings.gamma, 0, Settings.brightness,
					0.16 * Settings.gamma, 0.79 * Settings.gamma, 0.04 * Settings.gamma, 0, Settings.brightness,
					0.01 * Settings.gamma, -.01 * Settings.gamma,    1 * Settings.gamma, 0, Settings.brightness,
					                    0,                     0,                     0, 1,                   0,
				];
			case TRITANOPIA:
				[
					0.20 * Settings.gamma, 0.99 * Settings.gamma, -.19 * Settings.gamma, 0, Settings.brightness,
					0.16 * Settings.gamma, 0.79 * Settings.gamma, 0.04 * Settings.gamma, 0, Settings.brightness,
					0.01 * Settings.gamma, -.01 * Settings.gamma,    1 * Settings.gamma, 0, Settings.brightness,
					                    0,                     0,                     0, 1,                   0,
				];
			case DOWNER:
				[
					0, 0,                    0, 0,                   0,
					0, 0,                    0, 0,                   0,
					0, 0, 1.5 * Settings.gamma, 0, Settings.brightness,
					0, 0,                    0, 1,                   0,
				];
			case GAME_BOY:
				[
					0,                    0, 0, 0,                   0,
					0, 1.5 * Settings.gamma, 0, 0, Settings.brightness,
					0,                    0, 0, 0,                   0,
					0,                    0, 0, 1,                   0,
				];
			case GRAYSCALE:
				[
					.3 * Settings.gamma, .3 * Settings.gamma, .3 * Settings.gamma, 0, Settings.brightness,
					.3 * Settings.gamma, .3 * Settings.gamma, .3 * Settings.gamma, 0, Settings.brightness,
					.3 * Settings.gamma, .3 * Settings.gamma, .3 * Settings.gamma, 0, Settings.brightness,
					                  0,                   0,                   0, 1,                   0,
				];
			case INVERT:
				[
					-1 * Settings.gamma,                   0,                   0, 0, 255 + Settings.brightness,
					                  0, -1 * Settings.gamma,                   0, 0, 255 + Settings.brightness,
					                  0,                   0, -1 * Settings.gamma, 0, 255 + Settings.brightness,
					                  0,                   0,                   0, 1,                         1,
				];
			case VIRTUAL_BOY:
				[
					0.9 * Settings.gamma, 0, 0, 0, Settings.brightness,
					                   0, 0, 0, 0,                   0,
					                   0, 0, 0, 0,                   0,
					                   0, 0, 0, 1,                   0,
				];
		}
	}

	public static function updateHueFilter()
	{
		if (hueFilter == null)
			hueFilter = new ColorMatrixFilter();

		var cosA:Float = Math.cos(-Settings.hue * Math.PI / 180);
		var sinA:Float = Math.sin(-Settings.hue * Math.PI / 180);

		var a1:Float = cosA + (1.0 - cosA) / 3.0;
		var a2:Float = 1.0 / 3.0 * (1.0 - cosA) - Math.sqrt(1.0 / 3.0) * sinA;
		var a3:Float = 1.0 / 3.0 * (1.0 - cosA) + Math.sqrt(1.0 / 3.0) * sinA;

		var b1:Float = a3;
		var b2:Float = cosA + 1.0 / 3.0 * (1.0 - cosA);
		var b3:Float = a2;

		var c1:Float = a2;
		var c2:Float = a3;
		var c3:Float = b2;

		hueFilter.matrix = [
			a1, b1, c1, 0, 0,
			a2, b2, c2, 0, 0,
			a3, b3, c3, 0, 0,
			 0,  0,  0, 1, 0
		];
	}

	public static function getTransitionTime()
	{
		return TRANSITION_TIME * (Settings.fastTransitions ? 0.4 : 1);
	}

	public function new()
	{
		Log.level = NONE; // no lime logs

		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		addChild(new FNFGame(0, 0, BootState, 60, 60, true, false));

		addChild(statsDisplay = new StatsDisplay());
		statsDisplay.visible = false;

		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.signals.gameResized.add(onGameResized);
	}

	function onKeyDown(e:KeyboardEvent)
	{
		switch (e.keyCode)
		{
			case Keyboard.F3:
				statsDisplay.visible = !statsDisplay.visible;
		}
	}

	function onGameResized(width:Int, height:Int)
	{
		statsDisplay.onResize(width, height);
	}
}
