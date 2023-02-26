package ui;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.MenuList;

typedef TextMenuList = TypedMenuList<TextMenuItem>;

class TextMenuItem extends TypedMenuItem<FlxText>
{
	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void, size:Int = 65)
	{
		var label = new FlxText(0, 0, 0, name, size);
		label.setFormat('PhantomMuff 1.5', size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);

		super(x, y, label, name, callback);
		setEmptyBackground();
	}

	override function get_width()
	{
		if (label != null)
		{
			label.updateHitbox();
			return label.width;
		}

		return width;
	}

	override function get_height()
	{
		if (label != null)
		{
			label.updateHitbox();
			return label.height;
		}

		return height;
	}
}
