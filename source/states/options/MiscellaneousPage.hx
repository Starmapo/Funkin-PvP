package states.options;

import data.Settings;
import flixel.FlxG;

class MiscellaneousPage extends BaseSettingsPage
{
	public function new()
	{
		super();

		addSetting({
			name: 'autoPause',
			displayName: 'Auto Pause',
			description: "If enabled, the game will pause while you aren't viewing it.",
			type: CHECKBOX,
			defaultValue: false
		}, function()
		{
			FlxG.autoPause = Settings.autoPause;
		});
		addSetting({
			name: 'persistentCache',
			displayName: 'Persistent Cache',
			description: "If enabled, graphics and sounds will be kept in memory even when they're unused.",
			type: CHECKBOX,
			defaultValue: true
		});
	}
}
