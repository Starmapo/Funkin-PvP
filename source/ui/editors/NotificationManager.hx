package ui.editors;

import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import openfl.geom.Rectangle;

class NotificationManager extends FlxTypedGroup<Notification>
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
			text.y = CoolUtil.lerp(text.y, targetY, elapsed * 15);
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
				FlxTimer.startTimer(5, function(_)
				{
					FlxTween.tween(notification, {alpha: 0}, 0.5, {
						onComplete: function(_)
						{
							remove(notification, true);
							notification.destroy();
						}
					});
				});
			}
		});
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
	var text:FlxUIText;

	public function new(info:String, level:NotificationLevel)
	{
		super();

		bg = new FlxUI9SliceSprite(0, 0, Paths.getImage('editors/notification'), new Rectangle(), [6, 6, 11, 11]);

		text = new FlxUIText(0, 0, info);
		text.setFormat('VCR OSD Mono', 14, getLevelColor(level));

		bg.resize(text.width + 10, text.height + 10);
		text.setPosition((bg.width / 2) - (text.width / 2), (bg.height / 2) - (text.height / 2));

		add(bg);
		add(text);

		alpha = 0;
		scrollFactor.set();
	}

	override function destroy()
	{
		super.destroy();
		bg = null;
		text = null;
	}
}

enum NotificationLevel
{
	INFO;
	ERROR;
	WARNING;
	SUCCESS;
}
