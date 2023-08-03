package;

import flixel.FlxG;
import flixel.FlxGame;
import lime.utils.Log;
import objects.openfl.NotificationManager;
import objects.openfl.StatsDisplay;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;
import openfl.ui.Keyboard;
import states.BootState;

using StringTools;

/**
	The main sprite which contains everything, including the game.
**/
class Main extends Sprite
{
	/**
		Duration of transitions between screens.
	**/
	public static final TRANSITION_TIME:Float = 0.7;
	
	/**
		Internal variable to track if the audio was disconnected.
	**/
	public static var audioDisconnected:Bool = false;
	
	static var gameFilters:Array<BitmapFilter> = [];
	static var colorFilter:ColorMatrixFilter;
	static var hueFilter:ColorMatrixFilter;
	static var statsDisplay:StatsDisplay;
	static var notificationManager:NotificationManager;
	
	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}
	
	/**
		Gets the proper transition time, taking `Settings.fastTransitions` into account.
	**/
	public static function getTransitionTime():Float
	{
		return TRANSITION_TIME * (Settings.fastTransitions ? 0.4 : 1);
	}
	
	/**
		Displays a new notification, unless `Settings.showInternalNotifications` is disabled.

		@param	info	The text to display in the notification.
		@param	level	The level of the notification (`INFO` (default), `ERROR`, `WARNING`, or `SUCCESS`).
		@return	The new notification, or `null` if internal notifications are disabled.
	**/
	public static function showInternalNotification(info:String, level:NotificationLevel = INFO):Notification
	{
		if (Settings.showInternalNotifications)
			return notificationManager.showNotification(info, level);
			
		return null;
	}
	
	/**
		Displays a new notification.

		@param	info	The text to display in the notification.
		@param	level	The level of the notification (`INFO` (default), `ERROR`, `WARNING`, or `SUCCESS`).
		@return	The new notification.
	**/
	public static function showNotification(info:String, level:NotificationLevel = INFO):Notification
	{
		return notificationManager.showNotification(info, level);
	}
	
	/**
		Updates the color filter based on `Settings.filter`, `Settings.gamma`, and `Settings.brightness`.
	**/
	public static function updateColorFilter():Void
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
	
	/**
		Updates the game's filters.
	**/
	public static function updateFilters():Void
	{
		updateColorFilter();
		updateHueFilter();
		
		gameFilters = [colorFilter, hueFilter];
		FlxG.game.filtersEnabled = true;
		FlxG.game.setFilters(gameFilters);
	}
	
	/**
		Updates the hue filter based on `Settings.hue`.
	**/
	public static function updateHueFilter():Void
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
			
		addChild(new FlxGame(0, 0, BootState, 60, 60, true, false));
		
		addChild(notificationManager = new NotificationManager());
		
		addChild(statsDisplay = new StatsDisplay());
		statsDisplay.visible = false;
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.signals.gameResized.add(onGameResized);
	}
	
	function onGameResized(width:Int, height:Int):Void
	{
		statsDisplay.onResize(width, height);
	}
	
	function onKeyDown(e:KeyboardEvent):Void
	{
		switch (e.keyCode)
		{
			case Keyboard.F3:
				statsDisplay.visible = !statsDisplay.visible;
		}
	}
}
