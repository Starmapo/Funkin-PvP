package states;

import data.Mods;
import data.Settings;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
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
import ui.MenuList;

class SongSelectState extends FNFState
{
	var camPlayers:Array<FlxCamera>;
	var camDivision:FlxCamera;
	var camOver:FlxCamera;
	var transitioning:Bool = true;
	var playerGroups:FlxTypedGroup<PlayerSongSelect>;

	override function create()
	{
		transIn = transOut = null;

		var players = Settings.singleSongSelection ? 1 : 2;
		for (i in 0...players)
		{
			var camPlayer = new FlxCamera(0, 0, Std.int(FlxG.width / players));
			camPlayer.bgColor = 0;
			FlxG.cameras.add(camPlayer, false);
		}

		if (!Settings.singleSongSelection)
		{
			camDivision = new FlxCamera(Std.int((FlxG.width / 2) - 1), 0, 3);
			camDivision.bgColor = FlxColor.WHITE;
			FlxG.cameras.add(camDivision, false);
		}

		camOver = new FlxCamera();
		camOver.bgColor = 0;
		FlxG.cameras.add(camOver, false);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF21007F;
		add(bg);

		playerGroups = new FlxTypedGroup();
		add(playerGroups);

		for (cam in camPlayers)
			cam.zoom = 3;
		FlxTween.tween(camPlayers[0], {zoom: 1}, Main.TRANSITION_TIME, {
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

		if (camPlayers[1] != null)
			camPlayers[1].zoom = camPlayers[0].zoom;
	}
}

class PlayerSongSelect extends FlxGroup
{
	var player:Int = 0;
	var groupMenuList:GroupMenuList;

	public function new(player:Int, camera:FlxCamera)
	{
		super();
		this.player = player;
		cameras = [camera];

		groupMenuList = new GroupMenuList(player);
		groupMenuList.controlsEnabled = false;
		add(groupMenuList);

		for (name => group in Mods.songGroups)
		{
			groupMenuList.createItem(name, group);
		}
	}

	public function setControlsEnabled(value:Bool)
	{
		groupMenuList.controlsEnabled = value;
	}
}

class GroupMenuList extends TypedMenuList<GroupMenuItem>
{
	var player:Int = 0;

	public function new(player:Int)
	{
		super();
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
			if (player == 1)
				item.x += (FlxG.width / 2);
		}
		return addItem(name, item);
	}
}

class GroupMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	var bg:FlxSprite;
	var groupData:ModSongGroup;

	public function new(x:Float = 0, y:Float = 0, name:String, groupData:ModSongGroup)
	{
		this.groupData = groupData;

		var label = new FlxSpriteGroup();

		bg = new FlxSprite().loadGraphic(getBGGraphic(groupData.bg));
		label.add(bg);

		super(x, y, label, name);

		setEmptyBackground();
	}

	function getBGGraphic(name:String)
	{
		var graphicKey = name + '_cropped';
		if (FlxG.bitmap.checkCache(graphicKey))
			return FlxG.bitmap.get(graphicKey);

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
