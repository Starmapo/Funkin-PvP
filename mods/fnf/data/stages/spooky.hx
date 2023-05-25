var halloweenBG:FlxSprite;
var lightningStrikeBeat:Int = 0;
var lightningOffset:Int = 8;

function onCreate()
{
	halloweenBG = new FlxSprite(-200, -100);
	halloweenBG.frames = Paths.getSpritesheet('stages/spooky/halloween_bg');
	halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
	halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
	halloweenBG.animation.play('idle');
	halloweenBG.antialiasing = true;
	addBehindChars(halloweenBG);

	if (!Settings.lowQuality && Settings.distractions)
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
	halloweenBG.animation.play('lightning');

	lightningStrikeBeat = beat;
	lightningOffset = Math.round(FlxG.random.int(8, 24) * playbackRate);

	bf.playAnim('scared', true);
	gf.playAnim('scared', true);
}
