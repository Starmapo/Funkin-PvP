package subStates.editors.char;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import lime.ui.MouseCursor;
import openfl.ui.Mouse;
import states.editors.CharacterEditorState;

class BaseImageSubState extends FNFSubState
{
	var state:CharacterEditorState;
	var border:FlxSprite;
	var char:FlxSprite;
	var charBorder:FlxSprite;
	var drag:FlxPoint;
	var handleSize:Int = 11;
	var resizingType:Int = -1;
	var resizingWidth:Float = 0;
	var startPos:FlxPoint;

	public function new(state:CharacterEditorState, width:Int, height:Int)
	{
		super();
		this.state = state;

		createCamera();

		char = new FlxSprite();
		add(char);

		charBorder = new FlxSprite();
		add(charBorder);

		var borderKey = 'imageBorder:' + width + 'x' + height;
		var borderGraphic = FlxG.bitmap.get(borderKey);
		if (borderGraphic == null)
		{
			var spr = new FlxSprite().makeGraphic(width, height, FlxColor.TRANSPARENT, false, borderKey);
			FlxSpriteUtil.drawRect(spr, 0, 0, spr.width, spr.height, FlxColor.TRANSPARENT, {thickness: 4, color: FlxColor.WHITE});
			borderGraphic = spr.graphic;
			borderGraphic.destroyOnNoUse = false;
			spr.destroy();
		}
		border = new FlxSprite(0, 0, borderGraphic);
		border.screenCenter();
		add(border);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var amount = FlxG.keys.pressed.SHIFT ? 10 : 1;
		if (FlxG.keys.justPressed.LEFT)
			char.x -= amount;
		if (FlxG.keys.justPressed.RIGHT)
			char.x += amount;
		if (FlxG.keys.justPressed.UP)
			char.y -= amount;
		if (FlxG.keys.justPressed.DOWN)
			char.y += amount;

		var mousePos = FlxG.mouse.getGlobalPosition();
		if (drag != null)
		{
			if (resizingType >= 0)
			{
				var diff:FlxPoint = mousePos - startPos;
				if (!diff.isZero())
				{
					char.setGraphicSize(resizingWidth - diff.x);
					char.updateHitbox();
					switch (resizingType)
					{
						case 0:
							char.setPosition(drag.x - char.width, drag.y - char.height);
					}
					updateBorder();
				}
				diff.put();
			}
			else
				char.setPosition(mousePos.x - drag.x, mousePos.y - drag.y);
			if (FlxG.mouse.released)
			{
				drag = null;
				startPos = null;
			}
		}

		var handleType = -1;
		if (mousePos.x >= char.x && mousePos.x < char.x + handleSize && mousePos.y >= char.y && mousePos.y < char.y + handleSize)
			handleType = 0;
		if (mousePos.x >= char.x + char.width - handleSize
			&& mousePos.x < char.x + char.width
			&& mousePos.y >= char.y
			&& mousePos.y < char.y + handleSize)
			handleType = 1;
		if (mousePos.x >= char.x
			&& mousePos.x < char.x + handleSize
			&& mousePos.y >= char.y + char.height - handleSize
			&& mousePos.y < char.y + char.height)
			handleType = 2;
		if (mousePos.x >= char.x + char.width - handleSize
			&& mousePos.x < char.x + char.width
			&& mousePos.y >= char.y + char.height - handleSize
			&& mousePos.y < char.y + char.height)
			handleType = 3;
		var cursor = switch (handleType)
		{
			case 0, 3: MouseCursor.RESIZE_NWSE;
			case 1, 2: MouseCursor.RESIZE_NESW;
			default: MouseCursor.DEFAULT;
		}
		if (Mouse.cursor != cursor)
			Mouse.cursor = cursor;

		if (FlxG.mouse.justPressed)
		{
			if (handleType >= 0)
			{
				startPos = mousePos.copyTo();
				switch (handleType)
				{
					case 0:
						drag = FlxPoint.get(char.x + char.width, char.y + char.height);
				}
				resizingType = handleType;
				resizingWidth = char.width;
			}
			else if (char.overlapsPoint(mousePos))
				drag = FlxPoint.get(mousePos.x - char.x, mousePos.y - char.y);
		}

		mousePos.put();

		charBorder.setPosition(char.x, char.y);

		if (FlxG.keys.justPressed.ESCAPE)
			close();
	}

	override function destroy()
	{
		super.destroy();
		state = null;
		border = null;
		char = null;
		drag = FlxDestroyUtil.put(drag);
	}

	override function onOpen()
	{
		reloadFrame();
		super.onOpen();
	}

	function reloadFrame()
	{
		var frame = state.char.frame;
		char.frames = FlxAtlasFrames.findFrame(frame.parent);
		char.frame = frame;
		char.scale.scale(state.charInfo.scale);
		char.updateHitbox();
		char.screenCenter();
		char.flipX = state.charInfo.flipX;
		char.antialiasing = state.charInfo.antialiasing;

		updateBorder();
	}

	function updateBorder()
	{
		if (charBorder.width != char.width || charBorder.height != char.height)
		{
			charBorder.makeGraphic(Std.int(char.width), Std.int(char.height), FlxColor.TRANSPARENT);
			FlxSpriteUtil.drawRect(charBorder, 0, 0, charBorder.width, charBorder.height, FlxColor.TRANSPARENT, {thickness: 1, color: FlxColor.WHITE});
		}
	}
}
