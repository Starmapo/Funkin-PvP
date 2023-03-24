package ui.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIText;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import openfl.geom.Rectangle;

class Tooltip extends FlxSpriteGroup
{
	var bg:FlxUI9SliceSprite;
	var text:FlxUIText;
	var addedTooltips:Map<FlxSprite, String> = new Map();
	var fadeTween:FlxTween;
	var showing:Bool = false;

	public function new()
	{
		super();

		bg = new FlxUI9SliceSprite(0, 0, Paths.getImage('editors/tooltip'), new Rectangle(), [6, 6, 11, 11]);
		add(bg);

		text = new FlxUIText();
		text.setFormat('VCR OSD Mono', 14);
		add(text);

		changeText();

		alpha = 0;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		var show = false;
		for (sprite => tooltip in addedTooltips)
		{
			if (sprite != null && sprite.exists && sprite.visible && FlxG.mouse.overlaps(sprite))
			{
				if (text.text != tooltip)
					changeText(tooltip);
				show = true;
				break;
			}
		}

		if (show && !showing)
		{
			activateTooltip();
		}
		else if (!show && showing)
		{
			deactivateTooltip();
		}

		if (showing)
		{
			setPosition(FlxMath.bound(FlxG.mouse.globalX - width, 5, FlxG.width - width - 5),
				FlxMath.bound(FlxG.mouse.globalY - height - 2, 5, FlxG.height - height - 5));
		}
	}

	override function destroy()
	{
		super.destroy();
		if (fadeTween != null)
			fadeTween.cancel();
	}

	public function changeText(newText:String = '')
	{
		text.text = newText;
		bg.resize(text.width + 10, text.height + 10);
		text.setPosition(bg.x + (bg.width / 2) - (text.width / 2), bg.y + (bg.height / 2) - (text.height / 2));
	}

	public function addTooltip(sprite:FlxSprite, text:String)
	{
		var sprite:FlxSprite = sprite;
		if (Std.isOfType(sprite, FlxUIDropDownMenu))
		{
			var dropdown:FlxUIDropDownMenu = cast sprite;
			sprite = dropdown.header.background;
		}
		addedTooltips.set(sprite, text);
	}

	function activateTooltip()
	{
		if (fadeTween != null)
			fadeTween.cancel();

		alpha = 0;
		fadeTween = FlxTween.tween(this, {alpha: 1}, 0.15, {
			onComplete: function(_)
			{
				fadeTween = null;
			}
		});

		showing = true;
	}

	function deactivateTooltip()
	{
		if (fadeTween != null)
			fadeTween.cancel();

		alpha = 0;

		showing = false;
	}
}
