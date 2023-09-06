var inkStormRain:FlxSprite;
var inkscroll:FlxTypedGroup<FlxSprite>;
var blackOverlay:FlxSprite;
var piper:FlxSprite;
var fisher:FlxSprite;
var shakeyCam:Bool = false;
var fisherAng:Float = 180;
var fisherX:Float = -700;
var fisherKill = false;
var fisheraaa:Float = 0;
var brightShader:FlxRuntimeShader;
var defaultBrightVal:Float = -0.05;
var brightSpeed:Float = 0.5;
var brightMagnitude:Float = 0.05;

function onCreatePost()
{
	if (songName == "Last Reel")
	{
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
		
		if (!Settings.lowQuality)
		{
			piper = new FlxSprite();
			piper.frames = Paths.getSpritesheet('stages/factory/PiperJumpscare');
			piper.animation.addByPrefix('bruh', 'Fuck uuuu instance 1', 24, false);
			piper.updateHitbox();
			piper.screenCenter();
			piper.scrollFactor.set();
			piper.antialiasing = true;
			piper.alpha = 0.0001;
			piper.cameras = [camHUD];
			addBehindUI(piper);

			fisher = new FlxSprite(-1280);
			fisher.frames = Paths.getSpritesheet('stages/factory/DontmindmeImmajustwalkby');
			fisher.animation.addByPrefix('bruh', 'WalkinFhis instance 1', 24, true);
			fisher.updateHitbox();
			fisher.screenCenter(FlxAxes.Y);
			fisher.scrollFactor.set();
			fisher.antialiasing = true;
			fisher.alpha = 0.0001;
			fisher.cameras = [camHUD];
			addBehindUI(fisher);
			
			Paths.getSound("bendy/boo");
		}
	}
	
	precacheImage("stages/factory/ready");
	precacheImage("stages/factory/set");
	precacheImage("stages/factory/go");
	
	if (Settings.shaders)
	{
		brightShader = getShader("bright");
		brightShader.setFloat("contrast", 1);
		FlxG.camera.addShader(brightShader);
	}
}

function onUpdatePost(elapsed)
{
	if (shakeyCam)
		FlxG.camera.shake(0.1, 0.03 / playbackRate);
		
	if (inkscroll != null)
	{
		for (i in inkscroll)
		{
			i.x += 350 * elapsed * playbackRate;
			if (i.x >= 1280)
				i.x = -i.width;
		}
	}
	
	if (fisher != null)
	{
		if (fisher.alpha >= 0.05)
		{
			var fisherToX = (1280 / 2) + Math.cos(fisherAng * Math.PI / 180) * (1280 / 2);
			fisherX += ((fisherToX - fisherX) / 10) * elapsed * 60 * playbackRate;
			var anothax = fisheraaa;

			if (fisher.animation.curAnim.curFrame > 75)
				fisher.animation.curAnim.curFrame = 0;
			fisher.offset.x = fisher.animation.curAnim.curFrame * 17 + 250;
			fisher.x = fisherX + anothax;
			fisherAng += elapsed * playbackRate * 60 / 1.5;
		}

		if (fisherKill)
		{
			fisheraaa += elapsed * 45 * playbackRate;
			if (fisheraaa >= 325.800000000001)
				fisher.kill();
		}
	}
	
	if (Settings.shaders && brightSpeed != 0)
		setBrightness(defaultBrightVal + Math.sin((timing.audioPosition / 1000) * (timing.curTimingPoint != null ? (timing.curTimingPoint.bpm / 60) : 1) * brightSpeed) * brightMagnitude);
	else
		setBrightness(defaultBrightVal);
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Shakey Cam":
			shakeyCam = !shakeyCam;
		case "Stickman Run":
			if (Settings.lowQuality)
				return;
			stickmanGuy.animation.play("run");
			stickmanGuy.alpha = 1;
			stickmanGuy.animation.finishCallback = function()
			{
				remove(stickmanGuy);
				stickmanGuy.destroy();
			}
		case "Piper Jumpscare":
			if (piper == null)
				return;
			piper.alpha = 1;
			piper.animation.play('bruh', true);
			FlxG.sound.play(Paths.getSound('bendy/boo')).pitch = playbackRate;

			new FlxTimer().start(1.75 / playbackRate, function(tmr:FlxTimer)
			{
				remove(piper);
				piper.destroy();
			});
		case "Ink Storm":
			if (inkStormRain == null)
				return;
			inkStormRain.animation.play('play', true);
			for (inkscroll in inkscroll)
				FlxTween.tween(inkscroll, {alpha: 0.6}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
			FlxTween.tween(inkStormRain, {alpha: 1}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
			FlxTween.tween(blackOverlay, {alpha: 0.33}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
		case "Bendy Boys Tween":
			if (Settings.lowQuality)
				return;
			FlxTween.tween(bendyboysfg, {x: bendyboysfg.x, y: bendyboysfg.y + 300, alpha: 0.0}, 1.5 / playbackRate, {ease: FlxEase.quadOut, onComplete: function(_) {
				remove(bendyboysfg);
				bendyboysfg.destroy();
			}});
		case "Two":
			countdown("ready");
		case "One":
			countdown("set");
		case "Go":
			countdown("go");
		case "Ink Storm Fade":
			if (inkStormRain == null)
				return;
			for (inkscroll in inkscroll)
				FlxTween.tween(inkscroll, {alpha: 0}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
			FlxTween.tween(inkStormRain, {alpha: 0}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
			FlxTween.tween(blackOverlay, {alpha: 0}, 1 / playbackRate, {ease: FlxEase.cubeInOut});
		case "Fisher":
			if (fisher == null)
				return;
			fisher.alpha = 1;
			fisher.animation.play('bruh', true);
			new FlxTimer().start(6 / playbackRate, function(tmr:FlxTimer)
			{
				fisherKill = true;
			});
	}
}

function countdown(name)
{
	var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.getImage("stages/factory/" + name));
	spr.scrollFactor.set();
	spr.updateHitbox();
	spr.cameras = [camHUD];
	spr.screenCenter();
	add(spr);
	FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, timing.curTimingPoint.beatLength / 1000 / playbackRate, {
		ease: FlxEase.cubeInOut,
		onComplete: function(twn:FlxTween)
		{
			remove(spr);
			spr.destroy();
		}
	});
}

function setBrightness(value)
{
	if (brightShader != null)
		brightShader.setFloat("brightness", value);
}