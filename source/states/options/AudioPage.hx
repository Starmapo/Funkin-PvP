package states.options;

import data.Settings;
import flixel.FlxG;

class AudioPage extends BaseSettingsPage
{
	public function new()
	{
		super();
		rpcDetails = 'Audio Options';
		
		addSetting({
			name: 'musicVolume',
			displayName: 'Music Volume',
			description: "How loud the music should be.",
			type: PERCENT,
			minValue: 0,
			maxValue: 1
		}, function()
		{
			FlxG.sound.defaultMusicGroup.volume = Settings.musicVolume;
		});
		addSetting({
			name: 'effectVolume',
			displayName: 'Effect Volume',
			description: "How loud the sound effects should be.",
			type: PERCENT,
			minValue: 0,
			maxValue: 1
		}, function()
		{
			FlxG.sound.defaultSoundGroup.volume = Settings.effectVolume;
		});
		addSetting({
			name: 'globalOffset',
			displayName: 'Global Offset',
			description: "An offset to apply to every song. Negative offset means the timing position is behind of the audio position, useful for headphones latency.",
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'ms';
			},
			minValue: -300,
			maxValue: 300,
			holdMult: 2
		});
		/*
			addSetting({
				name: 'smoothAudioTiming',
				displayName: 'Smooth Audio Timing',
				description: "If enabled, attempts to make the audio/frame timing move smoothly, instead of being set to the audio's exact position.",
				type: CHECKBOX
			});
		 */
		
		addPageTitle('Audio');
	}
}
