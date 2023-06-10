package states.pvp;

import flixel.util.FlxStringUtil;
import data.Mods;
import data.PlayerSettings;
import data.Settings;
import data.song.Song;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapDataChannel;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import ui.HealthIcon;
import ui.lists.MenuList;
import ui.lists.TextMenuList;
import util.DiscordClient;

class SongSelectState extends FNFState
{
	public static var song:Song = null;

	public var transitioning:Bool = true;

	var camPlayers:Array<FlxCamera> = [];
	var camDivision:FlxCamera;
	var camScroll:FlxCamera;
	var camOver:FlxCamera;
	var playerGroups:FlxTypedGroup<PlayerSongSelect>;
	var iconScroll:FlxBackdrop;
	var stateText:FlxText;

	override function create()
	{
		DiscordClient.changePresence(null, "Song Select");

		transIn = transOut = null;
		persistentUpdate = true;

		var players = Settings.singleSongSelection ? 1 : 2;
		for (i in 0...players)
		{
			var camPlayer = new FlxCamera(Std.int((FlxG.width / 2) * i), 0, Std.int(FlxG.width / players));
			camPlayer.bgColor = 0;
			camPlayers.push(camPlayer);
			FlxG.cameras.add(camPlayer, false);
		}

		if (!Settings.singleSongSelection)
		{
			camDivision = new FlxCamera(Std.int((FlxG.width / 2) - 1), 0, 3);
			camDivision.bgColor = FlxColor.WHITE;
			FlxG.cameras.add(camDivision, false);
		}

		camScroll = new FlxCamera();
		camScroll.bgColor = FlxColor.fromRGBFloat(0, 0, 0, 0.5);
		FlxG.cameras.add(camScroll, false);
		camOver = new FlxCamera();
		camOver.bgColor = 0;
		FlxG.cameras.add(camOver, false);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF21007F;
		add(bg);

		playerGroups = new FlxTypedGroup();
		add(playerGroups);

		var groups = [];
		for (_ => group in Mods.songGroups)
			groups.push(group);
		groups.sort(function(a, b)
		{
			return CoolUtil.sortAlphabetically(a.name, b.name);
		});
		for (i in 0...players)
			playerGroups.add(new PlayerSongSelect(i, camPlayers[i], this, groups));

		stateText = new FlxText(0, 0, 0, 'Song Selection');
		stateText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		stateText.screenCenter(X);
		stateText.scrollFactor.set();
		stateText.cameras = [camOver];
		camScroll.height = Math.ceil(stateText.height);
		stateText.y = camScroll.y -= camScroll.height;

		iconScroll = new FlxBackdrop(Paths.getImage('menus/pvp/iconScroll'));
		iconScroll.alpha = 0.5;
		iconScroll.cameras = [camScroll];
		iconScroll.velocity.set(25, 25);
		iconScroll.scale.set(0.5, 0.5);
		iconScroll.antialiasing = true;

		add(iconScroll);
		add(stateText);

		for (cam in camPlayers)
			cam.zoom = 3;
		var duration = Main.getTransitionTime();
		FlxTween.tween(camScroll, {y: 0}, duration, {ease: FlxEase.expoOut});
		FlxTween.tween(FlxG.camera, {zoom: 1}, duration, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				for (group in playerGroups)
					group.setControlsEnabled(true);
			}
		});
		camOver.fade(FlxColor.BLACK, duration, true, null, true);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// prevent overflow (it would probably take an eternity for that to happen but you can never be too safe)
		if (iconScroll.x >= 300)
			iconScroll.x %= 300;
		if (iconScroll.y >= 300)
			iconScroll.y %= 300;

		if (!transitioning)
		{
			var ready = true;
			for (player in playerGroups)
			{
				if (!player.ready)
				{
					ready = false;
					break;
				}
			}
			if (ready)
			{
				reloadSong();
				exitTransition(function(_)
				{
					FlxG.switchState(new CharacterSelectState());
				});
			}
		}

		stateText.y = camScroll.y;
		for (cam in camPlayers)
			cam.zoom = FlxG.camera.zoom;
	}

	override function destroy()
	{
		super.destroy();
		camPlayers = null;
		camDivision = null;
		camScroll = null;
		camOver = null;
		playerGroups = null;
		iconScroll = null;
		stateText = null;
	}

	public function exitTransition(onComplete:FlxTween->Void)
	{
		transitioning = true;
		for (group in playerGroups)
			group.setControlsEnabled(false);
		var duration = Main.getTransitionTime();
		FlxTween.tween(camScroll, {y: -camScroll.height}, duration / 2, {ease: FlxEase.expoIn});
		FlxTween.tween(FlxG.camera, {zoom: 5}, duration, {
			ease: FlxEase.expoIn,
			onComplete: onComplete
		});
		camOver.fade(FlxColor.BLACK, duration, false, null, true);
	}

	function reloadSong()
	{
		var group = playerGroups.members[FlxG.random.int(0, playerGroups.length - 1)];
		var data = group.songMenuList.selectedItem.songData;
		var difficulty = group.difficultyMenuList.selectedItem.difficulty;
		song = Song.loadSong(data.name + '/' + difficulty, data.directory);

		if (Settings.noLongNotes)
			song.replaceLongNotesWithRegularNotes();
		if (Settings.inverse)
			song.applyInverse();
		if (Settings.fullLongNotes)
		{
			song.replaceLongNotesWithRegularNotes();
			song.applyInverse();
		}
		if (Settings.mirrorNotes)
			song.mirrorNotes();
		if (Settings.randomize)
			song.randomizeLanes();
	}
}

