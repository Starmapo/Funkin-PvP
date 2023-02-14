package data;

class Song
{
	public var songName:String = '';
	public var scrollSpeed:Float = 1;
	public var timingPoints:Array<TimingPoint> = [];
	public var sliderVelocities:Array<SliderVelocity> = [];
	public var notes:Array<NoteInfo> = [];

	public function new(data:Dynamic)
	{
		songName = data.songName;
		scrollSpeed = data.scrollSpeed;
		for (t in data.timingPoints)
		{
			timingPoints.push(t);
		}
		for (s in data.sliderVelocities)
		{
			sliderVelocities.push(s);
		}
		for (n in data.notes)
		{
			notes.push(n);
		}
	}
}

class TimingPoint
{
	public var startTime:Float = 0;
	public var bpm:Float = 120;
	public var meter:Int = 4;

	public function new(data:Dynamic)
	{
		startTime = data.startTime;
		bpm = data.bpm;
		meter = data.meter;
	}
}

class SliderVelocity
{
	public var startTime:Float = 0;
	public var multiplier:Float = 1;

	public function new(data:Dynamic)
	{
		startTime = data.startTime;
		multiplier = data.multiplier;
	}
}

class NoteInfo
{
	public var startTime:Float = 0;
	public var lane:Int = 0;
	public var endTime:Float = 0;
	public var type:String = '';
	public var params:String = '';

	public function new(data:Dynamic)
	{
		startTime = data.startTime;
		lane = data.lane;
		endTime = data.endTime;
		type = data.type;
		params = data.params;
	}
}
