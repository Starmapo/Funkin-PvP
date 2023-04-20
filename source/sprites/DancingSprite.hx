package sprites;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
	A sprite that dances to music. Add its animations, then add it to a timing object and you're good to go.
**/
class DancingSprite extends AnimatedSprite
{
	/**
		The list of animations to go through when dancing, starting from the beginning again once the last animation has been played. If only one animation is in this list, then that animation will just repeat every beat.
	**/
	public var danceAnims:Array<String> = ['idle'];

	/**
		What beats this sprite should dance on. The default is 1, which means it dances every beat.

		For example, 2 would make this sprite dance every 2 beats.
	**/
	public var danceBeats:Int = 1;

	public var canDance:Bool = true;

	/**
		Whether to force a dance animation to restart if it's still playing when a new beat is reached.
	**/
	public var forceRestartDance:Bool = false;

	/**
		The current "step" into the dance animations list.
	**/
	public var danceStep(default, null) = -1;

	/**
		Gets dispatched when this sprite dances.
	**/
	public var onDance:FlxTypedSignal<String->Void> = new FlxTypedSignal();

	override function destroy()
	{
		super.destroy();
		FlxDestroyUtil.destroy(onDance);
	}

	/**
		Makes this sprite play the next dancing animation.
	**/
	public function dance(force:Bool = false)
	{
		setDanceStep(danceStep + 1, force);
	}

	/**
		Manually sets the current dance step.
	**/
	public function setDanceStep(step:Int = 0, force:Bool = false)
	{
		danceStep = FlxMath.wrapInt(step, 0, danceAnims.length - 1);
		playDanceAnim(force);
	}

	/**
		Quickly sets the dance animations for a preset dance type, those being:
		- SINGLE: `['idle']`
		- DOUBLE: `['danceLeft', 'danceRight']`
	**/
	public function setDancePreset(preset:DancePreset, doDance:Bool = true)
	{
		switch (preset)
		{
			case SINGLE:
				danceAnims = ['idle'];
			case DOUBLE:
				danceAnims = ['danceLeft', 'danceRight'];
			default:
				throw 'Invalid dance preset: $preset';
		}
		if (doDance)
			dance();
	}

	function playDanceAnim(force:Bool = false)
	{
		var anim = danceAnims[danceStep];
		if (anim != null)
		{
			playAnim(anim, force || forceRestartDance);
			danced(anim);
			onDance.dispatch(anim);
		}
	}

	/**
		This function is called after this sprite dances. You can override this with whatever you wish.
	**/
	public function danced(name:String) {}
}

enum abstract DancePreset(Int) to Int from Int
{
	var SINGLE = 0;
	var DOUBLE = 1;
}
