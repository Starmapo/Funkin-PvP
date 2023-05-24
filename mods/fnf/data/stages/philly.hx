var phillyCityLights:FlxTypedGroup<FlxSprite>;
var phillyTrain:FlxSprite;
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
	if (!Settings.lowQuality) {
		var bg = new FlxSprite(-100).loadGraphic(Paths.getImage('stages/philly/sky'));
		bg.scrollFactor.set(0.1, 0.1);
		bg.antialiasing = true;
		addBehindChars(bg);
	}

	var city = new FlxSprite(-10).loadGraphic(Paths.getImage('stages/philly/city'));
	city.scrollFactor.set(0.3, 0.3);
	city.setGraphicSize(Std.int(city.width * 0.85));
	city.updateHitbox();
	city.antialiasing = true;
	addBehindChars(city);
	
	if (Settings.shaders)
	{
		lightFadeShader = getShader("building");
		lightFadeShader.setFloat("alphaShit", 0);
	}
	
	phillyCityLights = new FlxTypedGroup();
	addBehindChars(phillyCityLights);
	
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

	if (!Settings.lowQuality) {
		var streetBehind = new FlxSprite(-40, 50).loadGraphic(Paths.getImage('stages/philly/behindTrain'));
		addBehindChars(streetBehind);
	}

	phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.getImage('stages/philly/train'));
	phillyTrain.visible = false;
	phillyTrain.antialiasing = true;
	addBehindChars(phillyTrain);

	trainSound = new FlxSound().loadEmbedded(Paths.getSound('train_passes'));
	FlxG.sound.list.add(trainSound);
	
	var street = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.getImage('stages/philly/street'));
	street.antialiasing = true;
	addBehindChars(street);
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
		trainCooldown = FlxG.random.int(-4, 0);
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
		phillyTrain.x -= 400;

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