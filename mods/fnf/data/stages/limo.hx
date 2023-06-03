var limo:FlxSprite;
var grpLimoDancers:FlxTypedGroup<FlxSprite>;
var fastCar:FlxSprite;
var fastCarCanDrive:Bool = true;
var danceDir:Bool = false;

function onCreate()
{
	state.defaultCamZoom = 0.9;

	var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.getImage('stages/limo/limoSunset'));
	skyBG.scrollFactor.set(0.1, 0.1);
	skyBG.antialiasing = true;
	skyBG.active = false;
	addBehindChars(skyBG);

	if (!Settings.lowQuality)
	{
		var bgLimo:FlxSprite = new FlxSprite(-200, 480);
		bgLimo.frames = Paths.getSpritesheet('stages/limo/bgLimo');
		bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
		bgLimo.animation.play('drive');
		bgLimo.scrollFactor.set(0.4, 0.4);
		bgLimo.antialiasing = true;
		addBehindChars(bgLimo);

		if (Settings.distractions)
		{
			grpLimoDancers = new FlxTypedGroup();
			addBehindChars(grpLimoDancers);

			for (i in 0...5)
			{
				var dancer = new FlxSprite((370 * i) + 130, bgLimo.y - 400);
				dancer.frames = Paths.getSpritesheet("stages/limo/limoDancer");
				dancer.animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				dancer.animation.addByIndices('danceRight', 'bg dancer sketch PINK', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24,
					false);
				dancer.animation.play('danceLeft');
				dancer.animation.finish();
				dancer.antialiasing = true;
				dancer.scrollFactor.set(0.4, 0.4);
				grpLimoDancers.add(dancer);
			}
		}
	}

	limo = new FlxSprite(-120, 550);
	limo.frames = Paths.getSpritesheet('stages/limo/limoDrive');
	limo.animation.addByPrefix('drive', "Limo stage", 24);
	limo.animation.play('drive');
	limo.antialiasing = true;
	addOverGF(limo);

	bf.setCharacterPosition(1030, -160);

	if (Settings.distractions)
	{
		fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.getImage('stages/limo/fastCarLol'));
		fastCar.antialiasing = true;
		addOverChars(fastCar);

		resetFastCar();

		Paths.getSound('carPass0');
		Paths.getSound('carPass1');
	}
	else
		close();
}

function onBeatHit(beat, decBeat)
{
	if (grpLimoDancers != null)
	{
		danceDir = !danceDir;
		grpLimoDancers.forEach(function(dancer)
		{
			if (danceDir)
				dancer.animation.play('danceRight', true);
			else
				dancer.animation.play('danceLeft', true);
		});
	}

	if (fastCar != null && fastCarCanDrive && FlxG.random.bool(10))
		fastCarDrive();
}

function resetFastCar():Void
{
	fastCar.x = -12600;
	fastCar.y = FlxG.random.int(400, 560);
	fastCar.velocity.x = 0;
	fastCarCanDrive = true;
}

function fastCarDrive()
{
	var sound = FlxG.sound.play(Paths.getSound('carPass' + FlxG.random.int(0, 1)), 0.7);
	sound.pitch = playbackRate;

	fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3 * playbackRate;
	fastCarCanDrive = false;
	new FlxTimer().start(2 / playbackRate, function(tmr:FlxTimer)
	{
		resetFastCar();
	});
}