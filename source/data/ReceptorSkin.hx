package data;

class ReceptorSkin extends JsonObject
{
	public var receptors:Array<ReceptorData> = [];
	public var receptorsCenterAnimation:Bool;
	public var receptorsImage:String;
	public var receptorsOffset:Array<Float>;
	public var receptorsPadding:Float;
	public var receptorsScale:Float;
	public var antialiasing:Bool;

	public function new(data:Dynamic)
	{
		for (r in readArray(data.receptors))
		{
			receptors.push(new ReceptorData(r));
		}
		receptorsCenterAnimation = readBool(data.receptorsCenterAnimation, true);
		receptorsImage = readString(data.receptorsImage, 'NOTE_assets');
		receptorsOffset = cast readArray(data.receptorsOffset, [0.0, 0.0]);
		receptorsPadding = readFloat(data.receptorsPadding);
		receptorsScale = readFloat(data.receptorsScale, 1);
		antialiasing = readBool(data.antialiasing, true);
	}
}

class ReceptorData extends JsonObject
{
	public var staticAnim:String;
	public var pressedAnim:String;
	public var confirmAnim:String;
	public var staticFPS:Float;
	public var pressedFPS:Float;
	public var confirmFPS:Float;
	public var staticOffset:Array<Float>;
	public var pressedOffset:Array<Float>;
	public var confirmOffset:Array<Float>;

	public function new(data:Dynamic)
	{
		staticAnim = readString(data.staticAnim);
		pressedAnim = readString(data.pressedAnim);
		confirmAnim = readString(data.confirmAnim);
		staticFPS = readFloat(data.staticFPS);
		pressedFPS = readFloat(data.pressedFPS);
		confirmFPS = readFloat(data.confirmFPS);
		staticOffset = cast readArray(data.staticOffset, [0.0, 0.0]);
		pressedOffset = cast readArray(data.pressedOffset, [0.0, 0.0]);
		confirmOffset = cast readArray(data.confirmOffset, [0.0, 0.0]);
	}
}
