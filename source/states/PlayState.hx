package states;

import flixel.FlxState;
import flixel.text.FlxText;

class PlayState extends FlxState
{
	var text:FlxText;

	override public function create()
	{
		text = new FlxText(0, 0, 0, '');
		add(text);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
