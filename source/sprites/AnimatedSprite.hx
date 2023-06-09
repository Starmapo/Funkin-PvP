package sprites;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

using StringTools;

/**
	Handy utilities for animated sprites.
**/
class AnimatedSprite extends FlxSprite
{
	public var offsets:Map<String, Array<Float>> = new Map();
	public var offsetScale:FlxPoint = FlxPoint.get(1, 1);

	/**
		Gets dispatched when this sprite plays an animation.
	**/
	public var onAnimPlayed:FlxTypedSignal<String->Void> = new FlxTypedSignal();

	public function new(x:Float = 0, y:Float = 0, ?frames:FlxAtlasFrames, scale:Float = 1)
	{
		super(x, y);
		if (frames != null)
			this.frames = frames;
		this.scale.set(scale, scale);
	}

	/**
		Adds a new animation using `AnimData`.
	**/
	public function addAnim(data:AnimData, baseAnim:Bool = false)
	{
		data = resolveAnimData(data);

		if (data.indices != null && data.indices.length > 0)
		{
			if (data.atlasName != null && data.atlasName.length > 0)
			{
				if (data.atlasName.startsWith('prefix:'))
					animation.addByIndices(data.name, data.atlasName.substr(7), data.indices, '', data.fps, data.loop, data.flipX, data.flipY);
				else
					animation.addByAtlasNameIndices(data.name, data.atlasName, data.indices, data.fps, data.loop, data.flipX, data.flipY);
			}
			else
				animation.add(data.name, data.indices, data.fps, data.loop, data.flipX, data.flipY);
		}
		else
		{
			if (data.atlasName.startsWith('prefix:'))
				animation.addByPrefix(data.name, data.atlasName.substr(7), data.fps, data.loop, data.flipX, data.flipY);
			else
				animation.addByAtlasName(data.name, data.atlasName, data.fps, data.loop, data.flipX, data.flipY);
		}

		if (data.offset != null && data.offset.length >= 2)
			addOffset(data.name, data.offset[0], data.offset[1]);

		if (baseAnim)
			playAnim(data.name, true);
	}

	/**
		Plays an animation in this sprite.
		@param name 	The name of the animation.
		@param force 	Whether to force the animation to restart if it's already playing.
		@param reversed Whether to reverse the animation.
		@param frame	The frame to begin playing the animation at.
	**/
	public function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		if (!animation.exists(name))
			return;

		animation.play(name, force, reversed, frame);
		updateOffset();
		animPlayed(name);
		onAnimPlayed.dispatch(name);
	}

	/**
		This function is called after an animation is played. You can override this with whatever you wish.
	**/
	public function animPlayed(name:String) {}

	public function updateOffset()
	{
		updateHitbox();
		var animOffset = offsets.get(animation.name);
		if (animOffset != null)
			offset.add(animOffset[0] * offsetScale.x, animOffset[1] * offsetScale.y);
	}

	public function stopAnimCallback()
	{
		animation.finishCallback = null;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		offsets.set(name, [x, y]);
	}

	override function destroy()
	{
		super.destroy();
		offsets = null;
		offsetScale = FlxDestroyUtil.put(offsetScale);
		FlxDestroyUtil.destroy(onAnimPlayed);
	}

	function resolveAnimData(data:AnimData)
	{
		if (data.fps == null)
			data.fps = 24;

		if (data.loop == null)
			data.loop = true;

		if (data.flipX == null)
			data.flipX = false;

		if (data.flipY == null)
			data.flipY = false;

		return data;
	}
}

typedef AnimData =
{
	/**
		What this animation should be called.
	**/
	name:String,

	/**
		The animation's name in the atlas. Optional if you input `indices`.
	**/
	?atlasName:String,
	/**
		Optional, an array of numbers indicating what frames to play in what order.
	**/
	?indices:Array<Int>,
	/**
		The speed in frames per second that the animation should play at. Defaults to 24.
	**/
	?fps:Float,
	/**
		Whether or not the animation is looped or just plays once. Defaults to true.
	**/
	?loop:Bool,
	/**
		Whether the frames should be flipped horizontally.
	**/
	?flipX:Bool,
	/**
		Whether the frames should be flipped vertically.
	**/
	?flipY:Bool,
	/**
		Optional, an offset for this animation.
	**/
	?offset:Array<Float>
}
