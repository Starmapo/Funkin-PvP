package util.editors;

import flixel.FlxG;
import flixel.text.FlxText;

class EditorInputText extends FlxText
{
	public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, size:Int = 8, embeddedFont:Bool = true)
	{
		super(x, y, fieldWidth, text, size, embeddedFont);
		textField.selectable = true;
		textField.type = INPUT;
		FlxG.game.addChild(textField);
	}

	override function draw()
	{
		super.draw();

		var position = getGlobalPosition(null, camera);

		textField.x = FlxG.game.x + position.x - offset.x;
		textField.y = FlxG.game.y + position.y - offset.y;

		#if !web
		textField.x -= 1;
		textField.y -= 1;
		#end

		textField.scaleX = camera.totalScaleX * scale.x;
		textField.scaleY = camera.totalScaleY * scale.y;

		textField.x -= 0.5 * camera.width * (camera.scaleX - 1) * FlxG.scaleMode.scale.x;
		textField.y -= 0.5 * camera.height * (camera.scaleY - 1) * FlxG.scaleMode.scale.y;

		position.put();
	}

	override function destroy()
	{
		FlxG.game.removeChild(textField);
		super.destroy();
	}
}
