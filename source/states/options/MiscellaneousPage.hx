package states.options;

import data.Settings;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;

class MiscellaneousPage extends BaseSettingsPage
{
	public function new()
	{
		super();
		rpcDetails = 'Miscellaneous Options';

		addSetting({
			name: 'autoPause',
			displayName: 'Auto Pause',
			description: "If enabled, the game will pause while you aren't viewing it.",
			type: CHECKBOX
		}, function()
		{
			FlxG.autoPause = Settings.autoPause;
		});
		addSetting({
			name: 'fastTransitions',
			displayName: 'Fast Transitions',
			description: "If enabled, transitions between screens are faster.",
			type: CHECKBOX
		}, function()
		{
			FlxTransitionableState.defaultTransOut.duration = FlxTransitionableState.defaultTransIn.duration = Main.getTransitionTime();
		});
		addSetting({
			name: 'persistentCache',
			displayName: 'Persistent Cache',
			description: "If enabled, graphics and sounds will be kept in memory even when they're unused.",
			type: CHECKBOX
		});
	}
}
