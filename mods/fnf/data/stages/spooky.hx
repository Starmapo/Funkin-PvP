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
	
	Paths.getSound('thunder_1');
	Paths.getSound('thunder_2');
}

function onBeatHit(beat, decBeat)
{
	if (beat > lightningStrikeBeat + lightningOffset && FlxG.random.bool(10))
		lightningStrikeShit(beat);
}

function lightningStrikeShit(beat:Int)
{
	FlxG.sound.play(Paths.getSound('thunder_' + FlxG.random.int(1, 2)));
	halloweenBG.animation.play('lightning');

	lightningStrikeBeat = beat;
	lightningOffset = FlxG.random.int(8, 24);

	bf.playAnim('scared', true);
	gf.playAnim('scared', true);
}