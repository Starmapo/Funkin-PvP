package data.char;

import haxe.Json;
import haxe.io.Path;
import sys.io.File;

using StringTools;

class CharacterInfo extends JsonObject
{
	public static function loadCharacter(path:String, ?mod:String)
	{
		if (!Paths.exists(path))
			return null;

		var json:Dynamic = Paths.getJson(path, mod);
		if (json == null)
			return null;

		if (json.sing_duration != null)
			json = convertPsychCharacter(json);

		var charInfo = new CharacterInfo(json);
		charInfo.directory = Path.normalize(Path.directory(path));
		charInfo.charName = new Path(path).file;
		charInfo.mod = charInfo.directory.split('/')[1];
		charInfo.sortAnims();
		return charInfo;
	}

	public static function loadCharacterFromName(name:String)
	{
		var colonIndex = name.indexOf(':');
		if (colonIndex > -1)
		{
			var mod = name.substr(0, colonIndex);
			var charName = name.substr(colonIndex + 1);
			var path = 'mods/$mod/data/characters/$charName.json';
			trace(path);
			return loadCharacter(path);
		}

		var path = 'mods/${Mods.currentMod}/data/characters/$name.json';
		if (Paths.exists(path))
			return loadCharacter(path);

		return loadCharacter('mods/fnf/data/characters/$name.json');
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
	public var healthColors:Array<Int>;
	public var loopAnimsOnHold:Bool;
	public var holdLoopPoint:Int;
	public var directory:String = '';
	public var charName:String = '';
	public var mod:String = '';

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

	public function sortAnims()
	{
		anims.sort(function(a, b)
		{
			var animA = a.name.toLowerCase();
			var animB = b.name.toLowerCase();
			if (animA < animB)
				return -1;
			if (animA > animB)
				return 1;
			return 0;
		});
	}

	public function save(path:String)
	{
		var data:Dynamic = {
			image: image,
			anims: [],
			danceAnims: danceAnims,
			flipX: flipX,
			scale: scale,
			antialiasing: antialiasing,
			positionOffset: positionOffset,
			cameraOffset: cameraOffset,
			healthIcon: healthIcon,
			healthColors: healthColors,
			loopAnimsOnHold: loopAnimsOnHold,
			holdLoopPoint: holdLoopPoint,
		}
		for (anim in anims)
		{
			data.anims.push({
				name: anim.name,
				atlasName: anim.atlasName,
				indices: anim.indices,
				fps: anim.fps,
				loop: anim.loop,
				offset: anim.offset,
				nextAnim: anim.nextAnim
			});
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
