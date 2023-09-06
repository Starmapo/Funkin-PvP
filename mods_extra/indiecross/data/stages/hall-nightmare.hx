var chromaShader:FlxRuntimeShader;
var defaultChromVal:Float = 0;
var chromVal:Float = defaultChromVal;

function onCreatePost()
{
	if (Settings.shaders)
	{
		chromaShader = getShader("chromaticAberration");
		setChroma(chromVal);
		addGameShader(chromaShader);
	}
}

function onUpdatePost(elapsed)
{
	if (Settings.flashing)
		setChroma(chromVal);
}

function onBeatHit(beat, decBeat)
{
	if (beat % 2 == 0)
		beatDropbg.animation.play('beatHit', true);
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

function onEvent(event, params)
{
	switch (event)
	{
		case "Beat Drop":
			nightmareSansBGManager('beatdrop');
		case "Beat Drop Finished":
			nightmareSansBGManager('beatdropFinished');
	}
}

function nightmareSansBGManager(mode:String)
{
	switch (mode)
	{
		case 'normal':
			bg.animation.play('normal', true);
			bg.alpha = 1;
			beatDropbg.alpha = 0;
		case 'beatdrop':
			bg.animation.play('beatdrop', true);
			bg.alpha = 1;
			beatDropbg.alpha = 0;
		case 'beatdropFinished':
			bg.animation.play('beatDropFinish', true);
			bg.alpha = 1;
			beatDropbg.alpha = 1;
	}
}

function setChroma(value)
{
	if (chromaShader == null)
		return;
	chromaShader.setFloat("rOffset", value);
	chromaShader.setFloat("bOffset", -value);
}