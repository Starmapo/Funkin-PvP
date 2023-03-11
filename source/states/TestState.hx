package states;

import flixel.FlxG;
import flixel.text.FlxText;
import sprites.AnimatedSprite;

class TestState extends FNFState
{
	var sprite:AnimatedSprite;
	var text:FlxText;

	override function create()
	{
		transIn = transOut = null;

		sprite = new AnimatedSprite(0, 0, Paths.getSpritesheet('menus/options/checkboxThingie'), 0.7);
		sprite.addAnim({
			name: 'static',
			atlasName: 'Check Box unselected',
			loop: false
		}, true);
		sprite.screenCenter();
		add(sprite);

		text = new FlxText();
		updateText();
		add(text);

		super.create();
	}

	override function update(elapsed:Float)
	{
		var mult = FlxG.keys.pressed.SHIFT ? 10 : 1;
		if (FlxG.keys.justPressed.LEFT)
		{
			sprite.frames.addFrameOffset(sprite.frame.name, -1 * mult);
		}
		else if (FlxG.keys.justPressed.RIGHT)
		{
			sprite.frames.addFrameOffset(sprite.frame.name, 1 * mult);
		}
		if (FlxG.keys.justPressed.UP)
		{
			sprite.frames.addFrameOffset(sprite.frame.name, 0, -1 * mult);
		}
		else if (FlxG.keys.justPressed.DOWN)
		{
			sprite.frames.addFrameOffset(sprite.frame.name, 0, 1 * mult);
		}
		updateText();

		super.update(elapsed);
	}

	function updateText()
	{
		text.text = '${sprite.frame.offset}';
	}
}
