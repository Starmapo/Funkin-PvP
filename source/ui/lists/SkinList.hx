package ui.lists;

import data.Mods.ModSkin;
import flixel.FlxG;
import ui.lists.MenuList.TypedMenuList;
import ui.lists.TextMenuList.TextMenuItem;

class SkinList extends TypedMenuList<SkinItem>
{
	public function createItem(skin:ModSkin)
	{
		var item = new SkinItem(0, length * 100, skin);
		item.x = ((FlxG.width / 2 - item.width) / 2);
		return addItem(item.name, item);
	}
}

class SkinItem extends TextMenuItem
{
	public var skin:ModSkin;
	
	var maxWidth:Float = (FlxG.width / 2) - 10;
	
	public function new(x:Float = 0, y:Float = 0, skin:ModSkin)
	{
		this.skin = skin;
		super(x, y, skin.mod + ':' + skin.name, null);
		
		label.text = skin.displayName;
		if (label.width > maxWidth)
		{
			var ratio = maxWidth / label.width;
			label.size = Math.floor(label.size * ratio);
		}
	}
}
