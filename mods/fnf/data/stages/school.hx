var bgGirls:FlxSprite;
var danceDir:Bool = false;
var daPixelZoom:Float = 6;

function onCreate()
{
	if (!Settings.lowQuality)
	{
		bgGirls = new FlxSprite(-100, 190);
		bgGirls.frames = Paths.getSpritesheet('stages/weeb/bgFreaks');
		bgGirls.animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
		bgGirls.animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);
		bgGirls.animation.play('danceLeft');
		bgGirls.animation.finish();
		bgGirls.scrollFactor.set(0.9, 0.9);

		if (songName == 'Roses')
		{
			bgGirls.animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
			bgGirls.animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);
			bgGirlsDance();
			bgGirls.animation.finish();
		}

		bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
		bgGirls.updateHitbox();
		addBehindChars(bgGirls);
	}
	else
		close();
}

function onBeatHit(beat, decBeat)
{
	bgGirlsDance();
}

function bgGirlsDance()
{
	if (bgGirls != null)
	{
		danceDir = !danceDir;

		if (danceDir)
			bgGirls.animation.play('danceRight', true);
		else
			bgGirls.animation.play('danceLeft', true);
	}
}
