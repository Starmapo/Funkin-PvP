package objects.openfl;

import backend.FlxDisplayState;
import flixel.FlxG;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer;
import openfl.geom.Rectangle;

class NotificationManager extends FlxDisplayState
{
	var display:NotificationDisplay;
	
	public function new()
	{
		super();
		
		display = new NotificationDisplay();
		add(display);
	}
	
	override function destroy()
	{
		super.destroy();
		display = null;
	}
	
	public function showNotification(info:String, level:NotificationLevel = INFO)
	{
		return display.showNotification(info, level);
	}
}

class NotificationDisplay extends FlxTypedGroup<Notification>
{
	static final startY:Int = 50;
	
	override function update(elapsed:Float)
	{
		var targetY:Float = startY;
		for (i in 0...length)
		{
			var text = members[i];
			if (text == null)
				continue;
			text.y = FlxMath.lerp(text.y, targetY, elapsed * 15);
			targetY += text.height + 10;
		}
	}
	
	public function showNotification(info:String, level:NotificationLevel = INFO)
	{
		var notification = new Notification(info, level);
		notification.screenCenter(X);
		FlxTween.tween(notification, {alpha: 1}, 0.5, {
			onComplete: function(_)
			{
				var tmr = FlxTimer.startTimer(5, function(_)
				{
					FlxTween.tween(notification, {alpha: 0}, 0.5, {
						onComplete: function(_)
						{
							remove(notification, true);
							notification.destroy();
						}
					}).persist = true;
				}).persist = true;
			}
		}).persist = true;
		return insert(0, notification);
	}
}

class Notification extends FlxSpriteGroup
{
	static function getLevelColor(level:NotificationLevel)
	{
		return switch (level)
		{
			case ERROR:
				0xFFF9645D;
			case WARNING:
				0xFFE9B736;
			case SUCCESS:
				0xFF27B06E;
			default:
				0xFF0FBAE5;
		}
	}
	
	var bg:FlxUI9SliceSprite;
	var text:FlxUITextPersistent;
	
	public function new(info:String, level:NotificationLevel)
	{
		super();
		
		bg = new FlxUI9SliceSprite(0, 0, Paths.getImage('editors/notification'), new Rectangle(), [6, 6, 11, 11]);
		
		text = new FlxUITextPersistent(0, 0, info);
		text.setFormat(Paths.FONT_VCR, 14, getLevelColor(level), CENTER);
		
		final maxWidth = FlxG.width - 40;
		if (text.width > maxWidth)
			text.fieldWidth = maxWidth;
			
		bg.resize(Math.ceil(text.width + 10), Math.ceil(text.height + 10));
		bg.graphic.destroyOnNoUse = false;
		text.setPosition((bg.width / 2) - (text.width / 2), (bg.height / 2) - (text.height / 2));
		
		add(bg);
		add(text);
		
		alpha = 0;
		scrollFactor.set();
	}
	
	override function destroy()
	{
		super.destroy();
		bg = FlxDestroyUtil.destroy(bg);
		text = FlxDestroyUtil.destroy(text);
	}
}

enum NotificationLevel
{
	INFO;
	ERROR;
	WARNING;
	SUCCESS;
}

class FlxUITextPersistent extends FlxUIText
{
	override function regenGraphic()
	{
		super.regenGraphic();
		if (graphic != null)
			graphic.destroyOnNoUse = false;
	}
}
