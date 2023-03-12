package states;

import data.Mods;
import data.PlayerSettings;
import data.Settings;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapDataChannel;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import ui.MenuList;

class SongSelectState extends FNFState
{
	public var transitioning:Bool = true;

	var camPlayers:Array<FlxCamera> = [];
	var camDivision:FlxCamera;
	var camScroll:FlxCamera;
	var camOver:FlxCamera;
	var playerGroups:FlxTypedGroup<PlayerSongSelect>;
	var iconScroll:FlxBackdrop;

	override function create()
	{
		transIn = transOut = null;

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

		for (i in 0...players)
		{
			playerGroups.add(new PlayerSongSelect(i, camPlayers[i], this));
		}

		var stateText = new FlxText(0, 0, 0, 'Song Selection');
		stateText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		stateText.screenCenter(X);
		stateText.scrollFactor.set();
		stateText.cameras = [camOver];
		camScroll.height = Math.ceil(stateText.height);

		iconScroll = new FlxBackdrop(Paths.getImage('menus/pvp/iconScroll'));
		iconScroll.alpha = 0.5;
		iconScroll.cameras = [camScroll];
		iconScroll.velocity.set(25, 25);
		iconScroll.scale.set(0.5, 0.5);

		add(iconScroll);
		add(stateText);

		for (cam in camPlayers)
			cam.zoom = 3;
		FlxTween.tween(FlxG.camera, {zoom: 1}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				for (group in playerGroups)
					group.setControlsEnabled(true);
			}
		});
		camOver.fade(FlxColor.BLACK, Main.TRANSITION_TIME, true, null, true);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// prevent overflow (it would probably take an eternity for that to happen but you can never be too safe)
		if (iconScroll.x >= 300)
		{
			iconScroll.x %= 300;
		}
		if (iconScroll.y >= 300)
		{
			iconScroll.y %= 300;
		}

		for (cam in camPlayers)
			cam.zoom = FlxG.camera.zoom;
	}

	public function exit()
	{
		transitioning = true;
		for (group in playerGroups)
			group.setControlsEnabled(false);
		FlxTween.tween(FlxG.camera, {zoom: 5}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoIn,
			onComplete: function(_)
			{
				FlxG.switchState(new RulesetState());
			}
		});
		camOver.fade(FlxColor.BLACK, Main.TRANSITION_TIME, false, null, true);
	}
}

class PlayerSongSelect extends FlxGroup
{
	static var lastSelectedGroups:Array<Int> = [0, 0];

	public var viewingSongs:Bool = false;

	var player:Int = 0;
	var onExit:Void->Void;
	var state:SongSelectState;
	var groupMenuList:GroupMenuList;
	var camFollow:FlxObject;

	public function new(player:Int, camera:FlxCamera, state:SongSelectState)
	{
		super();
		this.player = player;
		this.state = state;
		cameras = [camera];

		camFollow = new FlxObject(FlxG.width / (Settings.singleSongSelection ? 2 : 4));
		camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);

		groupMenuList = new GroupMenuList(player);
		groupMenuList.onChange.add(onChange);
		setControlsEnabled(false);
		add(groupMenuList);

		for (name => group in Mods.songGroups)
		{
			groupMenuList.createItem(name, group);
		}

		groupMenuList.selectItem(lastSelectedGroups[player]);
		camera.snapToTarget();
	}

	override function update(elapsed:Float)
	{
		if (!state.transitioning && PlayerSettings.checkPlayerAction(player, BACK_P))
		{
			if (viewingSongs) {}
			else
			{
				state.exit();
			}
		}

		super.update(elapsed);
	}

	public function setControlsEnabled(value:Bool)
	{
		groupMenuList.controlsEnabled = value;
	}

	function onChange(item:GroupMenuItem)
	{
		updateCamFollow(item);
		lastSelectedGroups[player] = item.ID;
	}

	function updateCamFollow(item:GroupMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}
}

class GroupMenuList extends TypedMenuList<GroupMenuItem>
{
	var player:Int = 0;

	public function new(player:Int)
	{
		super(VERTICAL, PLAYER(player));
		this.player = player;
	}

	public function createItem(name:String, groupData:ModSongGroup)
	{
		var item = new GroupMenuItem(0, 250 * length, name, groupData);
		if (Settings.singleSongSelection)
		{
			item.screenCenter(X);
		}
		else
		{
			item.x = ((FlxG.width / 2) - item.width) / 2;
		}
		return addItem(name, item);
	}
}

class GroupMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	var bg:FlxSprite;
	var groupData:ModSongGroup;
	var targetScale:Float = 1;

	public function new(x:Float = 0, y:Float = 0, name:String, groupData:ModSongGroup)
	{
		this.groupData = groupData;

		var label = new FlxSpriteGroup();

		bg = new FlxSprite().loadGraphic(getBGGraphic(groupData.bg));
		label.add(bg);

		super(x, y, label, name);

		setEmptyBackground();

		bg.scale.set(targetScale, targetScale);
	}

	override function update(elapsed:Float)
	{
		if (label != null)
		{
			var lerp = CoolUtil.getLerp(0.25);
			bg.scale.set(FlxMath.lerp(bg.scale.x, targetScale, lerp), FlxMath.lerp(bg.scale.y, targetScale, lerp));
		}

		super.update(elapsed);
	}

	override function idle()
	{
		alpha = 0.6;
		targetScale = 0.8;
	}

	override function select()
	{
		alpha = 1;
		targetScale = 1;
	}

	function getBGGraphic(name:String)
	{
		var graphicKey = name + '_cropped';
		if (FlxG.bitmap.checkCache(graphicKey))
			return FlxG.bitmap.get(graphicKey);

		var startTime = Sys.time();

		var thickness = 4;

		var graphic = Paths.getImage(name, groupData.directory, true, graphicKey);

		var text = new FlxText(0, graphic.height - thickness, graphic.width, groupData.name);
		text.setFormat('PhantomMuff 1.5', 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
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
			var sprite = new FlxSprite().makeGraphic(600, 240, FlxColor.TRANSPARENT, false, 'groupMask');
			FlxSpriteUtil.drawRoundRect(sprite, 0, 0, sprite.width, sprite.height, 20, 20, FlxColor.BLACK);
			mask = sprite.graphic;
			sprite.destroy();
		}

		graphic.bitmap.copyChannel(mask.bitmap, new Rectangle(0, 0, mask.width, mask.height), new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);

		var outline = FlxG.bitmap.get('groupOutline');
		if (outline == null)
		{
			var sprite = new FlxSprite().makeGraphic(600, 240, FlxColor.TRANSPARENT, false, 'groupOutline');
			FlxSpriteUtil.drawRoundRect(sprite, 0, 0, sprite.width, sprite.height, 20, 20, FlxColor.TRANSPARENT,
				{thickness: thickness, color: FlxColor.WHITE});
			outline = sprite.graphic;
			sprite.destroy();
		}

		graphic.bitmap.copyPixels(outline.bitmap, new Rectangle(0, 0, outline.width, outline.height), new Point(), null, null, true);

		trace(Sys.time() - startTime);

		return graphic;
	}

	override function get_width()
	{
		if (label != null)
		{
			return label.width;
		}

		return width;
	}

	override function get_height()
	{
		if (label != null)
		{
			return label.height;
		}

		return height;
	}
}
