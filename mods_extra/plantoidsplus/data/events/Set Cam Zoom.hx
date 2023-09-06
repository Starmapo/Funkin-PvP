var camTween:FlxTween;

function onEvent(event, params)
{
	if (event == "Set Cam Zoom")
	{
		var zoom = Std.parseFloat(params[0]);
		if (params[1] == null || params[1].length < 1)
			state.defaultCamZoom = zoom;
		else
		{
			if (camTween != null)
				camTween.cancel();
			camTween = FlxTween.tween(FlxG.camera, {zoom: zoom}, Std.parseFloat(params[1]), {ease: FlxEase.sineInOut, onComplete: function(_)
			{
				state.defaultCamZoom = zoom;
				camTween = null;
			}});
		}
	}
}