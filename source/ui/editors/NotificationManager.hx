package ui.editors;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class NotificationManager extends FlxTypedGroup<FlxText>
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
			text.y = FlxMath.lerp(text.y, targetY, CoolUtil.getLerp(0.25));
			targetY += text.height + 10;
		}
	}

	public function showNotification(notification:String)
	{
		var text = new FlxText(5, startY, FlxG.width - 10, notification);
		text.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		text.alpha = 0;
		FlxTween.tween(text, {alpha: 1}, 0.5, {
			onComplete: function(_)
			{
				FlxTimer.startTimer(3, function(_)
				{
					FlxTween.tween(text, {alpha: 0}, 0.5, {
						onComplete: function(_)
						{
							remove(text, true);
							text.destroy();
						}
					});
				});
			}
		});
		return insert(0, text);
	}
}
