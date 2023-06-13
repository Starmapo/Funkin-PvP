package states.options;

import data.Settings.TimeDisplay;

class GameplayPage extends BaseSettingsPage
{
	public function new()
	{
		super();
		rpcDetails = 'Gameplay Options';

		addSetting({
			name: 'lowQuality',
			displayName: 'Low Quality',
			description: "If enabled, some background details are disabled, improving performance and reducing loading times.",
			type: CHECKBOX
		});
		addSetting({
			name: 'distractions',
			displayName: 'Distractions',
			description: "Toggle stage distractions that can hinder your gameplay.",
			type: CHECKBOX
		});
		addSetting({
			name: 'shaders',
			displayName: 'Shaders',
			description: "Whether gameplay shaders are enabled.",
			type: CHECKBOX
		});
		addSetting({
			name: 'forceDefaultStage',
			displayName: 'Force Default Stage',
			description: "If enabled, the Week 1 stage is forced on every song.",
			type: CHECKBOX
		});
		addSetting({
			name: 'backgroundBrightness',
			displayName: 'Background Brightness',
			description: "Change how visible the background elements should be.",
			type: PERCENT,
			minValue: 0,
			maxValue: 1
		});
		addSetting({
			name: 'hideHUD',
			displayName: 'Hide HUD',
			description: "If enabled, hides most HUD elements.",
			type: CHECKBOX
		});
		addSetting({
			name: 'timeDisplay',
			displayName: 'Time Display',
			description: 'Select what the time should display.',
			type: STRING,
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
			minValue: 0,
			maxValue: 1
		});
		addSetting({
			name: 'healthBarColors',
			displayName: 'Character Health Colors',
			description: "If enabled, health bars have their colors match the character icons.",
			type: CHECKBOX
		});
		addSetting({
			name: 'breakTransparency',
			displayName: 'Receptors Transparent on Break',
			description: "If enabled, playfield receptors will get more transparent while there aren't notes nearby.",
			type: CHECKBOX
		});
		addSetting({
			name: 'cameraNoteMovements',
			displayName: 'Camera Note Movements',
			description: "If enabled, the camera will move in the direction of notes.",
			type: CHECKBOX
		});
		addSetting({
			name: 'missSounds',
			displayName: 'Miss Sounds',
			description: "Whether or not a sound should play when you miss a note.",
			type: CHECKBOX
		});
		addSetting({
			name: 'camZooming',
			displayName: 'Camera Zooming on Beat',
			description: "If enabled, the camera will zoom in on every bar/measure.",
			type: CHECKBOX
		});
		addSetting({
			name: 'resultsScreen',
			displayName: 'Results Screen',
			description: "If enabled, a results screen is shown after a match.",
			type: CHECKBOX
		});
		/*
		addSetting({
			name: 'clearGameplayCache',
			displayName: 'Clear Gameplay Cache',
			description: "If enabled, graphics and sounds loaded while in gameplay will be cleared after exiting.",
			type: CHECKBOX
		});
		*/
	}
}
