package states.pvp;

import backend.util.StringUtil;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import objects.menus.VoidBG;
import objects.menus.lists.MenuList;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class CharacterSelectState extends FNFState
{
	public var transitioning:Bool = true;
	
	var camPlayers:Array<FlxCamera> = [];
	var camDivision:FlxCamera;
	var camScroll:FlxCamera;
	var camOver:FlxCamera;
	var iconScroll:FlxBackdrop;
	var stateText:FlxText;
	var playerGroups:FlxTypedGroup<PlayerCharacterSelect>;
	
	override function create()
	{
		DiscordClient.changePresence(null, "Character Select");
		
		transIn = transOut = null;
		persistentUpdate = true;
		
		for (i in 0...2)
		{
			var camPlayer = new FlxCamera(Std.int((FlxG.width / 2) * i), 0, Std.int(FlxG.width / 2));
			camPlayer.bgColor = 0;
			camPlayers.push(camPlayer);
			FlxG.cameras.add(camPlayer, false);
		}
		
		camDivision = new FlxCamera(Std.int((FlxG.width / 2) - 1), 0, 3);
		camDivision.bgColor = FlxColor.WHITE;
		FlxG.cameras.add(camDivision, false);
		
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
			Mods.reloadCharacters();
		var groups = [];
		for (_ => group in Mods.characterGroups)
			groups.push(group);
		groups.sort(function(a, b)
		{
			return StringUtil.sortAlphabetically(a.name, b.name);
		});
		for (i in 0...2)
			playerGroups.add(new PlayerCharacterSelect(i, camPlayers[i], this, groups));
			
		stateText = new FlxText(0, 0, 0, 'Character Selection');
		stateText.setFormat(Paths.FONT_PHANTOMMUFF, 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
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
		
		FlxG.camera.zoom = 3;
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
		
		if (!FlxG.sound.musicPlaying)
			CoolUtil.playPvPMusic(duration);
			
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
				transitioning = true;
				exitTransition(function(_)
				{
					var chars = [];
					for (group in playerGroups)
					{
						var data = group.charMenuList.selectedItem.charData;
						chars.push(data.id + ':' + data.name);
					}
					Paths.clearCache = true;
					FlxG.switchState(new PlayState(SongSelectState.song, chars));
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
		iconScroll = null;
		stateText = null;
		playerGroups = null;
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
}

class PlayerCharacterSelect extends FlxGroup
{
	static var lastSelectedGroups:Array<Int> = [0, 0];
	static var lastSelectedChars:Array<Int> = [-1, -1];
	static var lastScreens:Array<Int> = [0, 0];
	
	public var viewing:Int = 0;
	public var ready:Bool = false;
	public var groupMenuList:CharacterGroupMenuList;
	public var charMenuList:CharacterMenuList;
	
	var player:Int = 0;
	var state:CharacterSelectState;
	var camFollow:FlxObject;
	var lastGroupReset:String = '';
	var charPortrait:FlxSprite;
	var charPortraitWhite:FlxSprite;
	var charText:FlxText;
	var screenText:FlxText;
	
	public function new(player:Int, camera:FlxCamera, state:CharacterSelectState, groups:Array<ModCharacterGroup>)
	{
		super();
		this.player = player;
		this.state = state;
		cameras = [camera];
		
		camFollow = new FlxObject(FlxG.width / 4);
		camFollow.exists = false;
		camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);
		
		groupMenuList = new CharacterGroupMenuList(player);
		groupMenuList.onChange.add(onGroupChange);
		groupMenuList.onAccept.add(onGroupAccept);
		
		for (group in groups)
			groupMenuList.createItem(group);
		groupMenuList.afterInit();
		
		charMenuList = new CharacterMenuList(player);
		charMenuList.controlsEnabled = false;
		charMenuList.onChange.add(onCharChange);
		charMenuList.onAccept.add(onCharAccept);
		
		add(charMenuList);
		add(groupMenuList);
		
		charPortrait = new FlxSprite(FlxG.width / 2, FlxG.height / 4);
		if (player == 0)
			charPortrait.x += 5;
		else
		{
			charPortrait.x += 15 + FlxG.width / 4;
			charPortrait.flipX = true;
		}
		charPortrait.antialiasing = true;
		charPortrait.scrollFactor.y = 0;
		charPortrait.active = false;
		add(charPortrait);
		
		charPortraitWhite = new FlxSprite(charPortrait.x, charPortrait.y).makeGraphic(1, 1, FlxColor.WHITE);
		charPortraitWhite.scrollFactor.copyFrom(charPortrait.scrollFactor);
		charPortraitWhite.alpha = 0;
		charPortraitWhite.active = false;
		add(charPortraitWhite);
		
		var charPortraitOutline = new FlxSprite(charPortrait.x, charPortrait.y, getPortraitOutlineGraphic());
		charPortraitOutline.scrollFactor.copyFrom(charPortrait.scrollFactor);
		charPortraitOutline.active = false;
		add(charPortraitOutline);
		
		charText = new FlxText(charPortraitOutline.x, charPortraitOutline.y + charPortraitOutline.height + 10, charPortraitOutline.width, '');
		charText.setFormat(Paths.FONT_PHANTOMMUFF, 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		charText.scrollFactor.copyFrom(charPortraitOutline.scrollFactor);
		charText.active = false;
		add(charText);
		
		screenText = new FlxText(5, 50, camera.width - 10);
		screenText.setFormat(Paths.FONT_PHANTOMMUFF, 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		screenText.scrollFactor.set();
		screenText.alpha = 0.6;
		screenText.active = false;
		add(screenText);
		
		if (lastSelectedGroups[player] >= groupMenuList.length)
			lastSelectedGroups[player] = groupMenuList.length - 1;
		groupMenuList.selectItem(lastSelectedGroups[player]);
		
		var selectedChar = lastSelectedChars[player];
		if (selectedChar >= 0)
		{
			charMenuList.resetGroup(groupMenuList.selectedItem);
			lastGroupReset = groupMenuList.selectedItem.name;
			
			if (selectedChar >= charMenuList.length)
				selectedChar = charMenuList.length - 1;
			charMenuList.selectItem(selectedChar);
		}
		
		switch (lastScreens[player])
		{
			case 1:
				groupAccept(groupMenuList.selectedItem);
			default:
				updateCamFollow(groupMenuList.selectedItem);
		}
		
		camera.snapToTarget();
		
		setControlsEnabled(false);
	}
	
	override function update(elapsed:Float)
	{
		if (!state.transitioning && PlayerSettings.checkPlayerAction(player, BACK_P))
		{
			if (ready)
			{
				var item = charMenuList.selectedItem;
				FlxTween.cancelTweensOf(item);
				FlxTween.color(item, 0.5, item.color, FlxColor.WHITE);
				ready = false;
				charMenuList.controlsEnabled = true;
			}
			else if (viewing == 1)
			{
				charMenuList.controlsEnabled = false;
				groupMenuList.controlsEnabled = true;
				camFollow.x = FlxG.width * 0.25;
				updateCamFollow(groupMenuList.selectedItem);
				updateScreenText();
				viewing = 0;
				lastScreens[player] = viewing;
			}
			else
			{
				state.exitTransition(function(_)
				{
					FlxG.switchState(new SongSelectState());
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
		charMenuList = null;
		state = null;
		camFollow = null;
		charPortrait = null;
		charPortraitWhite = null;
		charText = null;
	}
	
	public function setControlsEnabled(value:Bool)
	{
		if (viewing == 1)
			charMenuList.controlsEnabled = value;
		else
			groupMenuList.controlsEnabled = value;
	}
	
	function updateCamFollow(item:MenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}
	
	function onGroupChange(item:CharacterGroupMenuItem)
	{
		updateCamFollow(item);
		lastSelectedGroups[player] = item.ID;
	}
	
	function onGroupAccept(item:CharacterGroupMenuItem)
	{
		groupAccept(item);
		CoolUtil.playScrollSound();
	}
	
	function groupAccept(item:CharacterGroupMenuItem)
	{
		groupMenuList.controlsEnabled = false;
		charMenuList.controlsEnabled = true;
		camFollow.x = FlxG.width * 0.75;
		if (lastGroupReset != item.name)
		{
			charMenuList.resetGroup(item);
			charMenuList.selectItem(0);
			lastGroupReset = item.name;
		}
		else
			updateCamFollow(charMenuList.selectedItem);
		updateScreenText();
		viewing = 1;
		lastScreens[player] = viewing;
	}
	
	function onCharChange(item:CharacterMenuItem)
	{
		updateCamFollow(item);
		var portrait = Paths.getImage('characterSelect/portraits/' + item.charData.name, item.charData.id);
		if (portrait != null)
		{
			charPortrait.loadGraphic(portrait);
			
			charPortraitWhite.setGraphicSize(charPortrait.width, charPortrait.height);
			charPortraitWhite.updateHitbox();
			charPortraitWhite.alpha = 0.25;
			FlxTween.cancelTweensOf(charPortraitWhite);
			FlxTween.tween(charPortraitWhite, {alpha: 0}, 0.2);
		}
		charPortraitWhite.visible = charPortrait.visible = (portrait != null);
		charText.text = item.charData.displayName;
		lastSelectedChars[player] = item.ID;
	}
	
	function onCharAccept(item:CharacterMenuItem)
	{
		ready = true;
		charMenuList.controlsEnabled = false;
		FlxTween.cancelTweensOf(item);
		FlxTween.color(item, 0.5, item.color, FlxColor.LIME);
		CoolUtil.playConfirmSound();
	}
	
	function getPortraitOutlineGraphic()
	{
		var graphicKey = 'portrait_outline';
		if (FlxG.bitmap.checkCache(graphicKey))
			return FlxG.bitmap.get(graphicKey);
			
		var outline:FlxGraphic = null;
		
		var sprite = new FlxSprite().makeGraphic(300, 360, FlxColor.TRANSPARENT, true, graphicKey);
		FlxSpriteUtil.drawRect(sprite, 0, 0, sprite.width, sprite.height, FlxColor.TRANSPARENT, {thickness: 4, color: FlxColor.WHITE});
		outline = sprite.graphic;
		outline.destroyOnNoUse = false;
		sprite.destroy();
		
		return outline;
	}
	
	function updateScreenText()
	{
		if (charMenuList.controlsEnabled)
			screenText.text = groupMenuList.selectedItem.groupData.name;
		else
			screenText.text = '';
	}
}

class CharacterGroupMenuList extends TypedMenuList<CharacterGroupMenuItem>
{
	public var singleSongSelection:Bool = false;
	
	var player:Int = 0;
	var columns:Int = 4;
	var gridSize:Int = 158;
	var singleOffset:Float;
	var doubleOffset:Float;
	
	public function new(player:Int)
	{
		super(COLUMNS(columns), PLAYER(player));
		this.player = player;
		
		var columnWidth = gridSize * 4;
		singleOffset = (FlxG.width - columnWidth) / 2;
		doubleOffset = ((FlxG.width / 2) - columnWidth) / 2;
	}
	
	public function createItem(groupData:ModCharacterGroup)
	{
		var name = groupData.name;
		var item = new CharacterGroupMenuItem(gridSize * (length % columns), gridSize * Math.floor(length / columns), name, groupData);
		
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

class CharacterGroupMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	public var groupData:ModCharacterGroup;
	
	var bg:FlxSprite;
	
	public function new(x:Float = 0, y:Float = 0, name:String, groupData:ModCharacterGroup)
	{
		this.groupData = groupData;
		
		var label = new FlxSpriteGroup();
		
		super(x, y, label, name);
		
		bg = new FlxSprite(0, 0, CoolUtil.getGroupGraphic(groupData.name, groupData.id));
		bg.antialiasing = true;
		label.add(bg);
		
		setEmptyBackground();
		active = false;
	}
	
	override function destroy()
	{
		super.destroy();
		groupData = null;
		bg = null;
	}
}

class CharacterMenuList extends TypedMenuList<CharacterMenuItem>
{
	var player:Int = 0;
	var columns:Int = 4;
	var gridSize:Int = 80;
	var offset:Float;
	
	public function new(player:Int)
	{
		super(COLUMNS(columns), PLAYER(player));
		this.player = player;
		
		var columnWidth = gridSize * 4;
		offset = ((FlxG.width / 2) - columnWidth) / 2;
	}
	
	public function createItem(charData:ModCharacter, y:Float)
	{
		var item = new CharacterMenuItem(gridSize * (length % columns), y, charData);
		if (player == 0)
			item.x += (FlxG.width * 0.75) - 5;
		else
		{
			item.x += (FlxG.width * 0.5) + 5;
			item.flipX = true;
		}
		return addItem(item.name, item);
	}
	
	public function resetGroup(groupItem:CharacterGroupMenuItem)
	{
		var charGroup = groupItem.groupData;
		var midpoint = groupItem.getMidpoint();
		
		// some stupid coding here
		for (i in 0...charGroup.chars.length)
		{
			var char = charGroup.chars[i];
			var itemY = midpoint.y + gridSize * Math.floor(i / columns);
			var item = members[i];
			if (item == null)
				item = createItem(char, itemY);
			else
			{
				item.y = itemY;
				byName.remove(item.name);
				item.setCharData(char);
				byName[item.name] = item;
			}
			item.y -= item.height / 2;
		}
		while (length > charGroup.chars.length)
		{
			var item = remove(members[length - 1], true);
			item.destroy();
		}
		midpoint.put();
	}
}

class CharacterMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	public var charData:ModCharacter;
	
	var bg:FlxSprite;
	
	public function new(x:Float = 0, y:Float = 0, charData:ModCharacter)
	{
		var label = new FlxSpriteGroup();
		
		super(x, y, label, null);
		
		bg = new FlxSprite();
		bg.antialiasing = true;
		label.add(bg);
		
		setEmptyBackground();
		active = false;
		
		setCharData(charData);
	}
	
	override function destroy()
	{
		super.destroy();
		charData = null;
		bg = null;
	}
	
	public function setCharData(charData:ModCharacter)
	{
		this.charData = charData;
		name = charData.id + charData.name;
		
		bg.loadGraphic(getBGGraphic());
	}
	
	function getBGGraphic()
	{
		final graphicKey = name + '_edit';
		if (FlxG.bitmap.checkCache(graphicKey))
			return FlxG.bitmap.get(graphicKey);
			
		final thickness = 4;
		
		var graphic = Paths.getImage('characterSelect/icons/' + charData.name, charData.id, true, false, graphicKey);
		if (graphic == null)
		{
			final unknownKey = '::charUnknown::_edit';
			if (FlxG.bitmap.checkCache(unknownKey))
				return FlxG.bitmap.get(unknownKey);
			graphic = FlxGraphic.fromRectangle(80, 80, FlxColor.TRANSPARENT, true, unknownKey);
		}
		
		var outline = FlxG.bitmap.get('charOutline');
		if (outline == null)
		{
			final sprite = new FlxSprite().makeGraphic(80, 80, FlxColor.TRANSPARENT, false, 'charOutline');
			FlxSpriteUtil.drawRect(sprite, 0, 0, sprite.width, sprite.height, FlxColor.TRANSPARENT, {thickness: thickness, color: FlxColor.WHITE});
			outline = sprite.graphic;
			outline.destroyOnNoUse = false;
			sprite.destroy();
		}
		
		graphic.bitmap.copyPixels(outline.bitmap, new Rectangle(0, 0, outline.width, outline.height), new Point(), null, null, true);
		
		return graphic;
	}
	
	override function set_flipX(value)
	{
		bg.flipX = value;
		return super.set_flipX(value);
	}
}