class PlayerSongSelect extends FlxGroup
{
	static var lastSelectedGroups:Array<Int> = [0, 0];
	static var lastSelectedSongs:Array<Int> = [0, 0];
	static var lastSelectedDiffs:Array<Int> = [0, 0];
	static var lastScreens:Array<Int> = [0, 0];

	public var viewing:Int = 0;
	public var ready:Bool = false;
	public var groupMenuList:SongGroupMenuList;
	public var songMenuList:SongMenuList;
	public var difficultyMenuList:DifficultyMenuList;

	var player:Int = 0;
	var state:SongSelectState;
	var camFollow:FlxObject;
	var lastGroupReset:String = '';
	var lastSongReset:String = '';

	public function new(player:Int, camera:FlxCamera, state:SongSelectState, groups:Array<ModSongGroup>)
	{
		super();
		this.player = player;
		this.state = state;
		cameras = [camera];

		camFollow = new FlxObject(FlxG.width / (Settings.singleSongSelection ? 2 : 4));
		camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);

		var controlsMode:ControlsMode = (Settings.singleSongSelection ? ALL : PLAYER(player));

		groupMenuList = new SongGroupMenuList(player, controlsMode);
		groupMenuList.singleSongSelection = Settings.singleSongSelection;
		groupMenuList.onChange.add(onGroupChange);
		groupMenuList.onAccept.add(onGroupAccept);

		for (group in groups)
			groupMenuList.createItem(group);
		groupMenuList.afterInit();

		songMenuList = new SongMenuList(player, controlsMode);
		songMenuList.onChange.add(onSongChange);
		songMenuList.onAccept.add(onSongAccept);
		songMenuList.controlsEnabled = false;

		difficultyMenuList = new DifficultyMenuList(player, controlsMode);
		difficultyMenuList.onChange.add(onDiffChange);
		difficultyMenuList.onAccept.add(onDiffAccept);
		difficultyMenuList.controlsEnabled = false;

		add(difficultyMenuList);
		add(songMenuList);
		add(groupMenuList);

		groupMenuList.selectItem(lastSelectedGroups[player]);

		songMenuList.resetGroup(groupMenuList.selectedItem);
		lastGroupReset = groupMenuList.selectedItem.name;
		songMenuList.selectItem(lastSelectedSongs[player]);

		difficultyMenuList.resetSong(songMenuList.selectedItem);
		lastSongReset = songMenuList.selectedItem.name;
		difficultyMenuList.selectItem(lastSelectedDiffs[player]);

		switch (lastScreens[player])
		{
			case 1:
				groupAccept(groupMenuList.selectedItem);
			case 2:
				groupAccept(groupMenuList.selectedItem);
				songAccept(songMenuList.selectedItem);
			default:
				updateCamFollow(groupMenuList.selectedItem);
		}

