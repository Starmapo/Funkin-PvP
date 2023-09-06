var freakyMachineVideoSpr:FlxVideoSprite;
var baseDadFloat:Float;
var dadFloat:Bool = false;

function onCreatePost()
{
	if (!Settings.lowQuality)
	{
		var videoName:String = 'bgscenephotosensitive';
		if (Settings.flashing)
			videoName = 'bgscene';
			
		freakyMachineVideoSpr = createVideoSprite(0, 0, "bendy/" + videoName, "", true);
		freakyMachineVideoSpr.width = FlxG.width / 4;
		freakyMachineVideoSpr.height = FlxG.height / 4;
		freakyMachineVideoSpr.screenCenter();
		freakyMachineVideoSpr.x -= 600;
		freakyMachineVideoSpr.y -= 250;
		freakyMachineVideoSpr.updateHitbox();
		freakyMachineVideoSpr.blend = BlendMode.ADD;
		freakyMachineVideoSpr.alpha = 0.0001;
		insert(members.indexOf(machineCurtainLeft), freakyMachineVideoSpr);
	}
	
	if (opponent.info.name == "bendyDA" && opponent.info.mod == modID)
		precacheCharacter("bendyDA-alt");
}

function onUpdatePost(elapsed)
{
	if (dadFloat)
		opponent.y = baseDadFloat + Math.sin((timing.audioPosition / 1000) * ((timing.curTimingPoint != null ? timing.curTimingPoint.bpm : 60) / 60) * 2.0) * 10;
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Play Animation":
			if (opponent.animation.name == "indiecross_bendyIsTrans")
				opponent.danceDisabled = true;
		case "Bendy Transition":
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 1, false, function()
				{
					if (opponent.info.name == "bendyDA" && opponent.info.mod == modID)
					{
						opponent.danceDisabled = false;
						opponent.changeCharacter("bendyDA-alt");
						baseDadFloat = opponent.y;
						dadFloat = true;
					}
					if (freakyMachineVideoSpr != null)
						freakyMachineVideoSpr.alpha = 1;
				});
			});
		case "Show":
			FlxG.camera.fade(FlxColor.BLACK, 0, true);
			FlxTween.tween(state, {defaultCamZoom: 0.75}, 0.5, {ease: FlxEase.sineOut});
			FlxTween.tween(machineCurtainLeft, {x: machineCurtainLeft.x - 900}, 0.8, {ease: FlxEase.quadOut});
			FlxTween.tween(machineCurtainRight, {x: machineCurtainRight.x + 900}, 0.8, {ease: FlxEase.quadOut});
	}
}

function onPause()
{
	if (freakyMachineVideoSpr != null)
		freakyMachineVideoSpr.pause();
}

function onResume()
{
	if (freakyMachineVideoSpr != null)
		freakyMachineVideoSpr.resume();
}