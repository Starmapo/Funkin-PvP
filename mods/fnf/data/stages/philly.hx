var phillyCityLights:FlxTypedGroup<FlxSprite>;
var trainSound:FlxSound;
var trainMoving:Bool = false;
var trainFrameTiming:Float = 0;
var trainCars:Int = 8;
var trainFinishing:Bool = false;
var trainCooldown:Int = 0;
var curLight:Int = 0;
var startedMoving:Bool = false;
var lightFadeShader:FlxRuntimeShader;

function onCreate()
{
	if (Settings.distractions)
	{
		if (Settings.shaders)
		{
			lightFadeShader = getShader("building");
			lightFadeShader.setFloat("alphaShit", 0);
		}

		phillyCityLights = new FlxTypedGroup();
		phillyCityLights.active = false;
		insert(members.indexOf(city) + 1, phillyCityLights);

		for (i in 0...5)
		{
			var light = new FlxSprite(city.x).loadGraphic(Paths.getImage('stages/philly/win' + i));
			light.scrollFactor.set(0.3, 0.3);
			light.visible = false;
			light.setGraphicSize(Std.int(light.width * 0.85));
			light.updateHitbox();
			light.antialiasing = true;
			if (lightFadeShader != null)
				light.shader = lightFadeShader;
			phillyCityLights.add(light);
		}
		
		trainSound = new FlxSound().loadEmbedded(Paths.getSound('train_passes'));
		trainSound.pitch = playbackRate;
		FlxG.sound.list.add(trainSound);
	}
	else
		close();
}

function onUpdate(elapsed)
{
	if (trainMoving)
	{
		trainFrameTiming += elapsed;

		if (trainFrameTiming >= 1 / 24)
		{
			updateTrainPos();
			trainFrameTiming = 0;
		}
	}

	if (lightFadeShader != null)
	{
		var point = timing.curTimingPoint;
		if (point != null)
			lightFadeShader.setFloat("alphaShit", lightFadeShader.getFloat("alphaShit") + ((point.beatLength / playbackRate / 1000) * elapsed * 1.5));
	}
}

function onBeatHit(beat, decBeat)
{
	if (!trainMoving)
		trainCooldown += 1;

	if (beat % 4 == 0)
	{
		if (lightFadeShader != null)
			lightFadeShader.setFloat("alphaShit", 0);

		phillyCityLights.forEach(function(light:FlxSprite)
		{
			light.visible = false;
		});

		curLight = FlxG.random.int(0, phillyCityLights.length - 1);

		phillyCityLights.members[curLight].visible = true;
	}

	if (beat % 8 == 4 && !trainMoving && trainCooldown > 8 && FlxG.random.bool(30))
	{
		trainCooldown = Math.round(FlxG.random.int(-4, 0) * playbackRate);
		trainStart();
	}
}

function updateTrainPos()
{
	if (trainSound.time >= 4700)
	{
		startedMoving = true;
		gf.playAnim('hairBlow');
		gf.danceDisabled = true;
		phillyTrain.visible = true;
	}

	if (startedMoving)
	{
		phillyTrain.x -= 400 * playbackRate;

		if (phillyTrain.x < -2000 && !trainFinishing)
		{
			phillyTrain.x = -1150;
			trainCars -= 1;

			if (trainCars <= 0)
				trainFinishing = true;
		}

		if (phillyTrain.x < -4000 && trainFinishing)
			trainReset();
	}
}

function trainReset():Void
{
	gf.playAnim('hairFall');
	gf.animation.finishCallback = function(name)
	{
		gf.danceDisabled = false;
	}
	phillyTrain.x = FlxG.width + 200;
	phillyTrain.visible = false;
	trainMoving = false;
	trainCars = 8;
	trainFinishing = false;
	startedMoving = false;
}

function trainStart():Void
{
	trainMoving = true;
	trainSound.play(true);
}
