package states.options;

import data.Mods;
import data.PlayerConfig;
import data.Settings;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.lists.MenuList.TypedMenuList;
import ui.lists.TextMenuList;

class NoteSkinPage extends Page
{
	var player:Int = 0;
	var items:NoteSkinList;
	var config:PlayerConfig;
	var lastSkin:NoteSkinItem;

	public function new(player:Int)
	{
		super();
		this.player = player;
		config = Settings.playerConfigs[player];
		rpcDetails = 'Player ${player + 1} Noteskin';

		items = new NoteSkinList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);

		for (skin in Mods.noteSkins)
		{
			var item = createItem(skin);
			if (config.noteSkin == item.name)
			{
				item.color = FlxColor.LIME;
				lastSkin = item;
			}
		}
	}

	override function destroy()
	{
		super.destroy();
		items = null;
		config = null;
	}

	override function onAppear()
	{
		updateCamFollow(items.selectedItem);
	}

	function createItem(skin:ModNoteSkin)
	{
		var item = new NoteSkinItem(0, items.length * 100, skin);
		item.x = ((FlxG.width / 2 - item.width) / 2);
		return items.addItem(item.name, item);
	}

	function updateCamFollow(item:NoteSkinItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}

	function onChange(item:NoteSkinItem)
	{
		updateCamFollow(item);
	}

	function onAccept(item:NoteSkinItem)
	{
		if (lastSkin == item)
			return;

		if (lastSkin != null)
		{
			FlxTween.cancelTweensOf(lastSkin);
			FlxTween.color(lastSkin, 0.5, lastSkin.color, FlxColor.WHITE);
		}
		config.noteSkin = item.name;
		FlxTween.cancelTweensOf(item);
		FlxTween.color(item, 0.5, item.color, FlxColor.LIME);
		lastSkin = item;
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
		super(x, y, skin.mod + ':' + skin.name, null);

		label.text = skin.displayName;
		if (label.width > maxWidth)
		{
			var ratio = maxWidth / label.width;
			label.size = Math.floor(label.size * ratio);
		}
	}
}
