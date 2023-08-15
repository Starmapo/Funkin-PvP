package objects;

import backend.FNFAtlasFrames;
import flixel.FlxSprite;
import flixel.animation.FlxAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using StringTools;

class AnimatedSprite extends FlxSprite
{
	static function resolveAnimData(data:AnimData)
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
	
	public var offsets:Map<String, FlxPoint> = new Map();
	
	public var onAnimPlayed:FlxTypedSignal<String->Void> = new FlxTypedSignal();
	
	public var offsetScale:FlxPoint;
	public var offsetAngle:Null<Float>;
	
	public function new(x:Float = 0, y:Float = 0, ?frames:FlxAtlasFrames, scale:Float = 1)
	{
		super(x, y);
		if (frames != null)
			this.frames = frames;
		if (scale != 1)
			this.scale.set(scale, scale);
	}
	
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
					addByAtlasNameIndices(data.name, data.atlasName, data.indices, '', data.fps, data.loop, data.flipX, data.flipY);
			}
			else
				animation.add(data.name, data.indices, data.fps, data.loop, data.flipX, data.flipY);
		}
		else
		{
			if (data.atlasName.startsWith('prefix:'))
				animation.addByPrefix(data.name, data.atlasName.substr(7), data.fps, data.loop, data.flipX, data.flipY);
			else
				addByAtlasName(data.name, data.atlasName, data.fps, data.loop, data.flipX, data.flipY);
		}
		
		if (data.offset != null && data.offset.length >= 2)
			addOffset(data.name, data.offset[0], data.offset[1]);
			
		if (baseAnim)
			playAnim(data.name, true);
	}
	
	public function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		if (name == null || !animation.exists(name))
			return;
		if (animation.name == name && !force && !animation.curAnim.finished)
			return;
			
		_playAnim(name, force, reversed, frame);
		updateOffset();
		animPlayed(name);
		onAnimPlayed.dispatch(name);
	}
	
	public function animPlayed(name:String) {}
	
	public function updateOffset(hitbox:Bool = true)
	{
		if (hitbox)
			updateHitbox();
			
		if (animation.curAnim == null)
			return;
			
		final animOffset = offsets.get(animation.name);
		if (animOffset != null)
			offset.addPoint(calculateOffset(animOffset));
	}
	
	public function stopAnimCallback()
	{
		animation.finishCallback = null;
	}
	
	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		offsets.set(name, FlxPoint.get(x, y));
	}
	
	@:access(flixel.animation.FlxAnimationController)
	public function addByAtlasName(name:String, atlasName:String, frameRate:Float = 30, looped:Bool = true, flipX:Bool = false, flipY:Bool = false):Void
	{
		if (frames != null && Std.isOfType(frames, FNFAtlasFrames))
		{
			final animFrames:Array<FlxFrame> = new Array<FlxFrame>();
			findByAtlasName(animFrames, atlasName); // adds valid frames to animFrames
			
			if (animFrames.length > 0)
			{
				final frameIndices:Array<Int> = new Array<Int>();
				animation.byPrefixHelper(frameIndices, animFrames, atlasName); // finds frames and appends them to the blank array
				
				final anim = new FlxAnimation(animation, name, frameIndices, frameRate, looped, flipX, flipY);
				animation._animations.set(name, anim);
			}
		}
	}
	
	@:access(flixel.animation.FlxAnimationController)
	public function addByAtlasNameIndices(name:String, atlasName:String, indices:Array<Int>, postfix:String, frameRate:Float = 30, looped:Bool = true,
			flipX:Bool = false, flipY:Bool = false):Void
	{
		if (frames != null && Std.isOfType(frames, FNFAtlasFrames))
		{
			final frameIndices:Array<Int> = new Array<Int>();
			// finds frames and appends them to the blank array
			byAtlasNameIndicesHelper(frameIndices, atlasName, indices, postfix);
			
			if (frameIndices.length > 0)
			{
				final anim:FlxAnimation = new FlxAnimation(animation, name, frameIndices, frameRate, looped, flipX, flipY);
				animation._animations.set(name, anim);
			}
		}
	}
	
	public function setOffsetScale(x:Float, y:Float)
	{
		if (offsetScale == null)
			offsetScale = FlxPoint.get();
		offsetScale.set(x, y);
	}
	
	override function destroy()
	{
		scale = FlxDestroyUtil.destroy(scale);
		super.destroy();
		if (offsets != null)
		{
			for (_ => offset in offsets)
				FlxDestroyUtil.put(offset);
			offsets = null;
		}
		FlxDestroyUtil.destroy(onAnimPlayed);
	}
	
	function findByAtlasName(animIndices:Array<FlxFrame>, atlasName:String):Void
	{
		final frames:FNFAtlasFrames = cast frames;
		for (frame in frames.frames)
		{
			if (frame.name != null && frames.checkAtlasName(frame.name, atlasName))
			{
				animIndices.push(frame);
			}
		}
	}
	
	function byAtlasNameIndicesHelper(addTo:Array<Int>, atlasName:String, indices:Array<Int>, postfix:String):Void
	{
		for (index in indices)
		{
			final indexToAdd:Int = findAtlasNameSpriteFrame(atlasName, index, postfix);
			if (indexToAdd != -1)
			{
				addTo.push(indexToAdd);
			}
		}
	}
	
	function findAtlasNameSpriteFrame(atlasName:String, index:Int, postfix:String):Int
	{
		final frames:FNFAtlasFrames = cast frames;
		for (i in 0...frames.frames.length)
		{
			final name = frames.frames[i].name;
			if (frames.checkAtlasName(name, atlasName) && StringTools.endsWith(name, postfix))
			{
				final frameIndex:Null<Int> = Std.parseInt(name.substring(atlasName.length, name.length - postfix.length));
				if (frameIndex == index)
					return i;
			}
		}
		
		return -1;
	}
	
	function calculateOffset(offset:FlxPoint)
	{
		if ((offsetScale == null || offsetScale.equals(scale)) && (offsetAngle == null || angle == offsetAngle))
			return offset;
			
		var newOffset = FlxPoint.weak().copyFrom(offset);
		if (offsetScale != null && !offsetScale.equals(scale))
			newOffset.scale(offsetScale.x / scale.x, offsetScale.y / scale.y);
		if (offsetAngle != null && angle != offsetAngle)
			newOffset.degrees += offsetAngle - angle;
		return newOffset;
	}
	
	function scaleCallback(_)
	{
		if (offsetScale != null)
			updateOffset(false);
	}
	
	function _playAnim(name:String, force:Bool, reversed:Bool, frame:Int)
	{
		animation.play(name, force, reversed, frame);
	}
	
	override function initVars():Void
	{
		flixelType = OBJECT;
		last = FlxPoint.get(x, y);
		scrollFactor = FlxPoint.get(1, 1);
		pixelPerfectPosition = flixel.FlxObject.defaultPixelPerfectPosition;
		
		initMotionVars();
		
		animation = new flixel.animation.FlxAnimationController(this);
		
		_flashPoint = new Point();
		_flashRect = new Rectangle();
		_flashRect2 = new Rectangle();
		_flashPointZero = new Point();
		offset = FlxPoint.get();
		origin = FlxPoint.get();
		scale = new FlxCallbackPoint(scaleCallback);
		_halfSize = FlxPoint.get();
		_matrix = new flixel.math.FlxMatrix();
		colorTransform = new openfl.geom.ColorTransform();
		_scaledOrigin = FlxPoint.get();
		
		scale.set(1, 1);
	}
	
	override function set_angle(value:Float)
	{
		if (angle != value)
		{
			super.set_angle(value);
			if (offsetAngle != null)
				updateOffset(false);
		}
		return value;
	}
}

typedef AnimData =
{
	name:String,
	?atlasName:String,
	?indices:Array<Int>,
	?fps:Int,
	?loop:Bool,
	?flipX:Bool,
	?flipY:Bool,
	?offset:Array<Float>
}
