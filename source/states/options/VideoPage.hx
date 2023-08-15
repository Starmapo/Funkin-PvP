package states.options;

import flixel.FlxG;
import flixel.FlxSprite;
import lime.app.Application;
import openfl.Lib;

class VideoPage extends BaseSettingsPage
{
	var ogAntialiasing:Map<FlxSprite, Bool> = new Map();
	
	public function new()
	{
		super();
		rpcDetails = 'Video Options';
		
		addSetting({
			name: 'resolution',
			displayName: 'Window Resolution',
			description: 'How big the game window should be.',
			type: PERCENT,
			displayFunction: function(value)
			{
				var value:Float = value;
				return Math.round(FlxG.width * value) + "x" + Math.round(FlxG.height * value);
			},
			minValue: 0.2,
			changeAmount: 0.2
		}, function()
		{
			Lib.application.window.maximized = false;
			FlxG.resizeWindow(Math.round(FlxG.width * Settings.resolution), Math.round(FlxG.height * Settings.resolution));
			FlxG.fullscreen = false;
		});
		addSetting({
			name: 'fpsCap',
			displayName: 'Framerate Cap',
			description: 'The maximum amount of FPS allowed in the game.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + ' FPS';
			},
			minValue: 60,
			maxValue: 360,
			changeAmount: 10,
			holdDelay: 0.05
		}, function()
		{
			CoolUtil.setFramerate(Settings.fpsCap);
			var state:OptionsState = cast FlxG.state;
			state.camPages.followLerp = CoolUtil.getLerp(0.1);
		});
		addSetting({
			name: 'vsync',
			displayName: 'VSync',
			description: "Whether vertical sync is enabled, eliminating screen tearing but possibly slowing down performance.",
			type: CHECKBOX
		}, function()
		{
			Application.current.window.vsync = Settings.vsync;
		});
		addSetting({
			name: 'antialiasing',
			displayName: 'Antialiasing',
			description: "Whether antialiasing is enabled. Changes will take place after exiting the options menu.",
			type: CHECKBOX
		});
		addSetting({
			name: 'hue',
			displayName: 'Hue',
			description: "Change the hues of the game's colors.",
			type: NUMBER,
			minValue: 0,
			maxValue: 359,
			wrap: true
		}, function()
		{
			Main.updateHueFilter();
		});
		addSetting({
			name: 'brightness',
			displayName: 'Brightness',
			description: "Change how bright the game looks.",
			type: NUMBER,
			displayFunction: function(value)
			{
				return value / 2 + '%';
			},
			minValue: -200,
			maxValue: 200,
			changeAmount: 10
		}, function()
		{
			Main.updateColorFilter();
		});
		addSetting({
			name: 'gamma',
			displayName: 'Gamma',
			description: "Change how vibrant the game looks.",
			type: PERCENT,
			minValue: 0.1,
			maxValue: 1
		}, function()
		{
			Main.updateColorFilter();
		});
		addSetting({
			name: 'filter',
			displayName: 'Filter',
			description: 'Select a filter for colorblindness, or just for fun.',
			type: STRING,
			options: [
				FilterType.NONE,
				FilterType.DEUTERANOPIA,
				FilterType.PROTANOPIA,
				FilterType.TRITANOPIA,
				FilterType.DOWNER,
				FilterType.GAME_BOY,
				FilterType.GRAYSCALE,
				FilterType.INVERT,
				FilterType.VIRTUAL_BOY
			]
		}, function()
		{
			Main.updateColorFilter();
		});
		addSetting({
			name: 'flashing',
			displayName: 'Flashing Lights',
			description: "Whether flashing lights are enabled.",
			type: CHECKBOX
		});
		
		addPageTitle('Video');
	}
	
	override function destroy()
	{
		super.destroy();
		ogAntialiasing = null;
	}
}
