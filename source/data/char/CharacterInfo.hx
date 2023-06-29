package data.char;

import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import haxe.io.Path;
import sys.io.File;

using StringTools;

class CharacterInfo extends JsonObject
{
	public static function loadCharacter(path:String, ?mod:String):CharacterInfo
	{
		if (!Paths.exists(path))
			return null;

		var json:Dynamic = Paths.getJson(path, mod);
		if (json == null)
			return null;

		var converted = false;
		if (json.sing_duration != null)
		{
			json = convertPsychCharacter(json);
			converted = true;
		}

		var charInfo = new CharacterInfo(json);
		charInfo.directory = Path.normalize(Path.directory(path));
		charInfo.name = new Path(path).file;
		charInfo.mod = charInfo.directory.split('/')[1];
		charInfo.sortAnims();
		if (converted)
			charInfo.save(path);
		return charInfo;
	}

	public static function loadCharacterFromName(name:String):CharacterInfo
	{
		var nameInfo = CoolUtil.getNameInfo(name);
		if (nameInfo.mod.length > 0)
		{
			var path = Paths.getPath('data/characters/${nameInfo.name}.json', nameInfo.mod);
			if (Paths.exists(path))
				return loadCharacter(path);
		}

		var path = Paths.getPath('data/characters/$name.json');
		if (Paths.exists(path))
			return loadCharacter(path);

		return loadCharacter(Paths.getPath('data/characters/$name.json', 'fnf'));
	}

	static function convertPsychCharacter(json:Dynamic)
	{
		var charInfo:Dynamic = {
			anims: [],
			image: json.image,
			scale: json.scale,
			healthIcon: json.healthicon,
			positionOffset: json.position.copy(),
			flipX: json.flip_x,
			antialiasing: json.no_antialiasing == false,
			healthColors: json.healthbar_colors,
			danceAnims: ['idle']
		};

		var jsonAnims:Array<Dynamic> = json.animations;
		var animMap = new Map<String, Bool>();
		for (anim in jsonAnims)
		{
			charInfo.anims.push({
				name: anim.anim,
				atlasName: anim.name,
				fps: anim.fps,
				loop: anim.loop,
				indices: anim.indices,
				offset: anim.offsets.copy(),
				nextAnim: ''
			});
			animMap.set(anim.anim, true);
		}
		if (animMap.exists('danceLeft') && animMap.exists('danceRight'))
			charInfo.danceAnims = ['danceLeft', 'danceRight'];

		var anims:Array<Dynamic> = charInfo.anims;
		for (anim in anims)
		{
			var loopName = anim.name + '-loop';
			if (animMap.exists(loopName))
				anim.nextAnim = loopName;
		}

		return charInfo;
	}

	public var image:String;
	public var anims:Array<AnimInfo> = [];
	public var danceAnims:Array<String>;
	public var flipX:Bool;
	public var scale:Float;
	public var antialiasing:Bool;
	public var positionOffset:Array<Float>;
	public var cameraOffset:Array<Float>;
	public var healthIcon:String;
	public var healthColors:FlxColor;
	public var loopAnimsOnHold:Bool;
	public var holdLoopPoint:Int;
	public var flipAll:Bool;
	public var constantLooping:Bool;
	public var directory:String = '';
	public var name:String = '';
	public var mod:String = '';

	public function new(data:Dynamic)
	{
		image = readString(data.image, 'characters/dad');
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
		healthColors = readColor(data.healthColors, FlxColor.fromRGB(161, 161, 161), false);
		loopAnimsOnHold = readBool(data.loopAnimsOnHold, true);
		holdLoopPoint = readInt(data.holdLoopPoint, 0, 0);
		flipAll = readBool(data.flipAll);
		constantLooping = readBool(data.constantLooping);
	}

	override function destroy()
	{
		anims = FlxDestroyUtil.destroyArray(anims);
		danceAnims = null;
		positionOffset = null;
		cameraOffset = null;
	}

	public function sortAnims()
	{
		anims.sort(function(a, b)
		{
			return CoolUtil.sortAlphabetically(a.name, b.name);
		});
	}

	public function save(path:String)
	{
		var data:Dynamic = {
			image: image,
			anims: [],
			positionOffset: positionOffset,
			cameraOffset: cameraOffset,
			healthIcon: healthIcon,
			healthColors: [healthColors.red, healthColors.green, healthColors.blue],
		}
		if (danceAnims.length > 1 || danceAnims[0] != 'idle')
			data.danceAnims = danceAnims;
		if (scale != 1)
			data.scale = scale;
		if (flipX)
			data.flipX = flipX;
		if (!antialiasing)
			data.antialiasing = antialiasing;
		if (!loopAnimsOnHold)
			data.loopAnimsOnHold = loopAnimsOnHold;
		if (holdLoopPoint != 0)
			data.holdLoopPoint = holdLoopPoint;
		if (flipAll)
			data.flipAll = flipAll;
		if (constantLooping)
			data.constantLooping = constantLooping;

		for (anim in anims)
		{
			var animData:Dynamic = {
				name: anim.name,
				atlasName: anim.atlasName,
				offset: anim.offset
			}
			if (anim.indices.length > 0)
				animData.indices = anim.indices;
			if (anim.fps != 24)
				animData.fps = anim.fps;
			if (anim.loop)
				animData.loop = anim.loop;
			if (anim.nextAnim.length > 0)
				animData.nextAnim = anim.nextAnim;

			data.anims.push(animData);
		}
		File.saveContent(path, Json.stringify(data, "\t"));
	}

	public function getAnim(name:String)
	{
		if (name == null)
			return null;

		for (anim in anims)
		{
			if (anim.name == name)
				return anim;
		}

		return null;
	}
}

class AnimInfo extends JsonObject
{
	public var name:String;
	public var atlasName:String;
	public var indices:Array<Int>;
	public var fps:Float;
	public var loop:Bool;
	public var flipX:Bool;
	public var flipY:Bool;
	public var offset:Array<Float>;
	public var nextAnim:String;

	public function new(data:Dynamic)
	{
		name = readString(data.name);
		atlasName = readString(data.atlasName);
		indices = readIntArray(data.indices, [], null, null, 0);
		fps = readFloat(data.fps, 24, 0, 1000, 2);
		loop = readBool(data.loop);
		flipX = readBool(data.flipX);
		flipY = readBool(data.flipY);
		offset = readFloatArray(data.offset, [0, 0], null, 2, null, null, 2);
		nextAnim = readString(data.nextAnim);
	}

	override function destroy()
	{
		indices = null;
		offset = null;
	}
}
