package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

// unfortunately idk how to make this an actual transition in FlxTransitionableState
class VoidTransition extends FlxSpriteGroup
{
	var transIn:Bool;
	var onComplete:Void->Void;
	
	public function new(transIn:Bool = false, ?onComplete:Void->Void)
	{
		super();
		this.transIn = transIn;
		this.onComplete = onComplete;
		
		var black = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(black);
		
		var staticBG = new FlxSprite();
		staticBG.frames = Paths.getSpritesheet('stages/static');
		staticBG.animation.add('idle', [4, 9, 2], 8);
		staticBG.animation.play('idle');
		staticBG.setGraphicSize(FlxG.width, FlxG.height);
		staticBG.updateHitbox();
		add(staticBG);
		
		var image = Paths.getImage('menus/pvp/voidTransition');
		var void = new FlxSprite().loadGraphic(image, true, image.width, Std.int(image.height / 3));
		void.animation.add('idle', [0, 1, 2], 8);
		void.animation.play('idle');
		void.screenCenter(X);
		add(void);
		
		scrollFactor.set();
		
		if (transIn)
		{
			void.flipY = true;
			void.y += 1;
			staticBG.y = black.y = void.height + 1;
			y -= void.height;
			FlxTween.tween(this, {y: FlxG.height}, Main.getTransitionTime(), {onComplete: complete});
		}
		else
		{
			void.y = black.height - 1;
			y -= height;
			FlxTween.tween(this, {y: 0}, Main.getTransitionTime(), {onComplete: complete});
		}
	}
	
	override function destroy()
	{
		super.destroy();
		onComplete = null;
	}
	
	function complete(_)
	{
		if (onComplete != null)
			onComplete();
		if (transIn)
		{
			FlxG.state.remove(this);
			for (spr in members)
			{
				var g = spr.graphic;
				spr.graphic = null;
				FlxG.bitmap.removeIfNoUse(g);
			}
			destroy();
		}
	}
}
