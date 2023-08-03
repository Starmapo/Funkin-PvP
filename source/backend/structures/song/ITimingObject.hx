package backend.structures.song;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

interface ITimingObject extends IFlxDestroyable
{
	var startTime:Float;
	function destroy():Void;
}
