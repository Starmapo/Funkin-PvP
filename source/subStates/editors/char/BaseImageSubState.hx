package subStates.editors.char;

import backend.util.UnsafeUtil;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUIButton;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import haxe.io.Path;
import lime.ui.MouseCursor;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.ui.Mouse;
import states.editors.CharacterEditorState;
import sys.FileSystem;
import sys.io.File;

class BaseImageSubState extends FNFSubState
{
	public var path:String;
	
	var state:CharacterEditorState;
	var border:FlxSprite;
	var char:FlxSprite;
	var charBorder:FlxSprite;
	var drag:FlxPoint;
	var handleSize:Int = 11;
	var resizingType:Int = -1;
	var resizingWidth:Float = 0;
	var startPos:FlxPoint;
	var minSize:Int = 22;
	var camHUD:FlxCamera;
	var saveButton:FlxUIButton;
	
	public function new(state:CharacterEditorState, width:Int, height:Int, path:String = '')
	{
		super();
		this.state = state;
		this.path = path;
		
		createCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);
		
		var grid = FlxGridOverlay.create(8, 8, width, height, true, 0xFF2F2F2F, 0xFF3F3F3F);
		grid.screenCenter();
		add(grid);
		
		char = new FlxSprite();
		add(char);
		
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
		
		final borderColor = 0xFF303030;
		add(new FlxSprite().makeGraphic(Std.int(border.x), FlxG.height, borderColor));
		add(new FlxSprite().makeGraphic(FlxG.width, Std.int(border.y), borderColor));
		add(new FlxSprite(border.x + border.width).makeGraphic(Std.int(FlxG.width - border.x - border.width), FlxG.height, borderColor));
		add(new FlxSprite(0, border.y + border.height).makeGraphic(FlxG.width, Std.int(FlxG.height - border.y - border.height), borderColor));
		
		charBorder = new FlxSprite();
		add(charBorder);
		
		saveButton = new FlxUIButton(0, 10, 'Save');
		saveButton.onUp.callback = function()
		{
			save();
		};
		saveButton.screenCenter(X);
		saveButton.cameras = [camHUD];
		add(saveButton);
		
		reloadFrame();
		char.screenCenter();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (drag == null)
		{
			final zoomAmount = 0.25;
			final zoomMult = 0.25;
			var zoom = camSubState.zoom;
			if (FlxG.keys.justPressed.Q)
				zoom -= zoomAmount;
			if (FlxG.keys.justPressed.E)
				zoom += zoomAmount;
			if (FlxG.keys.pressed.CONTROL && FlxG.mouse.wheel != 0)
				zoom += FlxG.mouse.wheel * zoomMult;
			camSubState.zoom = FlxMath.bound(zoom, 1, FlxG.height / border.height);
			
			final amount = FlxG.keys.pressed.SHIFT ? 10 : 1;
			if (FlxG.keys.justPressed.LEFT)
				char.x = Math.floor(char.x - amount);
			if (FlxG.keys.justPressed.RIGHT)
				char.x = Math.ceil(char.x + amount);
			if (FlxG.keys.justPressed.UP)
				char.y = Math.floor(char.y - amount);
			if (FlxG.keys.justPressed.DOWN)
				char.y = Math.ceil(char.y + amount);
				
			if (FlxG.keys.justPressed.R)
			{
				char.scale.set(state.info.scale, state.info.scale);
				char.updateHitbox();
				char.screenCenter();
				updateBorder();
			}
		}
		
