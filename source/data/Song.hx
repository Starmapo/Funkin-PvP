package data;

class Song extends JsonObject
{
	public var songName:String;
	public var scrollSpeed:Float;
	public var timingPoints:Array<TimingPoint> = [];
	public var sliderVelocities:Array<SliderVelocity> = [];
	public var notes:Array<NoteInfo> = [];

	public function new(data:Dynamic)
	{
		songName = readString(data.songName);
		scrollSpeed = readFloat(data.scrollSpeed, 1);
		for (t in readArray(data.timingPoints))
		{
			timingPoints.push(new TimingPoint(t));
		}
		for (s in readArray(data.sliderVelocities))
		{
			sliderVelocities.push(new SliderVelocity(s));
		}
		for (n in readArray(data.notes))
		{
			notes.push(new NoteInfo(n));
		}
	}
}

class TimingPoint extends JsonObject
{
	public var startTime:Float;
	public var bpm:Float;
	public var meter:Int;

	public function new(data:Dynamic)
	{
		startTime = readFloat(data.startTime);
		bpm = readFloat(data.bpm, 120);
		meter = readInt(data.meter, 4);
	}
}

class SliderVelocity extends JsonObject
{
	public var startTime:Float;
	public var multiplier:Float;

	public function new(data:Dynamic)
	{
		startTime = readFloat(data.startTime);
		multiplier = readFloat(data.multiplier, 1);
	}
}

class NoteInfo extends JsonObject
{
	public var startTime:Int = 0;
	public var lane:Int = 0;
	public var endTime:Int = 0;
	public var type:String = '';
	public var params:String = '';

	public function new(data:Dynamic)
	{
		startTime = readInt(data.startTime);
		lane = readInt(data.lane);
		endTime = readInt(data.endTime);
		type = readString(data.type);
		params = readString(data.params);
	}
}
