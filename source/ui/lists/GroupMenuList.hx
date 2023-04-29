package ui.lists;

import data.Mods.ModSongGroup;
import data.Settings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapDataChannel;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import ui.lists.MenuList;

class GroupMenuList extends TypedMenuList<GroupMenuItem>
{
    public var singleSongSelection:Bool = false;

	var player:Int = 0;
	var columns:Int = 4;
	var gridSize:Int = 158;
	var singleOffset:Float;
	var doubleOffset:Float;

	public function new(player:Int)
	{
		super(COLUMNS(4), PLAYER(player));
		this.player = player;

		var columnWidth = gridSize * 4;
		singleOffset = (FlxG.width - columnWidth) / 2;
		doubleOffset = ((FlxG.width / 2) - columnWidth) / 2;
	}

	public function createItem(groupData:ModSongGroup)
	{
		var name = groupData.name;
		var item = new GroupMenuItem(gridSize * (length % columns), gridSize * Math.floor(length / columns), name, groupData);

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
