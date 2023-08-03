package objects.menus;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;

class ScrollBar extends FlxSpriteGroup
{
	public var contentHeight(default, set):Float;
	public var scrollAmount:Float = 25;
	
	var bg:FlxSprite;
	var bar:FlxSprite;
	var barWidth:Int = 20;
	var contentCamera:FlxCamera;
	var isScrolling:Bool = false;
	var mousePos:Float;
	var barPos:Float;
	
	public function new(x:Float = 0, y:Float = 0, contentHeight:Float, contentCamera:FlxCamera)
	{
		super(x, y);
		this.contentCamera = contentCamera;
		
		bg = new FlxSprite().makeGraphic(1, 1, 0xFF424242);
		add(bg);
		
		bar = new FlxSprite().makeGraphic(1, 1, 0xFF686868);
		add(bar);
		
		changeHeight(contentCamera.height);
		this.contentHeight = contentHeight;
	}
	
	override function update(elapsed:Float)
	{
		if (contentHeight <= contentCamera.height)
			return;
			
		var scrolled = isScrolling;
		
		if (isScrolling)
		{
			var offset = FlxG.mouse.globalY - mousePos;
			bar.y = barPos + offset;
			
			if (FlxG.mouse.released)
				isScrolling = false;
		}
		
		if (FlxG.mouse.wheel != 0
			&& (FlxMath.mouseInFlxRect(false, FlxRect.weak(contentCamera.x, contentCamera.y, contentCamera.width, contentCamera.height))
				|| FlxMath.mouseInFlxRect(false, bg.getHitbox())))
		{
			bar.y += FlxG.mouse.wheel * -scrollAmount;
			scrolled = true;
		}
		
		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(bar))
				isScrolling = true;
			else if (FlxG.mouse.overlaps(bg))
			{
				bar.y = FlxG.mouse.globalY - (bar.height / 2);
				scrolled = true;
				isScrolling = true;
			}
			if (isScrolling)
			{
				mousePos = FlxG.mouse.globalY;
				barPos = bar.y;
			}
		}
		
		if (scrolled)
		{
			bar.y = FlxMath.bound(bar.y, bg.y, bg.y + bg.height - bar.height);
			contentCamera.scroll.y = FlxMath.remapToRange(bar.y, bg.y, bg.y + bg.height - bar.height, 0, contentHeight - contentCamera.height);
		}
	}
	
	public function changeHeight(height:Float)
	{
		bg.setGraphicSize(barWidth, Math.round(height));
		bg.updateHitbox();
		
		updateBarScale();
	}
	
	public function updateBarScale()
	{
		var scale = Math.min(contentCamera.height / contentHeight, 1);
		bar.setGraphicSize(Std.int(bg.width), Math.round(bg.height * scale));
		bar.updateHitbox();
		
		updateBarPosition();
	}
	
	public function updateBarPosition()
	{
		if (contentHeight <= contentCamera.height)
			bar.y = bg.y;
		else
			bar.y = FlxMath.remapToRange(contentCamera.scroll.y, 0, contentHeight - contentCamera.height, bg.y, bg.y + bg.height - bar.height);
	}
	
	function set_contentHeight(value:Float)
	{
		var newHeight = Math.max(value, contentCamera.height);
		if (contentHeight != newHeight)
		{
			contentHeight = newHeight;
			updateBarScale();
		}
		return value;
	}
}
