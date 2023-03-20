package util.editors;

import flixel.FlxG;
import flixel.text.FlxText;

class EditorInputText extends FlxText
{
	public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, size:Int = 8, embeddedFont:Bool = true)
	{
		super(x, y, fieldWidth, text, size, embeddedFont);
		scrollFactor.set();
		textField.selectable = true;
		textField.type = INPUT;
		FlxG.game.addChild(textField);
		FlxG.signals.gameResized.add(onGameResized);
	}

	override function draw()
	{
		updateTextField();
	}

	override function destroy()
	{
		FlxG.game.removeChild(textField);
		FlxG.signals.gameResized.remove(onGameResized);
		super.destroy();
	}

	function updateTextField()
	{
		if (textField == null)
			return;

		textField.scaleX = camera.totalScaleX * scale.x;
		textField.scaleY = camera.totalScaleY * scale.y;

		textField.x = (x - offset.x) * textField.scaleX;
		textField.y = (y - offset.y) * textField.scaleY;

		#if !web
		textField.x -= 1;
		textField.y -= 1;
		#end
	}

	function onGameResized(_, _)
	{
		updateTextField();
	}
}
