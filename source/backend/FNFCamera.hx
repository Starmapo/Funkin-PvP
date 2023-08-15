package backend;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;

class FNFCamera extends FlxCamera
{
	public function new(x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
	{
		super(x, y, width, height, zoom);
		followLerp = 1;
	}
	
	override function updateFollow():Void
	{
		if (followLerp >= 1 || followLerp == 0)
		{
			super.updateFollow();
			return;
		}
		
		final daFollowLerp = followLerp;
		followLerp = 0;
		
		super.updateFollow();
		
		followLerp = daFollowLerp;
		
		final lerp = camLerp(followLerp);
		scroll.x += (_scrollTarget.x - scroll.x) * lerp;
		scroll.y += (_scrollTarget.y - scroll.y) * lerp;
	}
	
	override function follow(target:FlxObject, ?style:FlxCameraFollowStyle, ?lerp:Float):Void
	{
		if (lerp == null)
			lerp = 1;
			
		super.follow(target, style, lerp);
	}
	
	override function set_followLerp(Value:Float):Float
	{
		return followLerp = FlxMath.bound(Value, 0, 1);
	}
	
	function camLerp(lerp:Float)
	{
		return lerp * (FlxG.elapsed / (1 / 60));
	}
}
