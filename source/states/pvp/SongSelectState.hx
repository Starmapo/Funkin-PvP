package states.pvp;

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
import lime.app.Future;
import openfl.display.BitmapData;
import sys.thread.Mutex;
import ui.HealthIcon;
import ui.VoidBG;
import ui.lists.MenuList;
import ui.lists.TextMenuList;
import util.DiscordClient;

class SongSelectState extends FNFState
{
	public static var song:Song;
	public static var songData:ModSong;
	public static var canSelectChars:Bool = true;
	
	public var transitioning:Bool = true;
	
	var camPlayers:Array<FlxCamera> = [];
	var camDivision:FlxCamera;
	
	public var camScroll:FlxCamera;
	
	var camOver:FlxCamera;
	var playerGroups:FlxTypedGroup<PlayerSongSelect>;
	var iconScroll:FlxBackdrop;
	var stateText:FlxText;
	
	override function create()
	{
		DiscordClient.changePresence(null, "Song Select");
		SongMenuItem.loadingIcons.clear();
		
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
		
		add(new VoidBG());
		
		playerGroups = new FlxTypedGroup();
		add(playerGroups);
		
		if (Settings.reloadMods)
			Mods.reloadSongs();
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
					if (!canSelectChars)
						FlxG.switchState(new PlayState(song, []));
					else
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
		songData = group.songMenuList.selectedItem.songData;
		canSelectChars = group.canSelectChars;
		
		var difficulty = group.difficultyMenuList.selectedItem.difficulty;
		song = Song.loadSong(songData.name + '/' + difficulty, songData.directory);
		
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
			
		return group;
	}
}

class PlayerSongSelect extends FlxGroup
{
	static var lastSelectedGroups:Array<Int> = [0, 0];
	static var lastSelectedSongs:Array<Int> = [-1, -1];
	static var lastSelectedDiffs:Array<Int> = [-1, -1];
	static var lastScreens:Array<Int> = [0, 0];
	
	public var viewing:Int = 0;
	public var ready:Bool = false;
	public var groupMenuList:SongGroupMenuList;
	public var songMenuList:SongMenuList;
	public var difficultyMenuList:DifficultyMenuList;
	public var canSelectChars:Bool = true;
	
	var player:Int = 0;
	var state:SongSelectState;
	var camFollow:FlxObject;
	var lastGroupReset:String = '';
	var lastSongReset:String = '';
	var screenText:FlxText;
	var warningText:FlxText;
	var warningBG:FlxSprite;
	
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
		
		songMenuList = new SongMenuList(state, player, controlsMode);
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
		
		warningBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		warningBG.scrollFactor.set();
		add(warningBG);
		
		warningText = new FlxText(5, 0, camera.width - 10);
		warningText.setFormat('PhantomMuff 1.5', 32, 0xffff5252, CENTER, OUTLINE, FlxColor.BLACK);
		warningText.scrollFactor.set();
		add(warningText);
		
		screenText = new FlxText(5, 50, camera.width - 10);
		screenText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		screenText.scrollFactor.set();
		screenText.alpha = 0.6;
		add(screenText);
		
		if (lastSelectedGroups[player] >= groupMenuList.length)
			lastSelectedGroups[player] = groupMenuList.length - 1;
		groupMenuList.selectItem(lastSelectedGroups[player]);
		
