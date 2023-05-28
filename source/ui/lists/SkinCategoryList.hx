package ui.lists;

import data.Mods.ModSkins;
import flixel.FlxG;
import ui.lists.MenuList.TypedMenuList;
import ui.lists.TextMenuList.TextMenuItem;

class SkinCategoryList extends TypedMenuList<SkinCategoryItem>
{
	public function createItem(skins:ModSkins)
	{
		var item = new SkinCategoryItem(0, length * 100, skins);
		item.x = ((FlxG.width / 2 - item.width) / 2);
		return addItem(item.name, item);
	}
}

class SkinCategoryItem extends TextMenuItem
{
	public var skins:ModSkins;

	var maxWidth:Float = (FlxG.width / 2) - 10;

	public function new(x:Float = 0, y:Float = 0, skins:ModSkins)
	{
		this.skins = skins;
		super(x, y, skins.name, null);

		if (label.width > maxWidth)
		{
			var ratio = maxWidth / label.width;
			label.size = Math.floor(label.size * ratio);
		}
	}
}
