package sprites.game;

import data.char.CharacterInfo;
import flixel.util.FlxTimer;
import ui.game.Note;

class Character extends DancingSprite
{
	public var charInfo:CharacterInfo;
	public var charPosX:Float;
	public var charPosY:Float;
	public var flipped(default, set):Bool;
	public var debugMode:Bool = false;
	public var startWidth:Float;
	public var startHeight:Float;
	public var state:CharacterState = IDLE;
	public var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	public var holdTimers:Array<FlxTimer> = [];

	public function new(x:Float = 0, y:Float = 0, charInfo:CharacterInfo, flipped:Bool = false)
	{
		super(x, y);
		this.charInfo = charInfo;
		this.flipped = flipped;
		initializeCharacter();
		setCharacterPosition(x, y);
	}

	override function playAnim(name, force = false, reversed = false, frame = 0)
	{
		stopAnimCallback();
		super.playAnim(name, force, reversed, frame);
	}

	override function animPlayed(name:String)
	{
		if (flipped)
			updatePosition();

		animation.finishCallback = function(name:String)
		{
			if (!debugMode)
			{
				var anim = charInfo.getAnim(name);
				if (anim != null && anim.nextAnim.length > 0)
					playAnim(anim.nextAnim);
				else
					stopAnimCallback();
			}
			else
				stopAnimCallback();
		}
	}

	override function danced(_)
	{
		state = IDLE;
	}

	public function setCharacterPosition(x:Float, y:Float)
	{
		charPosX = x;
		charPosY = y;
		updatePosition();
	}

	public function updatePosition()
	{
		if (flipped)
			x = charPosX - charInfo.positionOffset[0] + (startWidth - width);
		else
			x = charPosX + charInfo.positionOffset[0];

		y = charPosY + charInfo.positionOffset[1];
	}

	public function getCurAnim()
	{
		return charInfo.getAnim(animation.name);
	}

	public function getCurAnimIndex()
	{
		if (animation.name == null)
			return -1;

		for (i in 0...charInfo.anims.length)
		{
			if (charInfo.anims[i].name == animation.name)
				return i;
		}

		return -1;
	}

	public function getCurAnimOffset()
	{
		var anim = getCurAnim();
		if (anim != null && anim.offset.length >= 2)
			return anim.offset;

		return [0, 0];
	}

	public function stopAnimCallback()
	{
		animation.finishCallback = null;
	}

	public function playNoteAnim(note:Note)
	{
		var lane = note.info.playerLane;
		playSingAnim(lane);

		if (note.info.isLongNote)
		{
			if (holdTimers[lane] != null)
				holdTimers[lane].cancel();

			holdTimers[lane] = new FlxTimer().start((1 / 24) * 4, function(tmr)
			{
				if (note.tail.visible)
					playSingAnim(lane, true);
				else
				{
					tmr.cancel();
					holdTimers[lane] = null;
				}
			}, 0);
		}
	}

	public function playSingAnim(lane:Int, hold:Bool = false)
	{
		if (lane < 0 || lane > singAnimations.length - 1)
			return;

		canDance = false;
		state = SING(lane);
		var anim = singAnimations[lane];
		if (animation.exists(anim))
			playAnim(anim, true, false, hold ? charInfo.holdLoopPoint : 0);
	}

	public function playMissAnim(lane:Int)
	{
		if (lane < 0 || lane > singAnimations.length - 1)
			return;

		canDance = false;
		state = SING(lane);
		var anim = singAnimations[lane] + '-miss';
		if (animation.exists(anim))
		{
			playAnim(anim, true, false);
			animation.finishCallback = function(_)
			{
				canDance = true;
				dance();
			}
		}
	}

	public function playSpecialAnim(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		if (!animation.exists(name))
			return;

		canDance = false;
		state = SPECIAL;
		playAnim(name, force, reversed, frame);
		animation.finishCallback = function(_)
		{
			canDance = true;
			dance();
		}
	}

	function initializeCharacter()
	{
		frames = Paths.getSpritesheet(charInfo.image);
		danceAnims = charInfo.danceAnims.copy();
		flipX = charInfo.flipX;
		if (flipped)
			flipX = !flipX;
		antialiasing = charInfo.antialiasing;
		scale.set(charInfo.scale, charInfo.scale);

		for (anim in charInfo.anims)
		{
			var offset = anim.offset.copy();
			if (flipped)
				offset = [-offset[0], -offset[1]];

			addAnim({
				name: anim.name,
				atlasName: anim.atlasName,
				indices: anim.indices.copy(),
				fps: anim.fps,
				loop: anim.loop,
				offset: offset
			});

			if (charInfo.scale != 1)
			{
				playAnim(anim.name, true);
				var offset = offsets.get(anim.name);
				offset[0] += (graphicWidth - frameWidth) / 2;
				offset[1] += (graphicHeight - frameHeight) / 2;
			}
		}

		state = IDLE;
		danceStep = 0;
		playAnim(danceAnims[0], true);
		startWidth = frameWidth;
		startHeight = frameHeight;

		updatePosition();
	}

	function set_flipped(value:Bool)
	{
		if (flipped != value)
		{
			flipped = value;
			if (flipped)
				singAnimations = ['singRIGHT', 'singDOWN', 'singUP', 'singLEFT'];
			else
				singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
		}
		return value;
	}
}

enum CharacterState
{
	IDLE;
	SING(direction:Int);
	MISS(direction:Int);
	SPECIAL;
}
