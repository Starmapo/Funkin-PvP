package states.options;

import data.Settings.TimeDisplay;

class GameplayPage extends BaseSettingsPage
{
	public function new()
	{
		super();

		addSetting({
			name: 'lowQuality',
			displayName: 'Low Quality',
			description: "If enabled, some background details are disabled, improving performance and reducing loading times.",
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'shaders',
			displayName: 'Shaders',
			description: "Whether gameplay shaders are enabled.",
			type: CHECKBOX,
			defaultValue: true
		});
		addSetting({
			name: 'backgroundBrightness',
			displayName: 'Background Brightness',
			description: "Change how visible the background elements should be.",
			type: PERCENT,
			defaultValue: 1,
			minValue: 0,
			maxValue: 1
		});
		addSetting({
			name: 'hideHUD',
			displayName: 'Hide HUD',
			description: "If enabled, hides most HUD elements.",
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'timeDisplay',
			displayName: 'Time Display',
			description: 'Select what the time should display.',
			type: STRING,
			defaultValue: TimeDisplay.TIME_ELAPSED,
			options: [
				TimeDisplay.TIME_ELAPSED,
				TimeDisplay.TIME_LEFT,
				TimeDisplay.PERCENTAGE,
				TimeDisplay.DISABLED
			]
		});
		addSetting({
			name: 'healthBarAlpha',
			displayName: 'Health Bars Opacity',
			description: "Change how visible the health bars should be.",
			type: PERCENT,
			defaultValue: 1,
			minValue: 0,
			maxValue: 1
		});
		addSetting({
			name: 'camZooming',
			displayName: 'Camera Zooming on Beat',
			description: "If enabled, the camera will zoom in on every bar.",
			type: CHECKBOX,
			defaultValue: true
		});
		addSetting({
			name: 'clearGameplayCache',
			displayName: 'Clear Gameplay Cache',
			description: "If enabled, graphics and sounds loaded while in gameplay will be cleared after exiting.",
			type: CHECKBOX,
			defaultValue: true
		});
	}
}
