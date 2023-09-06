var inkStormRain:FlxSprite;
var inkscroll:FlxTypedGroup<FlxSprite>;
var blackOverlay:FlxSprite;
var brightShader:FlxRuntimeShader;
var defaultBrightVal:Float = -0.05;
var brightSpeed:Float = 0.2;
var brightMagnitude:Float = 0.05;
var bendy:FlxSprite;
var jumpscareStatic:FlxSprite;
var chromaShader:FlxRuntimeShader;
var defaultChromVal:Float = 0;
var chromVal:Float = defaultChromVal;

function onCreatePost()
{
	if (staticBG != null)
		staticBG.visible = false;

	inkStormRain = new FlxSprite();
	inkStormRain.frames = Paths.getSpritesheet('stages/InkRain');
	inkStormRain.animation.addByPrefix('play', 'erteyd instance 1', 30, true);
	inkStormRain.antialiasing = true;
	inkStormRain.setGraphicSize(FlxG.width);
	inkStormRain.updateHitbox();
	inkStormRain.screenCenter();
	inkStormRain.cameras = [camHUD];
	addBehindUI(inkStormRain);
	inkStormRain.alpha = 0.0001;

	inkscroll = new FlxTypedGroup();
	addBehindUI(inkscroll);

	for (i in 0...3)
	{
		var ink:FlxSprite;
		ink = new FlxSprite().loadGraphic(Paths.getImage('stages/Ink_shit'));
		ink.antialiasing = true;
		ink.alpha = 0.0001;
		ink.cameras = [camHUD];
		ink.setGraphicSize(FlxG.width);
		ink.updateHitbox();
		ink.x += i * 762;
		ink.blend = BlendMode.OVERLAY;
		inkscroll.add(ink);
	}

	blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	blackOverlay.updateHitbox();
	blackOverlay.screenCenter();
	blackOverlay.alpha = 0.0001;
	blackOverlay.scrollFactor.set();
	blackOverlay.cameras = [camHUD];
	addBehindUI(blackOverlay);

	if (Settings.shaders)
	{
		brightShader = getShader("bright");
		brightShader.setFloat("contrast", 1);
		FlxG.camera.addShader(brightShader);

		chromaShader = getShader("chromaticAberration");
		setChroma(chromVal);
		addGameShader(chromaShader);
	}

	if (opponent.info.name == "bendyNightmare" && opponent.info.mod == modID)
	{
		opponent.visible = false;
		Paths.getSound('bendy/nmbendy_land');
		if (!Settings.lowQuality)
		{
			bendy = new FlxSprite();
			bendy.frames = Paths.getSpritesheet('stages/factory-nightmare/NightmareJumpscares03');
			bendy.animation.addByPrefix('play', 'Emmi instance 1', 24, false);
			bendy.antialiasing = true;
			bendy.setGraphicSize(FlxG.width);
			bendy.updateHitbox();
			bendy.screenCenter();
			bendy.scrollFactor.set();
			bendy.cameras = [camHUD];
			bendy.alpha = 0.0001;
			addBehindUI(bendy);

			jumpscareStatic = new FlxSprite();
			jumpscareStatic.frames = Paths.getSpritesheet('stages/factory-nightmare/static');
			jumpscareStatic.animation.addByPrefix('static', 'static', 24, true);
			jumpscareStatic.antialiasing = true;
			jumpscareStatic.updateHitbox();
			jumpscareStatic.scrollFactor.set();
			jumpscareStatic.setGraphicSize(Std.int(FlxG.width * 1.1));
			jumpscareStatic.screenCenter();
			jumpscareStatic.cameras = [camHUD];
			jumpscareStatic.visible = false;
			addBehindUI(jumpscareStatic);

			Paths.getSound('Lights_Turn_On');
			Paths.getSound('scare_bendy');
		}
	}
}

