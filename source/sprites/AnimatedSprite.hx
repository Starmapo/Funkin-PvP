package sprites;

import flixel.FlxSprite;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
	Handy utilities for animated sprites.
**/
class AnimatedSprite extends FlxSprite
{
	/**
		Gets dispatched when this sprite plays an animation.
	**/
	public var onAnimPlayed:FlxTypedSignal<String->Void> = new FlxTypedSignal();

	/**
		Plays an animation in this sprite.
		@param animName The name of the animation.
		@param force 	Whether to force the animation to restart if it's already playing.
		@param reversed Whether to reverse the animation.
		@param frame	The frame to begin playing the animation at.
	**/
	public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		if (!animation.exists(animName))
			return;

		animation.play(animName, force, reversed, frame);

		animPlayed(animName);

		onAnimPlayed.dispatch(animName);
	}

	/**
		This function is called after an animation is played. You can override this with whatever you wish.
	**/
	public function animPlayed(animName:String) {}
}
