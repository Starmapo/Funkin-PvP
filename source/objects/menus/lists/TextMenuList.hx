package objects.menus.lists;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.menus.lists.MenuList;

typedef TextMenuList = TypedMenuList<TextMenuItem>;

class TextMenuItem extends TypedMenuItem<FlxText>
{
	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void, size:Int = 65)
	{
		var label = new FlxText(0, 0, 0, name, size);
		label.setFormat(Paths.FONT_PHANTOMMUFF, size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		label.antialiasing = Settings.antialiasing;
		
		super(x, y, label, name, callback);
		
		setEmptyBackground();
	}
	
	override function setData(name:String, ?callback:Void->Void)
	{
		super.setData(name, callback);
		
		if (label != null)
			label.text = name;
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
