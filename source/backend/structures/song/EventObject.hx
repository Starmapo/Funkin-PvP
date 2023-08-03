package backend.structures.song;

import flixel.util.FlxDestroyUtil;

class EventObject extends JsonObject implements ITimingObject
{
	public var startTime:Float;
	public var events:Array<Event> = [];
	
	public function new(data:Dynamic)
	{
		startTime = readFloat(data.startTime, 0, 0);
		for (e in readArray(data.events))
		{
			if (e != null)
				events.push(new Event(e));
		}
	}
	
	override function destroy()
	{
		events = FlxDestroyUtil.destroyArray(events);
	}
}

class Event extends JsonObject
{
	public var event:String;
	public var params:Array<String>;
	
	public function new(data:Dynamic)
	{
		event = readString(data.event);
		params = readString(data.params).split(',');
	}
	
	override function destroy()
	{
		params = null;
	}
}
