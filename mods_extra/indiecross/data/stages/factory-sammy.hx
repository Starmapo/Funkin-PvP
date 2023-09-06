var brightShader:FlxRuntimeShader;
var defaultBrightVal:Float = -0.05;
var brightSpeed:Float = 0.5;
var brightMagnitude:Float = 0.05;

function onCreatePost()
{
	if (Settings.shaders)
	{
		brightShader = getShader("bright");
		brightShader.setFloat("contrast", 1);
		FlxG.camera.addShader(brightShader);
	}
}

function onUpdatePost(elapsed)
{
	if (brightSpeed != 0)
		setBrightness(defaultBrightVal + Math.sin((timing.audioPosition / 1000) * (timing.curTimingPoint != null ? (timing.curTimingPoint.bpm / 60) : 1) * brightSpeed) * brightMagnitude);
	else
		setBrightness(defaultBrightVal);
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Tween Camera Alpha":
			FlxTween.tween(FlxG.camera, {alpha: Std.parseFloat(params[0])}, Std.parseFloat(params[1]) / playbackRate);
		case "End Tween":
			if (opponent.animation.exists("indiecross_ritualEnd"))
			{
				new FlxTimer().start((1 / 24) * 31 / playbackRate, function(_)
				{
					opponent.playSpecialAnim("indiecross_ritualEnd");
				});
			}
			new FlxTimer().start(2 / playbackRate, function(_)
			{
				FlxTween.tween(FlxG.camera, {alpha: 0}, 3 / playbackRate);
			});
	}
}

function setBrightness(value)
{
	if (brightShader != null)
		brightShader.setFloat("brightness", value);
}