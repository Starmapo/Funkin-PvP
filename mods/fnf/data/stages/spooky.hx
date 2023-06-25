var lightningStrikeBeat:Int = 0;
var lightningOffset:Int = 8;

function onCreate()
{
	if (!Settings.lowQuality)
	{
		Paths.getSound('thunder_1');
		Paths.getSound('thunder_2');
	}
	else
		close();
}

function onBeatHit(beat, decBeat)
{
	if (lightningStrikeBeat > beat)
		lightningStrikeBeat = 0;
	if (beat > lightningStrikeBeat + lightningOffset && FlxG.random.bool(10))
		lightningStrikeShit(beat);
}

function lightningStrikeShit(beat:Int)
{
	FlxG.sound.play(Paths.getSound('thunder_' + FlxG.random.int(1, 2)));
	halloweenBG.playAnim('lightning');

	lightningStrikeBeat = beat;
	lightningOffset = Math.round(FlxG.random.int(8, 24) * playbackRate);

	bf.playAnim('scared', true);
	gf.playAnim('scared', true);
}
