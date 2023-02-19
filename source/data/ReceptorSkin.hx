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
		for (r in readArray(data.receptors, null, null, 4))
		{
			if (r != null)
				receptors.push(new ReceptorData(r));
		}
		receptorsCenterAnimation = readBool(data.receptorsCenterAnimation, true);
		receptorsImage = readString(data.receptorsImage, 'NOTE_assets');
		receptorsOffset = readFloatArray(data.receptorsOffset, [0, 0], null, 2, -1000, 1000, 2);
		receptorsPadding = readFloat(data.receptorsPadding, 0, -1000, 1000, 2);
		receptorsScale = readFloat(data.receptorsScale, 1, 0.01, 100, 2);
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
		staticFPS = readFloat(data.staticFPS, 0, 0, 1000, 2);
		pressedFPS = readFloat(data.pressedFPS, 0, 0, 1000, 2);
		confirmFPS = readFloat(data.confirmFPS, 0, 0, 1000, 2);
		staticOffset = readFloatArray(data.staticOffset, [0, 0], null, 2, -1000, 1000, 2);
		pressedOffset = readFloatArray(data.pressedOffset, [0, 0], null, 2, -1000, 1000, 2);
		confirmOffset = readFloatArray(data.confirmOffset, [0, 0], null, 2, -1000, 1000, 2);
	}
}
