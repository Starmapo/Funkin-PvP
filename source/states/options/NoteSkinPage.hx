package states.options;

import data.Mods;
import data.PlayerConfig;
import data.PlayerSettings;
import data.Settings;
import data.skin.NoteSkin;
import data.song.NoteInfo;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import ui.game.Note;
import ui.game.Receptor;
import ui.lists.MenuList.TypedMenuList;
import ui.lists.TextMenuList;

class NoteSkinPage extends Page
{
	var player:Int = 0;
	var categoryList:CategoryList;
	var skinList:NoteSkinList;
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

		categoryList = new CategoryList();
		categoryList.onChange.add(onChangeCategory);
		categoryList.onAccept.add(onAcceptCategory);

		skinList = new NoteSkinList();
		skinList.onChange.add(onChangeSkin);
		skinList.onAccept.add(onAcceptSkin);
		skinList.controlsEnabled = false;

		add(skinList);
		add(categoryList);

		var groups:Array<ModSkins> = [];
		for (_ => group in Mods.skins)
		{
			if (group.noteskins.length > 0)
				groups.push(group);
		}
		groups.sort(function(a, b)
		{
			var nameA = a.name.toLowerCase();
			var nameB = b.name.toLowerCase();
			if (nameA < nameB)
				return FlxSort.ASCENDING;
			else if (nameA > nameB)
				return -FlxSort.ASCENDING;
			return 0;
		});

		for (group in groups)
			categoryList.createItem(group);

		categoryList.selectItem(0);
	}

	override function destroy()
	{
		super.destroy();
		categoryList = null;
		skinList = null;
		config = null;
	}

	override function updateControls()
	{
		if (PlayerSettings.checkAction(BACK_P))
		{
			if (skinList.visible)
			{
				skinList.visible = skinList.controlsEnabled = false;
				categoryList.visible = categoryList.controlsEnabled = true;
				updateCamFollow(categoryList.selectedItem);
			}
			else
				exit();
			CoolUtil.playCancelSound();
		}
	}

	override function onAppear()
	{
		updateCamFollow(categoryList.selectedItem);
	}

	function updateCamFollow(item:TextMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}

	function onChangeCategory(item:CategoryItem)
	{
		updateCamFollow(item);
	}

	function onAcceptCategory(item:CategoryItem)
	{
		reloadSkins(item.skins);
		categoryList.visible = categoryList.controlsEnabled = false;
		skinList.visible = skinList.controlsEnabled = true;
		CoolUtil.playScrollSound();
	}

	function onChangeSkin(item:NoteSkinItem)
	{
		updateCamFollow(item);
		reloadSkin(item);
	}

	function onAcceptSkin(item:NoteSkinItem)
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

	function reloadSkins(skins:ModSkins)
	{
		skinList.destroyMembers();
		lastSkin = null;
		for (skin in skins.noteskins)
		{
			var item = skinList.createItem(skin);
			if (skin.mod + ':' + skin.name == config.noteSkin)
			{
				item.color = FlxColor.LIME;
				lastSkin = item;
			}
		}
		skinList.selectItem(0);
	}
}

class CategoryList extends TypedMenuList<CategoryItem>
{
	public function createItem(skins:ModSkins)
	{
		var item = new CategoryItem(0, length * 100, skins);
		item.x = ((FlxG.width / 2 - item.width) / 2);
		return addItem(item.name, item);
	}
}

class CategoryItem extends TextMenuItem
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

class NoteSkinList extends TypedMenuList<NoteSkinItem>
{
	public function createItem(skin:ModNoteSkin)
	{
		var item = new NoteSkinItem(0, length * 100, skin);
		item.x = ((FlxG.width / 2 - item.width) / 2);
		return addItem(item.name, item);
	}
}

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