		var selectedSong = lastSelectedSongs[player];
		if (selectedSong >= 0)
		{
			songMenuList.resetGroup(groupMenuList.selectedItem);
			lastGroupReset = groupMenuList.selectedItem.name;
			
			if (selectedSong >= songMenuList.length)
				selectedSong = songMenuList.length - 1;
			songMenuList.selectItem(selectedSong);
			
			var selectedDiff = lastSelectedDiffs[player];
			if (selectedDiff >= 0)
			{
				difficultyMenuList.resetSong(songMenuList.selectedItem);
				lastSongReset = songMenuList.selectedItem.name;
				
				if (selectedDiff >= difficultyMenuList.length)
					selectedDiff = difficultyMenuList.length - 1;
				difficultyMenuList.selectItem(selectedDiff);
			}
		}
		
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
				updateScreenText();
				viewing = 0;
				lastScreens[player] = viewing;
			}
			else if (viewing == 2)
			{
				songMenuList.controlsEnabled = true;
				difficultyMenuList.controlsEnabled = false;
				camFollow.x = FlxG.width * (Settings.singleSongSelection ? 1.5 : 0.75);
				updateCamFollow(songMenuList.selectedItem.text);
				updateScreenText();
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
		updateScreenText();
		viewing = 1;
		lastScreens[player] = viewing;
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
		updateWarningText();
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
			var lastDiff = difficultyMenuList.selectedItem?.name;
			difficultyMenuList.resetSong(item);
			if (lastDiff != null && difficultyMenuList.hasItem(lastDiff))
				difficultyMenuList.selectItem(difficultyMenuList.getItemByName(lastDiff).ID);
			else
				difficultyMenuList.selectItem(0);
			lastSongReset = item.name;
		}
		else
			updateCamFollow(difficultyMenuList.selectedItem);
		updateScreenText();
		viewing = 2;
		lastScreens[player] = viewing;
	}
	
	function onDiffChange(item:DifficultyMenuItem)
	{
		updateCamFollow(item);
		updateWarningText();
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
	
	function updateScreenText()
	{
		if (difficultyMenuList.controlsEnabled)
			screenText.text = groupMenuList.selectedItem.groupData.name + ' - ' + songMenuList.selectedItem.songData.name;
		else if (songMenuList.controlsEnabled)
			screenText.text = groupMenuList.selectedItem.groupData.name;
		else
			screenText.text = '';
		updateWarningText();
	}
	
	function updateWarningText()
	{
		canSelectChars = true;
		
		var warning = '';
		var item = songMenuList.selectedItem;
		if (item.songData.forceCharacters)
		{
			canSelectChars = false;
			if (songMenuList.controlsEnabled)
				warning = CoolUtil.addMultilineText(warning, "You can't pick characters for this song.");
		}
		
		if (difficultyMenuList.controlsEnabled)
		{
			var item = difficultyMenuList.selectedItem;
			if (item.songData.forceCharacterDifficulties.contains(item.difficulty) && canSelectChars)
			{
				canSelectChars = false;
				warning = CoolUtil.addMultilineText(warning, "You can't pick characters for this difficulty.");
			}
		}
		
		if (warningText.text != warning)
			warningText.text = warning;
		warningText.y = FlxG.height - warningText.height - 5;
		
		if (warning.length > 0)
		{
			warningBG.visible = true;
			warningBG.setGraphicSize(warningText.width + 2, warningText.height + 2);
			warningBG.updateHitbox();
			warningBG.setPosition(warningText.x - 1, warningText.y - 1);
		}
		else
			warningBG.visible = false;
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
		
		bg = new FlxSprite(0, 0, CoolUtil.getGroupGraphic(groupData.name, groupData.directory));
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
}

class SongMenuList extends TypedMenuList<SongMenuItem>
{
	var state:SongSelectState;
	var player:Int = 0;
	
	public function new(state:SongSelectState, player:Int, controlsMode:ControlsMode)
	{
		super(VERTICAL, controlsMode);
		this.state = state;
		this.player = player;
	}
	
	public function createItem(songData:ModSong, y:Float)
	{
		var item = new SongMenuItem(0, y, songData);
		return addItem(item.name, item);
	}
	
	public function resetGroup(groupItem:SongGroupMenuItem)
	{
		var songGroup = groupItem.groupData;
		var midpoint = groupItem.getMidpoint();
		
		for (i in 0...songGroup.songs.length)
		{
			var song = songGroup.songs[i];
			var itemY = (midpoint.y + (160 * i));
			var item = members[i];
			if (item == null)
				item = createItem(song, itemY);
			else
			{
				item.y = itemY;
				byName.remove(item.name);
				item.setSongData(song);
				byName[item.name] = item;
			}
			item.y -= item.text.height / 2;
			if (item.icon != null)
				state.precacheGraphic(item.icon.graphic);
		}
		while (length > songGroup.songs.length)
		{
			var item = remove(members[length - 1], true);
			item.destroy();
		}
		midpoint.put();
	}
}

class SongMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	public static var loadingIcons:Map<String, Future<BitmapData>> = [];
	
	public var songData:ModSong;
	public var text:FlxText;
	public var icon:HealthIcon;
	
	var defaultMaxWidth:Float = (FlxG.width * (Settings.singleSongSelection ? 1 : 0.5)) - 10;
	var maxWidth:Float;
	var iconReady:Bool = false;
	var mutex:Mutex;
	
	public function new(x:Float = 0, y:Float = 0, songData:ModSong)
	{
		var label = new FlxSpriteGroup();
		
		super(x, y, label, null, callback);
		setEmptyBackground();
		
		text = new FlxText();
		text.setFormat('PhantomMuff 1.5', 65, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		text.antialiasing = true;
		text.active = false;
		label.add(text);
		
		setSongData(songData);
	}
	
	public function setSongData(songData:ModSong)
	{
		this.songData = songData;
		maxWidth = defaultMaxWidth;
		
		name = songData.directory + songData.name;
		
		text.text = songData.name;
		
		if (songData.icon.length > 0)
		{
			if (icon == null)
				icon = new HealthIcon(0, 0, songData.icon);
			else
				icon.icon = songData.icon;
			maxWidth -= icon.width + 5;
			label.add(icon);
			icon.y = text.y + (text.height / 2) - (icon.height / 2);
		}
		else if (icon != null)
		{
			label.remove(icon);
			icon.destroy();
			icon = null;
		}
		
		checkMaxWidth();
		if (icon != null)
			icon.x = text.x + text.width + 5;
		reposition();
	}
	
	override function destroy()
	{
		super.destroy();
		songData = null;
		text = null;
		icon = null;
	}
	
	function checkMaxWidth()
	{
		text.size = 65;
		if (text.width > maxWidth)
		{
			var ratio = maxWidth / text.width;
			text.size = Math.floor(text.size * ratio);
		}
	}
	
	function reposition()
	{
		if (Settings.singleSongSelection)
			x = FlxG.width + ((FlxG.width - width) / 2);
		else
			x = (FlxG.width / 2) + (((FlxG.width / 2) - width) / 2);
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
		var item = new DifficultyMenuItem(0, y, diff, songData);
		return addItem(item.name, item);
	}
	
	public function resetSong(songItem:SongMenuItem)
	{
		var songData = songItem.songData;
		var midpoint = songItem.getMidpoint();
		for (i in 0...songData.difficulties.length)
		{
			var diff = songData.difficulties[i];
			var itemY = (midpoint.y + (100 * i));
			var item = members[i];
			if (item == null)
				item = createItem(diff, songData, itemY);
			else
			{
				item.y = itemY;
				byName.remove(item.name);
				item.setSongData(songData, diff);
				byName[item.name] = item;
			}
			item.y -= item.height / 2;
		}
		while (length > songData.difficulties.length)
		{
			var item = remove(members[length - 1], true);
			item.destroy();
		}
		midpoint.put();
	}
}

class DifficultyMenuItem extends TextMenuItem
{
	public var songData:ModSong;
	public var difficulty:String;
	
	var maxWidth:Float = (FlxG.width * (Settings.singleSongSelection ? 1 : 0.5)) - 10;
	
	public function new(x:Float = 0, y:Float = 0, difficulty:String, songData:ModSong)
	{
		super(x, y, null, callback);
		
		setSongData(songData, difficulty);
	}
	
	public function setSongData(songData:ModSong, difficulty:String)
	{
		this.songData = songData;
		label.text = name = this.difficulty = difficulty;
		
		label.size = 65;
		if (label.width > maxWidth)
		{
			var ratio = maxWidth / label.width;
			label.size = Math.floor(label.size * ratio);
		}
		
		reposition();
	}
	
	public function reposition()
	{
		if (Settings.singleSongSelection)
			x = FlxG.width * 2 + ((FlxG.width - width) / 2);
		else
			x = FlxG.width + (((FlxG.width / 2) - width) / 2);
	}
	
	override function destroy()
	{
		super.destroy();
		songData = null;
	}
}
