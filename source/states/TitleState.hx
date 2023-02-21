package states;

import data.song.TimingPoint;
import flixel.FlxG;
import flixel.util.FlxTimer;
import util.MusicTiming;

class TitleState extends FNFState
{
	var timing:MusicTiming;

	override public function create()
	{
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});

		super.create();
	}

	override public function update(elapsed:Float)
	{
		if (timing != null)
			timing.update(elapsed);

		super.update(elapsed);
	}

	function startIntro()
	{
		if (!FlxG.sound.musicPlaying)
		{
			CoolUtil.playMenuMusic(0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}

		timing = new MusicTiming(FlxG.sound.music, null, [
			new TimingPoint({
				startTime: 0,
				bpm: 102,
				meter: 4
			})
		]);
	}
}
