package states.pvp;

import data.Mods;
import data.PlayerSettings;
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
import openfl.display.BitmapDataChannel;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import ui.lists.MenuList.MenuItem;
import ui.lists.MenuList.TypedMenuItem;
import ui.lists.MenuList.TypedMenuList;
import util.DiscordClient;

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

		playerGroups = new FlxTypedGroup();
		add(playerGroups);

		for (i in 0...2)
			playerGroups.add(new PlayerCharacterSelect(i, camPlayers[i], this));

		stateText = new FlxText(0, 0, 0, 'Character Selection');
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
				exitTransition(function(_)
				{
					var chars = [];
					for (group in playerGroups)
					{
						var data = group.charMenuList.selectedItem.charData;
						chars.push(data.directory + ':' + data.name);
					}
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
	static var lastSelectedChars:Array<Int> = [0, 0];

	public var viewing:Int = 0;
	public var ready:Bool = false;
	public var groupMenuList:CharacterGroupMenuList;
	public var charMenuList:CharacterMenuList;

	var player:Int = 0;
	var state:CharacterSelectState;
	var camFollow:FlxObject;
	var lastGroupReset:String = '';
	var charPortrait:FlxSprite;
	var charText:FlxText;

	public function new(player:Int, camera:FlxCamera, state:CharacterSelectState)
	{
		super();
		this.player = player;
		this.state = state;
		cameras = [camera];

		camFollow = new FlxObject(FlxG.width / 4);
		camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);

		groupMenuList = new CharacterGroupMenuList(player);
		groupMenuList.onChange.add(onGroupChange);
		groupMenuList.onAccept.add(onGroupAccept);

		for (_ => group in Mods.characterGroups)
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
		add(charPortrait);

		var charPortraitOutline = new FlxSprite(charPortrait.x, charPortrait.y, getPortraitOutlineGraphic());
		charPortraitOutline.scrollFactor.copyFrom(charPortrait.scrollFactor);
		add(charPortraitOutline);

		charText = new FlxText(charPortraitOutline.x, charPortraitOutline.y + charPortraitOutline.height + 10, charPortraitOutline.width, '');
		charText.setFormat('PhantomMuff 1.5', 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		charText.scrollFactor.copyFrom(charPortraitOutline.scrollFactor);
		add(charText);

		setControlsEnabled(false);

		groupMenuList.selectItem(lastSelectedGroups[player]);
		charMenuList.resetGroup(groupMenuList.selectedItem);
		lastGroupReset = groupMenuList.selectedItem.name;
		charMenuList.selectItem(lastSelectedChars[player]);

		updateCamFollow(groupMenuList.selectedItem);
		camera.snapToTarget();
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
				viewing = 0;
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
		charText = null;
	}

	public function setControlsEnabled(value:Bool)
	{
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
		viewing = 1;
		CoolUtil.playScrollSound();
	}

	function onCharChange(item:CharacterMenuItem)
	{
		updateCamFollow(item);
		var portrait = Paths.getImage('characterSelect/portraits/' + item.charData.name, item.charData.directory);
		if (portrait != null)
			charPortrait.loadGraphic(portrait);
		charPortrait.visible = (portrait != null);
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

		bg = new FlxSprite().loadGraphic(getBGGraphic(groupData.bg));
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
		var graphicKey = name + '_edit';
		if (FlxG.bitmap.checkCache(graphicKey))
			return FlxG.bitmap.get(graphicKey);

		var thickness = 4;

		var graphic = Paths.getImage(name, groupData.directory, true, graphicKey);

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
		var name = charData.directory + charData.name;
		var item = new CharacterMenuItem(gridSize * (length % columns), y + gridSize * Math.floor(length / columns), name, charData);
		if (player == 0)
			item.x += (FlxG.width * 0.75) - 5;
		else
		{
			item.x += (FlxG.width * 0.5) + 5;
			item.flipX = true;
		}
		item.y -= item.height / 2;
		byName[name] = item;
		item.ID = length;
		return item;
	}

	public function resetGroup(groupItem:CharacterGroupMenuItem)
	{
		var charGroup = groupItem.groupData;
		var midpoint = groupItem.getMidpoint();
		clear();
		for (song in charGroup.chars)
		{
			var item = createItem(song, midpoint.y);
			addItem(item.name, item);
		}
		midpoint.put();
	}
}

class CharacterMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	public var charData:ModCharacter;

	var bg:FlxSprite;

	public function new(x:Float = 0, y:Float = 0, name:String, charData:ModCharacter)
	{
		this.charData = charData;

		var label = new FlxSpriteGroup();

		super(x, y, label, name);

		bg = new FlxSprite().loadGraphic(getBGGraphic());
		bg.antialiasing = true;
		label.add(bg);

		setEmptyBackground();
	}

	override function destroy()
	{
		super.destroy();
		charData = null;
		bg = null;
	}

	function getBGGraphic()
	{
		var graphicKey = name + '_edit';
		if (FlxG.bitmap.checkCache(graphicKey))
			return FlxG.bitmap.get(graphicKey);

		var thickness = 4;

		var graphic = Paths.getImage('characterSelect/icons/' + charData.name, charData.directory, true, graphicKey);
		if (graphic == null)
			graphic = FlxGraphic.fromRectangle(80, 80, FlxColor.TRANSPARENT, true, graphicKey);

		var outline = FlxG.bitmap.get('charOutline');
		if (outline == null)
		{
			var sprite = new FlxSprite().makeGraphic(80, 80, FlxColor.TRANSPARENT, false, 'charOutline');
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
