package states.options;

import data.Mods;
import data.PlayerConfig;
import data.Settings;
import data.skin.NoteSkin;
import data.song.NoteInfo;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import ui.game.Note;
import ui.game.Receptor;
import ui.lists.MenuList.TypedMenuList;
import ui.lists.TextMenuList;

class NoteSkinPage extends Page
{
	var player:Int = 0;
	var items:NoteSkinList;
	var config:PlayerConfig;
	var lastSkin:NoteSkinItem;
	var skinGroup:FlxTypedGroup<FlxSprite>;
	var bg:FlxSprite;

	public function new(player:Int)
	{
		super();
		this.player = player;
		config = Settings.playerConfigs[player];
		rpcDetails = 'Player ${player + 1} Noteskin';

		skinGroup = new FlxTypedGroup();
		add(skinGroup);

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.fromRGBFloat(0, 0, 0, 0.6));
		bg.setGraphicSize(FlxG.width / 2, FlxG.height);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		items = new NoteSkinList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);

		var found = false;
		for (skin in Mods.noteSkins)
		{
			var item = createItem(skin);
			if (config.noteSkin == item.name)
			{
				item.color = FlxColor.LIME;
				lastSkin = item;
				items.selectItem(item.ID);
				found = true;
			}
		}
		if (!found)
			reloadSkin(items.selectedItem);
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
		reloadSkin(item);
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

	function reloadSkin(item:NoteSkinItem)
	{
		skinGroup.destroyMembers();

		var skin = NoteSkin.loadSkinFromName(item.skin.mod + ':' + item.skin.name);
		var curX:Float = FlxG.width / 2;
		var startY = 5;
		var receptors:Array<Receptor> = [];
		for (i in 0...4)
		{
			var receptor = createReceptor(curX, startY + skin.receptorsOffset[1], i, skin, 'static');
			receptors.push(receptor);
			skinGroup.add(receptor);
			var receptorPressed = createReceptor(curX, startY + 150 + skin.receptorsOffset[1], i, skin, 'pressed');
			skinGroup.add(receptorPressed);
			var receptorConfirm = createReceptor(curX, startY + 300 + skin.receptorsOffset[1], i, skin, 'confirm');
			skinGroup.add(receptorConfirm);

			var note = new Note(new NoteInfo({
				lane: i,
				endTime: 200
			}), null, null, skin);
			note.x = curX;
			note.y = startY + 450;
			skinGroup.add(note);

			curX += receptor.width + skin.receptorsPadding;
		}

		var newX = ((FlxG.width / 2) - CoolUtil.getArrayWidth(receptors)) / 2;
		for (obj in skinGroup)
			obj.x += newX;
	}

	function createReceptor(x:Float, y:Float, i:Int, skin:NoteSkin, anim:String)
	{
		var receptor = new Receptor(x, y, i, skin);
		receptor.playAnim(anim);
		if (anim != 'static')
			new FlxTimer().start(0.5, function(tmr)
			{
				if (receptor.exists)
					receptor.playAnim(anim, true);
				else
					tmr.cancel();
			}, 0);
		return receptor;
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