		final mousePos = FlxG.mouse.getScreenPosition(camSubState);
		if (drag != null)
		{
			if (resizingType >= 0)
			{
				// there is probably a better way to do all of this.
				// but if it aint broke dont fix it
				var diff:FlxPoint = mousePos - startPos;
				var width = resizingWidth + diff.x * (resizingType == 1 || resizingType == 3 ? 1 : -1);
				FlxG.watch.addQuick('diff', diff);
				FlxG.watch.addQuick('width', width);
				if (char.width != width && width >= minSize)
				{
					char.setGraphicSize(width);
					char.updateHitbox();
					switch (resizingType)
					{
						case 0:
							char.setPosition(drag.x - char.width, drag.y - char.height);
						case 1:
							char.setPosition(drag.x, drag.y - char.height);
						case 2:
							char.setPosition(drag.x - char.width, drag.y);
						case 3:
							char.setPosition(drag.x, drag.y);
					}
					updateBorder();
				}
				diff.put();
			}
			else
				char.setPosition(mousePos.x - drag.x, mousePos.y - drag.y);
			char.setPosition(Math.round(char.x), Math.round(char.y));
			if (FlxG.mouse.released)
			{
				drag = null;
				startPos = null;
				resizingType = -1;
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
			
		final charOverlap = char.overlapsPoint(mousePos);
		if (FlxG.mouse.justPressed)
		{
			if (handleType >= 0)
			{
				startPos = mousePos.copyTo();
				switch (handleType)
				{
					case 0:
						drag = FlxPoint.get(char.x + char.width, char.y + char.height);
					case 1:
						drag = FlxPoint.get(char.x, char.y + char.height);
					case 2:
						drag = FlxPoint.get(char.x + char.width, char.y);
					case 3:
						drag = FlxPoint.get(char.x, char.y);
				}
				resizingType = handleType;
				resizingWidth = char.width;
			}
			else if (charOverlap)
				drag = FlxPoint.get(mousePos.x - char.x, mousePos.y - char.y);
		}
		
		mousePos.put();
		
		var type = handleType;
		if (resizingType >= 0)
			type = resizingType;
		final cursor = switch (type)
		{
			case 0, 3: MouseCursor.RESIZE_NWSE;
			case 1, 2: MouseCursor.RESIZE_NESW;
			default: if (charOverlap) MouseCursor.MOVE; else MouseCursor.DEFAULT;
		}
		if (Mouse.cursor != cursor)
			Mouse.cursor = cursor;
			
		charBorder.setPosition(char.x, char.y);
		charBorder.visible = drag == null;
		
		if (FlxG.keys.justPressed.S && FlxG.keys.pressed.CONTROL)
			save();
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
	
	override function onClose()
	{
		if (Mouse.cursor != MouseCursor.DEFAULT)
			Mouse.cursor = MouseCursor.DEFAULT;
		super.onClose();
	}
	
	function reloadFrame()
	{
		char.flipX = state.info.flipX;
		char.antialiasing = state.info.antialiasing;
		
		var frame = state.char.frame;
		if (char.frame == frame)
			return;
			
		char.frames = FlxAtlasFrames.findFrame(frame.parent);
		char.frame = frame;
		char.scale.set(state.info.scale, state.info.scale);
		char.updateHitbox();
		char.screenCenter();
		updateBorder();
	}
	
	function updateBorder()
	{
		if (charBorder.width != char.width || charBorder.height != char.height)
		{
			charBorder.makeGraphic(Std.int(char.width), Std.int(char.height), FlxColor.TRANSPARENT);
			FlxSpriteUtil.drawRect(charBorder, 0, 0, charBorder.width, charBorder.height, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.BLUE});
		}
	}
	
	function save()
	{
		if (path == null || path.length < 1)
			return;
			
		var frame = char.frame;
		// first we need to make a bitmap with just the frame we're gonna draw
		// (for some reason, calling `draw` with the original bitmap doesn't work)
		var frameBitmap = new BitmapData(Std.int(frame.frame.width), Std.int(frame.frame.height), true, FlxColor.TRANSPARENT);
		frameBitmap.copyPixels(char.pixels, frame.frame.copyToFlash(), new Point(), null, null, true);
		
		// now we'll make the actual icon
		var bitmap = new BitmapData(Std.int(border.width), Std.int(border.height), true, FlxColor.TRANSPARENT);
		// create a matrix for our transformations
		var matrix = new FlxMatrix();
		// set frame transformations (offset + flipping horizontally)
		@:privateAccess
		frame.prepareMatrix(matrix, ANGLE_0, char.checkFlipX(), char.checkFlipY());
		matrix.translate(-char.origin.x, -char.origin.y);
		// scale matrix
		matrix.scale(char.scale.x, char.scale.y);
		// translate matrix to the correct position
		matrix.translate((char.x - border.x) + char.origin.x - char.offset.x, (char.y - border.y) + char.origin.y - char.offset.y);
		// round the position cause we shouldn't have decimals
		matrix.tx = Math.floor(matrix.tx);
		matrix.ty = Math.floor(matrix.ty);
		// now draw the frame with our matrix
		bitmap.draw(frameBitmap, matrix, null, null, null, char.antialiasing);
		
		var imagePath = Path.join([Mods.modsPath, state.info.mod, path]);
		UnsafeUtil.createDirectory(Path.directory(imagePath));
		// finally, save the image
		File.saveBytes(imagePath, bitmap.encode(new Rectangle(0, 0, bitmap.width, bitmap.height), new PNGEncoderOptions()));
		
		FlxTween.cancelTweensOf(saveButton);
		FlxTween.color(saveButton, 0.2, FlxColor.LIME, FlxColor.WHITE, {startDelay: 0.2});
	}
}