function onUpdatePost(elapsed)
{
	if (inkscroll != null)
	{
		for (i in inkscroll)
		{
			i.x += 350 * elapsed * playbackRate;
			if (i.x >= 1280)
				i.x = -i.width;
		}
	}

	if (Settings.shaders && brightSpeed != 0)
		setBrightness(defaultBrightVal
			+ Math.sin((timing.audioPosition / 1000) * (timing.curTimingPoint != null ? (timing.curTimingPoint.bpm / 60) : 1) * brightSpeed) * brightMagnitude);
	else
		setBrightness(defaultBrightVal);

	if (Settings.flashing)
		setChroma(chromVal);

	FlxG.watch.addQuick("c", state.defaultCamZoom);
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Bendy Fall":
			if (opponent.info.name != "bendyNightmare" || opponent.info.mod != modID)
				return;
			opponent.visible = true;
			opponent.playSpecialAnim('intro', 0, true);
			new FlxTimer().start(0.10 / playbackRate, function(tmr:FlxTimer)
			{
				FlxG.camera.shake(0.20, 0.05 / playbackRate);
			});
			FlxG.sound.play(Paths.getSound('bendy/nmbendy_land')).pitch = playbackRate;
		case "Show BG":
			FlxTween.tween(despairBG, {alpha: 1}, Std.parseFloat(params[0]) / playbackRate, {ease: Reflect.field(FlxEase, params[1])});
		case "Hide BG":
			FlxTween.tween(despairBG, {alpha: 0}, Std.parseFloat(params[0]) / playbackRate, {ease: Reflect.field(FlxEase, params[1])});
		case "Ink Storm":
			if (inkStormRain == null)
				return;
			inkStormRain.animation.play('play', true);
			for (inkscroll in inkscroll)
				FlxTween.tween(inkscroll, {alpha: 0.6}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
			FlxTween.tween(inkStormRain, {alpha: 1}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
			FlxTween.tween(blackOverlay, {alpha: 0.33}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
		case "Ink Storm Fade":
			if (inkStormRain == null)
				return;
			for (inkscroll in inkscroll)
				FlxTween.tween(inkscroll, {alpha: 0}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
			FlxTween.tween(inkStormRain, {alpha: 0}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
			FlxTween.tween(blackOverlay, {alpha: 0}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
		case "Show Fire":
			fire.animation.play('fire', true);
			FlxTween.tween(fire, {y: -227, alpha: 1}, 7.68 / playbackRate, {ease: FlxEase.sineOut});
		case "Ink":
			if (Settings.lowQuality || opponent.info.name != "bendyNightmare" || opponent.info.mod != modID)
				return;
			opponent.playSpecialAnim("indiecross_ink", true);
			opponent.danceDisabled = true;
		case "Jumpscare":
			if (Settings.lowQuality || opponent.info.name != "bendyNightmare" || opponent.info.mod != modID)
				return;
			bendy.alpha = 1;
			bendy.animation.play('play');
			jumpscareStatic.animation.play('static');
			FlxG.sound.play(Paths.getSound('Lights_Turn_On'));
			FlxG.sound.play(Paths.getSound('scare_bendy'));

			new FlxTimer().start(0.66 / playbackRate, function(tmr:FlxTimer)
			{
				jumpscareStatic.visible = true;
				FlxTween.color(jumpscareStatic, 1.85 / playbackRate, FlxColor.WHITE, FlxColor.BLACK, {ease: FlxEase.quadOut});
				bendy.alpha = 0.0;
			});
	}
}

function onCharacterSing(char, lane, hold)
{
	if (char == opponent && Settings.flashing)
	{
		FlxG.camera.shake(0.015, 0.1 / playbackRate);
		camHUD.shake(0.005, 0.1 / playbackRate);
		chromVal = FlxG.random.float(0.005, 0.01);
		FlxTween.num(chromVal, defaultChromVal, FlxG.random.float(0.05, 0.12) / playbackRate, null, function(n)
		{
			chromVal = n;
		});
	}
}

function setBrightness(value)
{
	if (brightShader != null)
		brightShader.setFloat("brightness", value);
}

function setChroma(value)
{
	if (chromaShader == null)
		return;
	chromaShader.setFloat("rOffset", value);
	chromaShader.setFloat("bOffset", -value);
}
