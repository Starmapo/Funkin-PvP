package data.char;

class CharacterInfo extends JsonObject
{
	public var image:String;
	public var anims:Array<AnimInfo> = [];
	public var danceAnims:Array<String>;
	public var flipX:Bool;
	public var scale:Float;
	public var antialiasing:Bool;
	public var positionOffset:Array<Float>;
	public var cameraOffset:Array<Float>;
	public var healthIcon:String;
	public var healthColors:Array<Int>;
	public var loopAnimsOnHold:Bool;
	public var holdLoopPoint:Int;

	public function new(data:Dynamic)
	{
		image = readString(data.image, 'characters/bf');
		for (a in readArray(data.anims))
		{
			if (a != null)
				anims.push(new AnimInfo(a));
		}
		danceAnims = cast readArray(data.danceAnims, ['idle']);
		flipX = readBool(data.flipX);
		scale = readFloat(data.scale, 1, 0.01, 100, 2);
		antialiasing = readBool(data.antialiasing, true);
		positionOffset = readFloatArray(data.positionOffset, [0, 0], null, 2, null, null, 2);
		cameraOffset = readFloatArray(data.cameraOffset, [0, 0], null, 2, null, null, 2);
		healthIcon = readString(data.healthIcon, 'face');
		healthColors = readIntArray(data.healthColors, [161, 161, 161], null, 3, 0, 255);
		loopAnimsOnHold = readBool(data.loopAnimsOnHold, true);
		holdLoopPoint = readInt(data.holdLoopPoint, 0, 0);
	}
}

class AnimInfo extends JsonObject
{
	public var name:String;
	public var atlasName:String;
	public var indices:Array<Int>;
	public var fps:Float;
	public var loop:Bool;
	public var offset:Array<Float>;
	public var nextAnim:String;

	public function new(data:Dynamic)
	{
		name = readString(data.name);
		atlasName = readString(data.atlasName);
		indices = readIntArray(data.indices, []);
		fps = readFloat(data.fps, 24, 0, 1000, 2);
		loop = readBool(data.loop);
		offset = readFloatArray(data.offset, [0, 0], null, 2, -1000, 1000, 2);
		nextAnim = readString(data.nextAnim);
	}
}