		camera.snapToTarget();

		setControlsEnabled(false);
	}

	override function update(elapsed:Float)
	{
		var back = (Settings.singleSongSelection ? PlayerSettings.checkAction(BACK_P) : PlayerSettings.checkPlayerAction(player, BACK_P));
		if (!state.transitioning && back)
		{
			if (ready)
			{
				var item = difficultyMenuList.selectedItem;
				FlxTween.cancelTweensOf(item);
				FlxTween.color(item, 0.5, item.color, FlxColor.WHITE);
				ready = false;
				difficultyMenuList.controlsEnabled = true;
			}
			else if (viewing == 1)
			{
				groupMenuList.controlsEnabled = true;
				songMenuList.controlsEnabled = false;
				camFollow.x = FlxG.width * (Settings.singleSongSelection ? 0.5 : 0.25);
				updateCamFollow(groupMenuList.selectedItem);
				viewing = 0;
				lastScreens[player] = viewing;
			}
			else if (viewing == 2)
			{
				songMenuList.controlsEnabled = true;
				difficultyMenuList.controlsEnabled = false;
				camFollow.x = FlxG.width * (Settings.singleSongSelection ? 1.5 : 0.75);
				updateCamFollow(songMenuList.selectedItem.text);
				viewing = 1;
				lastScreens[player] = viewing;
			}
			else
			{
				state.exitTransition(function(_)
				{
					FlxG.switchState(new RulesetState());
				});
			}
			CoolUtil.playCancelSound();
		}

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
		groupMenuList = null;
		songMenuList = null;
		difficultyMenuList = null;
		state = null;
		camFollow = null;
	}

	public function setControlsEnabled(value:Bool)
	{
		if (viewing == 1)
			songMenuList.controlsEnabled = value;
		else if (viewing == 2)
			difficultyMenuList.controlsEnabled = value;
		else
			groupMenuList.controlsEnabled = value;
	}

	function onGroupChange(item:SongGroupMenuItem)
	{
		updateCamFollow(item);
		lastSelectedGroups[player] = item.ID;
	}

	function onGroupAccept(item:SongGroupMenuItem)
	{
		groupAccept(item);
		CoolUtil.playScrollSound();
	}

	function groupAccept(item:SongGroupMenuItem)
	{
		groupMenuList.controlsEnabled = false;
		songMenuList.controlsEnabled = true;
		camFollow.x = FlxG.width * (Settings.singleSongSelection ? 1.5 : 0.75);
		if (lastGroupReset != item.name)
		{
			songMenuList.resetGroup(item);
			songMenuList.selectItem(0);
			lastGroupReset = item.name;
		}
		else
			updateCamFollow(songMenuList.selectedItem.text);
		viewing = 1;
	}

	function updateCamFollow(item:FlxSprite)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}

	function onSongChange(item:SongMenuItem)
	{
		updateCamFollow(item.text);
		lastSelectedSongs[player] = item.ID;
	}

	function onSongAccept(item:SongMenuItem)
	{
		songAccept(item);
		CoolUtil.playScrollSound();
	}

	function songAccept(item:SongMenuItem)
	{
		songMenuList.controlsEnabled = false;
		difficultyMenuList.controlsEnabled = true;
		camFollow.x = FlxG.width * (Settings.singleSongSelection ? 2.5 : 1.25);
		if (lastSongReset != item.name)
		{
			difficultyMenuList.resetSong(item);
			difficultyMenuList.selectItem(0);
			lastSongReset = item.name;
		}
		else
			updateCamFollow(difficultyMenuList.selectedItem);
		viewing = 2;
		lastScreens[player] = viewing;
	}

	function onDiffChange(item:DifficultyMenuItem)
	{
		updateCamFollow(item);
		lastSelectedDiffs[player] = item.ID;
	}

	function onDiffAccept(item:DifficultyMenuItem)
	{
		ready = true;
		difficultyMenuList.controlsEnabled = false;
		FlxTween.cancelTweensOf(item);
		FlxTween.color(item, 0.5, item.color, FlxColor.LIME);
		CoolUtil.playConfirmSound();
	}
}

