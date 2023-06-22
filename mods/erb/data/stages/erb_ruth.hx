var video:FlxVideoSprite;
function onCreatePost()
{
	video = createVideoSprite(0, 0, songName);
	video.pause();
	video.cameras = [camHUD];
	video.scrollFactor.set();
	video.bitmap.mute = true;
	video.alpha = 0.00001;
	addBehindUI(video);
	
	var blackBar = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 60, FlxColor.BLACK);
	blackBar.y -= blackBar.height;
	blackBar.cameras = [camHUD];
	blackBar.scrollFactor.set();
	addBehindUI(blackBar);
}

function onStartSong()
{
	video.resume();
	video.alpha = 1;
}

function onEndSong()
{
	video.destroy();
}

function onPause(_)
{
	video.pause();
}

function onResume()
{
	video.resume();
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Stop Video":
			video.stop();
			video.visible = false;
	}
}

function onSetTime(time)
{
	video.bitmap.time = Math.round(time);
}