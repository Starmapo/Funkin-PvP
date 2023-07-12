package data.char;

import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import haxe.io.Path;
import sys.io.File;

using StringTools;

/**
	JSON info for a character.
**/
class CharacterInfo extends JsonObject
{
	/**
		Loads a character file from a path to a JSON file.

		@return	A new `CharacterInfo` object, or `null` if the path doesn't exist or if the JSON file couldn't be parsed.
	**/
	public static function loadCharacter(path:String):CharacterInfo
	{
		if (!Paths.exists(path))
			return null;
			
		var json:Dynamic = Paths.getJson(path);
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
	
	/**
		Loads a character file from a name.

		@param	name	The name of the character to load. If it contains a colon `:`, it will use the name before it as
						the mod directory.
		@return	A new `CharacterInfo` object, or `null` if the file couldn't be found or if the JSON file couldn't be
				parsed.
	**/
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
	
	static function convertPsychCharacter(json:Dynamic):Dynamic
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
	
	/**
		The name of the image file for this character. If it contains a colon `:`, it will use the name before it as the
		mod directory. Defaults to Daddy Dearest's spritesheet.
	**/
	public var image:String;
	
	/**
		An array of animations for this character.
	**/
	public var anims:Array<AnimInfo> = [];
	
	/**
		An array of animation names to use for this character's dance. Defaults to `["idle"]`.
	**/
	public var danceAnims:Array<String>;
	
	/**
		Whether or not the character should be flipped horizontally on the left side. Defaults to `false`.
	**/
	public var flipX:Bool;
	
	/**
		The scaling factor for this character. Defaults to `1`, or no scaling.
	**/
	public var scale:Float;
	
	/**
		Whether or not the character should have antialiasing. Defaults to `true`.
	**/
	public var antialiasing:Bool;
	
	/**
		The position offset for this character. Will be automatically flipped when playing on the right side.
	**/
	public var positionOffset:Array<Float>;
	
	/**
		The camera offset for this character. Will be automatically flipped when playing on the right side.
	**/
	public var cameraOffset:Array<Float>;
	
	/**
		The name for this character's health bar icon. If it contains a colon `:`, it will use the name before it as the
		mod directory. Defaults to `"face"`.
	**/
	public var healthIcon:String;
	
	/**
		The health bar color for this character. Defaults to `0xFFA1A1A1`.
	**/
	public var healthColors:FlxColor;
	
	/**
		Whether or not long notes should repeat the character's sing animation. Defaults to `true`.
	**/
	public var loopAnimsOnHold:Bool;
	
	/**
		The frame index to start the sing animation at for long notes. Defaults to `0`, or from the beginning.
	**/
	public var holdLoopPoint:Int;
	
	/**
		If enabled, the down and up sing animations will also be flipped when this character is on the right side.
		Defaults to `false`.
	**/
	public var flipAll:Bool;
	
	/**
		If enabled, playing an animation will force it to start from the previous animation's frame index + `1`, if there
		was a previous animation. Only useful for running/moving characters. Defaults to `false`.
	**/
	public var constantLooping:Bool;
	
	/**
		The full directory path this character was in.
	**/
	public var directory:String = '';
	
	/**
		The name of the character.
	**/
	public var name:String = '';
	
	/**
		The mod directory this character was in.
	**/
	public var mod:String = '';
	
	/**
		@param	data	The JSON file to parse data from.
	**/
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
		healthColors = readColor(data.healthColors, 0xFFA1A1A1, false);
		loopAnimsOnHold = readBool(data.loopAnimsOnHold, true);
		holdLoopPoint = readInt(data.holdLoopPoint, 0, 0);
		flipAll = readBool(data.flipAll);
		constantLooping = readBool(data.constantLooping);
	}
	
	override function destroy():Void
	{
		anims = FlxDestroyUtil.destroyArray(anims);
		danceAnims = null;
		positionOffset = null;
		cameraOffset = null;
	}
	
	/**
		Gets an animation info by name.

		@return	An `AnimInfo` object, or `null` if the animation couldn't be found.
	**/
	public function getAnim(name:String):AnimInfo
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
	
	/**
		Saves this character info to a JSON file.
	**/
	public function save(path:String):Void
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
	
	/**
		Sorts the animations by name.
	**/
	public function sortAnims():Void
	{
		anims.sort(function(a, b)
		{
			return CoolUtil.sortAlphabetically(a.name, b.name);
		});
	}
}

/**
	JSON info for a character's animation.
**/
class AnimInfo extends JsonObject
{
	/**
		The name of this animation.
	**/
	public var name:String;
	
	/**
		The name of this animation in the character's spritesheet.

		NOTE: This uses the new `addByAtlasName` function instead of `addByPrefix`, which will use frames that have the
		exact animation name (minus the frame numbers) instead of starting with it. If you want to use `addByPrefix`,
		add `prefix:` to the start of the name.
	**/
	public var atlasName:String;
	
	/**
		Optional frame indices for this animation. If `atlasName` is empty, this will be used as indices in the overall
		spritesheet.
	**/
	public var indices:Array<Int>;
	
	/**
		The frame rate, or frames per second, of this animation. Defaults to `24`.
	**/
	public var fps:Float;
	
	/**
		Whether or not this animation should loop. Defaults to `false`.
	**/
	public var loop:Bool;
	
	/**
		Whether or not this animation should be flipped horizontally. Defaults to `false`.
	**/
	public var flipX:Bool;
	
	/**
		Whether or not this animation should be flipped vertically. Defaults to `false`.
	**/
	public var flipY:Bool;
	
	/**
		The visual offset for this animation.

		Values are substracted, so a value of `[5, -10]` will move the graphic 5 pixels left and 10 pixels down.

		Will be automatically flipped when playing on the right side.
	**/
	public var offset:Array<Float>;
	
	/**
		Optional name of the animation to change to after this one is finished.
	**/
	public var nextAnim:String;
	
	/**
		Creates a new `AnimInfo` object.

		@param	data	The JSON file to parse data from.
	**/
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
