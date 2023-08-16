package objects;

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
			if (data.prefix != null && data.prefix.length > 0)
			{
				animation.addByIndices(data.name, data.prefix, data.indices, '', data.fps, data.loop, data.flipX, data.flipY);
			}
			else
				animation.add(data.name, data.indices, data.fps, data.loop, data.flipX, data.flipY);
		}
		else
			animation.addByPrefix(data.name, data.prefix, data.fps, data.loop, data.flipX, data.flipY);
			
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
	?prefix:String,
	?indices:Array<Int>,
	?fps:Int,
	?loop:Bool,
	?flipX:Bool,
	?flipY:Bool,
	?offset:Array<Float>
}
