import flixel.FlxGame;

// FROM CODENAME ENGINE
class FNFGame extends FlxGame
{
	var skipNextTickUpdate:Bool = false;

	override function switchState()
	{
		super.switchState();
		draw();
		_total = ticks = getTicks();
		skipNextTickUpdate = true;
	}

	override function onEnterFrame(t)
	{
		if (skipNextTickUpdate)
			_total = ticks = getTicks();
		skipNextTickUpdate = false;
		super.onEnterFrame(t);
	}
}
