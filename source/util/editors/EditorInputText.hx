package util.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class EditorInputText extends FlxSpriteGroup
{
	public var text(get, set):String;

	var textBorder:FlxSprite;
	var textBG:FlxSprite;
	var textField:EditorInputTextField;

	public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, size:Int = 8, embeddedFont:Bool = true)
	{
		super(x, y);

		textField = new EditorInputTextField(1, 1, fieldWidth, text, size, embeddedFont);
		textField.color = FlxColor.BLACK;

		textBorder = new FlxSprite().makeGraphic(Std.int(textField.width) + 2, Std.int(textField.height) + 2, FlxColor.BLACK);

		textBG = new FlxSprite(1, 1).makeGraphic(Std.int(textField.width), Std.int(textField.height), FlxColor.WHITE);

		add(textBorder);
		add(textBG);
		add(textField);

		scrollFactor.set();
	}

	function get_text()
	{
		return textField.text;
	}

	function set_text(value:String)
	{
		return textField.text = value;
	}
}

class EditorInputTextField extends FlxText
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

		textField.x = (x - offset.x) * camera.totalScaleX;
		textField.y = (y - offset.y) * camera.totalScaleY;

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