class SongGroupMenuList extends TypedMenuList<SongGroupMenuItem>
{
	public var singleSongSelection:Bool = false;

	var player:Int = 0;
	var columns:Int = 4;
	var gridSize:Int = 158;
	var singleOffset:Float;
	var doubleOffset:Float;

	public function new(player:Int, controlsMode:ControlsMode)
	{
		super(COLUMNS(columns), controlsMode);
		this.player = player;

		var columnWidth = gridSize * 4;
		singleOffset = (FlxG.width - columnWidth) / 2;
		doubleOffset = ((FlxG.width / 2) - columnWidth) / 2;
	}

	public function createItem(groupData:ModSongGroup)
	{
		var name = groupData.name;
		var item = new SongGroupMenuItem(gridSize * (length % columns), gridSize * Math.floor(length / columns), name, groupData);

		if (singleSongSelection)
			item.x += singleOffset;
		else
			item.x += doubleOffset;

		return addItem(name, item);
	}

	public function afterInit()
	{
		var num = length % columns;
		if (num != 0)
		{
			var offset = ((gridSize * 4) - (gridSize * num)) / 2;
			for (i in length - num...length)
				members[i].x += offset;
		}
	}
}

class SongGroupMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	public var groupData:ModSongGroup;

	var bg:FlxSprite;

	public function new(x:Float = 0, y:Float = 0, name:String, groupData:ModSongGroup)
	{
		this.groupData = groupData;

		var label = new FlxSpriteGroup();

		super(x, y, label, name);

		bg = new FlxSprite().loadGraphic(getBGGraphic(groupData.name));
		bg.antialiasing = true;
		label.add(bg);

		setEmptyBackground();
	}

	override function destroy()
	{
		super.destroy();
		groupData = null;
		bg = null;
	}

	function getBGGraphic(name:String)
	{
		name = FlxStringUtil.validate(name);
		var graphicKey = name + '_edit';
		if (FlxG.bitmap.checkCache(graphicKey))
			return FlxG.bitmap.get(graphicKey);

		var thickness = 4;

		var graphic = Paths.getImage('bg/$name', groupData.directory, false, true, graphicKey);
		if (graphic == null)
			graphic = Paths.getImage('bg/unknown', '', false, true, graphicKey);

		var text = new FlxText(0, graphic.height - thickness, graphic.width, groupData.name);
		text.setFormat('VCR OSD Mono', 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		text.updateHitbox();
		text.y -= text.height;

		var textBG = new FlxSprite(text.x, text.y).makeGraphic(Std.int(text.width), Std.int(graphic.height - text.y), FlxColor.GRAY);
		graphic.bitmap.copyPixels(textBG.pixels, new Rectangle(0, 0, textBG.width, textBG.height), new Point(textBG.x, textBG.y), null, null, true);
		textBG.destroy();

		graphic.bitmap.copyPixels(text.pixels, new Rectangle(0, 0, text.width, text.height), new Point(text.x, text.y), null, null, true);
		text.destroy();

		var mask = FlxG.bitmap.get('groupMask');
		if (mask == null)
		{
			var sprite = new FlxSprite().makeGraphic(158, 158, FlxColor.TRANSPARENT, false, 'groupMask');
			FlxSpriteUtil.drawRoundRect(sprite, 0, 0, sprite.width, sprite.height, 20, 20, FlxColor.BLACK);
			mask = sprite.graphic;
			mask.destroyOnNoUse = false;
			sprite.destroy();
		}

		graphic.bitmap.copyChannel(mask.bitmap, new Rectangle(0, 0, mask.width, mask.height), new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);

		var outline = FlxG.bitmap.get('groupOutline');
		if (outline == null)
		{
			var sprite = new FlxSprite().makeGraphic(158, 158, FlxColor.TRANSPARENT, false, 'groupOutline');
			FlxSpriteUtil.drawRoundRect(sprite, 0, 0, sprite.width, sprite.height, 20, 20, FlxColor.TRANSPARENT,
				{thickness: thickness, color: FlxColor.WHITE});
			outline = sprite.graphic;
			outline.destroyOnNoUse = false;
			sprite.destroy();
		}

		graphic.bitmap.copyPixels(outline.bitmap, new Rectangle(0, 0, outline.width, outline.height), new Point(), null, null, true);

		return graphic;
	}
}

