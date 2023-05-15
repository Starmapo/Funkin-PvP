package data.skin;

import flixel.util.FlxDestroyUtil;

/**
	Configuration for a note skin.
**/
class NoteSkin extends JsonObject
{
	/**
		The list of receptor configurations.
	**/
	public var receptors:Array<ReceptorData> = [];

	/**
		The name of the image for the receptors.
	**/
	public var receptorsImage:String;

	/**
		The offset for the receptors positions.
	**/
	public var receptorsOffset:Array<Float>;

	/**
		Extra horizontal padding for the receptors.
	**/
	public var receptorsPadding:Float;

	/**
		The scale for the receptors.
	**/
	public var receptorsScale:Float;

	/**
		Whether or not the receptors graphic is automatically centered when the pressed/confirm animation is played.
	**/
	public var receptorsCenterAnimation:Bool;

	public var notes:Array<NoteData> = [];
	public var notesImage:String;
	public var notesScale:Float;
	public var judgementsSkin:String;
	public var judgementsScale:Float;
	public var splashes:Array<SplashData> = [];
	public var splashesImage:String;
	public var splashesScale:Float;

	/**
		Whether or not the sprites have antialiasing.
	**/
	public var antialiasing:Bool;

	public function new(data:Dynamic)
	{
		for (r in readArray(data.receptors, null, null, 4))
		{
			if (r != null)
				receptors.push(new ReceptorData(r));
		}
		receptorsCenterAnimation = readBool(data.receptorsCenterAnimation, true);
		receptorsImage = readString(data.receptorsImage, 'notes/default');
		receptorsOffset = readFloatArray(data.receptorsOffset, [0, 0], null, 2, -1000, 1000, 2);
		receptorsPadding = readFloat(data.receptorsPadding, 0, -1000, 1000, 2);
		receptorsScale = readFloat(data.receptorsScale, 1, 0.01, 100, 2);
		for (n in readArray(data.notes, null, null, 4))
		{
			if (n != null)
				notes.push(new NoteData(n));
		}
		notesImage = readString(data.notesImage, 'notes/default');
		notesScale = readFloat(data.notesScale, 1, 0.01, 100, 2);
		judgementsSkin = readString(data.judgementsSkin, 'base');
		judgementsScale = readFloat(data.judgementsScale, 1, 0.01, 100, 2);
		for (s in readArray(data.splashes, null, null, 4))
		{
			if (s != null)
				splashes.push(new SplashData(s));
		}
		splashesImage = readString(data.splashesImage, 'splashes/noteSplashes');
		splashesScale = readFloat(data.splashesScale, 1, 0.01, 100, 2);
		antialiasing = readBool(data.antialiasing, true);
	}

	override function destroy()
	{
		receptors = FlxDestroyUtil.destroyArray(receptors);
		receptorsOffset = null;
		notes = FlxDestroyUtil.destroyArray(notes);
		splashes = FlxDestroyUtil.destroyArray(splashes);
	}
}

class ReceptorData extends JsonObject
{
	/**
		The name for the static animation in the spritesheet.
	**/
	public var staticAnim:String;

	/**
		The name for the pressed animation in the spritesheet.
	**/
	public var pressedAnim:String;

	/**
		The name for the confirm animation in the spritesheet.
	**/
	public var confirmAnim:String;

	/**
		The FPS for the static animation.
	**/
	public var staticFPS:Float;

	/**
		The FPS for the pressed animation.
	**/
	public var pressedFPS:Float;

	/**
		The FPS for the confirm animation.
	**/
	public var confirmFPS:Float;

	/**
		The offset for the static animation. Overrides `receptorsCenterAnimation`.
	**/
	public var staticOffset:Array<Float>;

	/**
		The offset for the pressed animation. Overrides `receptorsCenterAnimation`.
	**/
	public var pressedOffset:Array<Float>;

	/**
		The offset for the confirm animation. Overrides `receptorsCenterAnimation`.
	**/
	public var confirmOffset:Array<Float>;

	public function new(data:Dynamic)
	{
		staticAnim = readString(data.staticAnim);
		pressedAnim = readString(data.pressedAnim);
		confirmAnim = readString(data.confirmAnim);
		staticFPS = readFloat(data.staticFPS, 0, 0, 1000, 2);
		pressedFPS = readFloat(data.pressedFPS, 24, 0, 1000, 2);
		confirmFPS = readFloat(data.confirmFPS, 24, 0, 1000, 2);
		staticOffset = readFloatArray(data.staticOffset, [], null, 2, null, null, 2);
		pressedOffset = readFloatArray(data.pressedOffset, [], null, 2, null, null, 2);
		confirmOffset = readFloatArray(data.confirmOffset, [], null, 2, null, null, 2);
	}

	override function destroy()
	{
		staticOffset = null;
		pressedOffset = null;
		confirmOffset = null;
	}
}

class NoteData extends JsonObject
{
	public var headAnim:String;
	public var bodyAnim:String;
	public var tailAnim:String;

	public function new(data:Dynamic)
	{
		headAnim = readString(data.headAnim);
		bodyAnim = readString(data.bodyAnim);
		tailAnim = readString(data.tailAnim);
	}
}

class SplashData extends JsonObject
{
	public var anim:String;
	public var fps:Float;
	public var offset:Array<Float>;

	public function new(data:Dynamic)
	{
		anim = readString(data.anim);
		fps = readFloat(data.fps, 24, 0, 1000, 2);
		offset = readFloatArray(data.offset, [], null, 2, null, null, 2);
	}
}
