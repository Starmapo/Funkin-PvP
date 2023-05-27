package states.options;

import data.Mods.ModNoteSkin;
import flixel.FlxG;
import ui.lists.MenuList.TypedMenuList;
import ui.lists.TextMenuList;

class NoteSkinPage extends Page
{
	var player:Int = 0;
	var items:NoteSkinList;

	public function new(player:Int)
	{
		super();
		this.player = player;
		rpcDetails = 'Player ${player + 1} Noteskin';

		items = new NoteSkinList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);
	}

	function createItem(skin:ModNoteSkin)
	{
		var item = new NoteSkinItem(0, items.length * 100, skin);
		return items.addItem(item.name, item);
	}

	function updateCamFollow(item:NoteSkinItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.setPosition(midpoint.x, midpoint.y);
		midpoint.put();
	}

	function onChange(item:NoteSkinItem)
	{
		updateCamFollow(item);
	}

	function onAccept(item:NoteSkinItem)
	{
		CoolUtil.playConfirmSound();
	}
}

class NoteSkinList extends TypedMenuList<NoteSkinItem> {}

class NoteSkinItem extends TextMenuItem
{
	public var skin:ModNoteSkin;

	var maxWidth:Float = (FlxG.width / 2) - 10;

	public function new(x:Float = 0, y:Float = 0, skin:ModNoteSkin)
	{
		this.skin = skin;
		super(x, y, skin.mod + skin.name, null);

		label.text = skin.displayName;
		if (label.width > maxWidth)
		{
			var ratio = maxWidth / label.width;
			label.size = Math.floor(label.size * ratio);
		}
	}
}