class SongMenuList extends TypedMenuList<SongMenuItem>
{
	var player:Int = 0;

	public function new(player:Int, controlsMode:ControlsMode)
	{
		super(VERTICAL, controlsMode);
		this.player = player;
	}

	public function createItem(songData:ModSong, y:Float)
	{
		var name = songData.directory + songData.name;
		var item = new SongMenuItem(0, y, name, songData);
		if (Settings.singleSongSelection)
			item.x = FlxG.width + ((FlxG.width - item.width) / 2);
		else
			item.x = (FlxG.width / 2) + (((FlxG.width / 2) - item.width) / 2);
		item.y -= item.text.height / 2;
		byName[name] = item;
		item.ID = length;
		return item;
	}

	public function resetGroup(groupItem:SongGroupMenuItem)
	{
		var songGroup = groupItem.groupData;
		var midpoint = groupItem.getMidpoint();
		destroyMembers();
		for (song in songGroup.songs)
		{
			var item = createItem(song, (midpoint.y + (160 * length)));
			addItem(item.name, item);
		}
		midpoint.put();
	}
}

class SongMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	public var songData:ModSong;
	public var text:FlxText;
	public var icon:HealthIcon;

	var maxWidth:Float = (FlxG.width * (Settings.singleSongSelection ? 1 : 0.5)) - 15;

	public function new(x:Float = 0, y:Float = 0, name:String, songData:ModSong)
	{
		var label = new FlxSpriteGroup();

		super(x, y, label, name, callback);
		this.songData = songData;

		text = new FlxText(0, 0, 0, songData.name);
		text.setFormat('PhantomMuff 1.5', 65, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		text.antialiasing = true;
		label.add(text);

		icon = new HealthIcon(0, text.height / 2, songData.icon);
		icon.y -= (icon.height / 2);
		label.add(icon);
		maxWidth -= icon.width;

		if (text.width > maxWidth)
		{
			var ratio = maxWidth / text.width;
			text.size = Math.floor(text.size * ratio);
		}
		icon.x = text.width + 5;

		setEmptyBackground();
	}

	override function destroy()
	{
		super.destroy();
		songData = null;
		text = null;
		icon = null;
	}
}

class DifficultyMenuList extends TypedMenuList<DifficultyMenuItem>
{
	var player:Int = 0;

	public function new(player:Int, controlsMode:ControlsMode)
	{
		super(VERTICAL, controlsMode);
		this.player = player;
	}

	public function createItem(diff:String, songData:ModSong, y:Float)
	{
		var name = songData.directory + songData.name + diff;
		var item = new DifficultyMenuItem(0, y, name, diff, songData);
		if (Settings.singleSongSelection)
			item.x = FlxG.width * 2 + ((FlxG.width - item.width) / 2);
		else
			item.x = FlxG.width + (((FlxG.width / 2) - item.width) / 2);
		item.y -= item.height / 2;
		byName[name] = item;
		return item;
	}

	public function resetSong(songItem:SongMenuItem)
	{
		var songData = songItem.songData;
		var midpoint = songItem.getMidpoint();
		destroyMembers();
		for (diff in songData.difficulties)
		{
			var item = createItem(diff, songData, (midpoint.y + (100 * length)));
			addItem(item.name, item);
		}
		midpoint.put();
	}
}

class DifficultyMenuItem extends TextMenuItem
{
	public var songData:ModSong;
	public var difficulty:String;

	var maxWidth:Float = (FlxG.width * (Settings.singleSongSelection ? 1 : 0.5)) - 10;

	public function new(x:Float = 0, y:Float = 0, name:String, difficulty:String, songData:ModSong)
	{
		super(x, y, name, callback);
		this.songData = songData;
		this.difficulty = difficulty;

		label.text = difficulty;
		if (label.width > maxWidth)
		{
			var ratio = maxWidth / label.width;
			label.size = Math.floor(label.size * ratio);
		}
	}

	override function destroy()
	{
		super.destroy();
		songData = null;
	}
}
