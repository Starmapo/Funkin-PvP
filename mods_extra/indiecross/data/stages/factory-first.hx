var brightShader:FlxRuntimeShader;
var defaultBrightVal:Float = 0;
var brightSpeed:Float = 0;
var brightMagnitude:Float = 0;
var video:FlxVideoSprite;

function onCreatePost()
{
	if (!Settings.lowQuality && !Settings.flashing)
		light.animation.pause();
	
	if (!Settings.lowQuality)
	{
		video = createVideoSprite(0, 0, "bendy/1.5");
		video.pause();
		video.scrollFactor.set();
		video.cameras = [camHUD];
		video.alpha = 0.00001;
		video.bitmap.onEndReached.add(function() {
			video = null;
		});
		addBehindUI(video);
	}
	
	if (Settings.shaders)
	{
		brightShader = getShader("bright");
		brightShader.setFloat("contrast", 1);
		FlxG.camera.addShader(brightShader);
	}
	
	if (bf.info.name == "bf-bendo" && bf.info.mod == modID)
		precacheCharacter("bfwhoareyou");
}

function onUpdatePost(elapsed)
{
	if (brightSpeed != 0)
		setBrightness(defaultBrightVal + Math.sin((timing.audioPosition / 1000) * (timing.curTimingPoint != null ? (timing.curTimingPoint.bpm / 60) : 1) * brightSpeed) * brightMagnitude);
	else
		setBrightness(defaultBrightVal);
}

function onCharFocus(char)
{
	if (char == opponent && !opponent.visible)
		camFollow.setPosition(bendo.x + (bendo.width / 2), bendo.y + (bendo.height / 2));
}

function onPause(player)
{
	if (video != null && video.alpha == 1)
		video.pause();
}

function onResume()
{
	if (video != null && video.alpha == 1)
		video.resume();
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Start Video":
			state.iconBop = state.camBop = false;
			if (!Settings.lowQuality)
				remove(light);
			if (video != null)
			{
				video.resume();
				video.alpha = 1;
			}
		case "Change BG":
			opponent.visible = true;
			bg.visible = bendo.visible = false;
			if (!Settings.lowQuality)
				speaker.visible = false;
			postDemise.alpha = 1;
			if (!Settings.lowQuality)
				pillar.visible = false;
			if (bf.info.name == "bf-bendo" && bf.info.mod == modID)
				bf.changeCharacter("bfwhoareyou");
		case "After Video":
			state.iconBop = state.camBop = true;
			defaultBrightVal = -0.05;
			brightSpeed = 0.5;
			brightMagnitude = 0.05;
	}
}

function setBrightness(value)
{
	if (brightShader != null)
		brightShader.setFloat("brightness", value);
}