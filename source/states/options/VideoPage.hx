package states.options;

import data.Settings;
import flixel.FlxG;
import openfl.Lib;

class VideoPage extends BaseSettingsPage
{
	public function new()
	{
		super();
		rpcDetails = 'Video Options';

		addSetting({
			name: 'resolution',
			displayName: 'Window Resolution',
			description: 'How big the game window should be.',
			type: PERCENT,
			defaultValue: 1,
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
			defaultValue: 60,
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
			FlxG.setFramerate(Settings.fpsCap);
		});
		addSetting({
			name: 'antialiasing',
			displayName: 'Antialiasing',
			description: "Whether antialiasing is enabled.",
			type: CHECKBOX,
			defaultValue: true
		}, function()
		{
			FlxG.forceNoAntialiasing = !Settings.antialiasing;
		});
		addSetting({
			name: 'hue',
			displayName: 'Hue',
			description: "Change the hues of the game's colors.",
			type: NUMBER,
			defaultValue: 0,
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
			defaultValue: 0,
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
			defaultValue: 1,
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
			defaultValue: FilterType.NONE,
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
			type: CHECKBOX,
			defaultValue: false
		});
	}
}
