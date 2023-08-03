package backend.structures.song;

class LyricStep extends JsonObject implements ITimingObject
{
	public var startTime:Float;
	
	public function new(data:Dynamic)
	{
		startTime = readFloat(data.startTime, 0, 0);
	}
}
