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
			name: 'reloadMods',
			displayName: 'Reload Mod Content',
			description: "If enabled, mod content will be refreshed when needed (for example, entering the song select screen will refresh what the current songs are). Useful if you're making a mod.",
			type: CHECKBOX
		});
		addSetting({
			name: 'forceCacheReset',
			displayName: 'Force Cache Reset',
			description: "If enabled, the cache will always be reset after a state switch, reloading everything.",
			type: CHECKBOX
		});
		
		addPageTitle('Miscellaneous');
	}
}
