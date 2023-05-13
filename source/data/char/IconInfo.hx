package data.char;

class IconInfo extends JsonObject
{
	public var frames:Int;
	public var antialiasing:Bool;
	public var positionOffset:Array<Float>;
	public var normalAnim:String;
	public var normalFPS:Float;
	public var losingAnim:String;
	public var losingFPS:Float;
	public var losingOffset:Array<Float>;
	public var winningAnim:String;
	public var winningFPS:Float;
	public var winningOffset:Array<Float>;

	public function new(data:Dynamic)
	{
		frames = readInt(data.frames, 2, 1, 3);
		antialiasing = readBool(data.antialiasing, true);
		positionOffset = readFloatArray(data.positionOffset, [0, 0], null, 2, null, null, 2);
		normalAnim = readString(data.normalAnim);
		normalFPS = readFloat(data.normalFPS, 24, 0, 1000, 2);
		losingAnim = readString(data.losingAnim);
		losingFPS = readFloat(data.losingFPS, 24, 0, 1000, 2);
		losingOffset = readFloatArray(data.losingOffset, [], null, 2, null, null, 2);
		winningAnim = readString(data.winningAnim);
		winningFPS = readFloat(data.winningFPS, 24, 0, 1000, 2);
		winningOffset = readFloatArray(data.winningOffset, [], null, 2, null, null, 2);
	}
}
