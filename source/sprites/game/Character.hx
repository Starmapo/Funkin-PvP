package sprites.game;

import data.char.CharacterInfo;
import flixel.animation.FlxAnimationController;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer;
import ui.game.Note;

class Character extends DancingSprite
{
	static var holdTime:Float = ((1 / 24) * 4);

	public var charInfo(default, set):CharacterInfo;
	public var charPosX:Float;
	public var charPosY:Float;
	public var flipped(default, null):Bool;
	public var debugMode:Bool = false;
	public var startWidth:Float;
	public var startHeight:Float;
	public var state:CharacterState = Idle;
	public var singAnimations:Array<String>;
	public var holdTimers:Array<FlxTimer> = [];
	public var allowDanceTimer:FlxTimer = new FlxTimer();
	public var allowMissColor:Bool = true;
	public var intendedColor:FlxColor = FlxColor.WHITE;
	public var isGF:Bool;
	public var camOffset:FlxPoint = FlxPoint.get();
	public var danceDisabled:Bool = false;

	var xDifference:Float = 0;

	public function new(x:Float = 0, y:Float = 0, charInfo:CharacterInfo, flipped:Bool = false, isGF:Bool = false)
	{
		super(x, y);
		if (charInfo == null)
			charInfo = CharacterInfo.loadCharacterFromName('fnf:bf');
		this.flipped = flipped;
		this.isGF = isGF;
		this.charInfo = charInfo;
		setCharacterPosition(x, y);
	}

	override function playAnim(name, force = false, reversed = false, frame = 0)
	{
		stopAnimCallback();
		super.playAnim(name, force, reversed, frame);
	}

	override function animPlayed(name:String)
	{
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

	override function updateOffset()
	{
		super.updateOffset();

		if (flipped)
			offset.x -= (startWidth - width);
	}

	override function danced(_)
	{
		state = Idle;
		resetColor();
		setCamOffsetFromLane();
	}

	public function setCharacterPosition(x:Float, y:Float)
	{
		charPosX = x;
		charPosY = y;
		updatePosition();
	}

	public function updatePosition()
	{
		if (flipped && !isGF)
			x = charPosX - charInfo.positionOffset[0] + xDifference;
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

	public function playNoteAnim(note:Note, beatLength:Float)
	{
		var lane = note.info.playerLane;
		playSingAnim(lane, beatLength, false, note.animSuffix);

		if (note.info.isLongNote)
		{
			if (holdTimers[lane] != null)
				holdTimers[lane].cancel();

			holdTimers[lane] = new FlxTimer().start(holdTime / FlxAnimationController.globalSpeed, function(tmr)
			{
				if (note.exists && note.currentlyBeingHeld && note.tail.visible)
					playSingAnim(lane, beatLength, true, note.animSuffix);
				else
				{
					tmr.cancel();
					holdTimers[lane] = null;
				}
			}, 0);
		}
	}

	public function playSingAnim(lane:Int, beatLength:Float, hold:Bool = false, suffix:String = '')
	{
		if (lane < 0 || lane > singAnimations.length - 1)
			return;

		var anim = singAnimations[lane] + suffix;
		if (!animation.exists(anim) && suffix.length > 0)
			anim = singAnimations[lane];

		if (animation.exists(anim))
		{
			canDance = false;
			state = Sing(lane);
			playAnim(anim, charInfo.loopAnimsOnHold || !hold, false, hold ? charInfo.holdLoopPoint : 0);
			resetColor();
			setCamOffsetFromLane(lane);

			if (allowDanceTimer.active)
				allowDanceTimer.cancel();
			allowDanceTimer.start((beatLength / 1000) * 1.5, function(_)
			{
				if (!danceDisabled)
				{
					canDance = true;
					dance();
				}
			});
		}
	}

	public function playMissAnim(lane:Int)
	{
		if (lane < 0 || lane > singAnimations.length - 1)
			return;

		var anim = singAnimations[lane] + 'miss';
		var fallback = false;
		if (!animation.exists(anim) && allowMissColor)
		{
			anim = singAnimations[lane];
			fallback = true;
		}
		if (animation.exists(anim))
		{
			if (allowDanceTimer.active)
				allowDanceTimer.cancel();

			canDance = false;
			state = Miss(lane);
			playAnim(anim, true, false);
			if (fallback)
				setMissColor();
			else
				resetColor();
			setCamOffsetFromLane();

			animation.finishCallback = function(_)
			{
				if (!danceDisabled)
				{
					canDance = true;
					dance();
				}
			}
		}
	}

	public function playSpecialAnim(name:String, allowDanceTime:Float = 0, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		if (!animation.exists(name))
			return;

		if (allowDanceTimer.active)
			allowDanceTimer.cancel();

		canDance = false;
		state = Special;
		playAnim(name, force, reversed, frame);
		resetColor();
		setCamOffsetFromLane();

		if (allowDanceTime > 0)
		{
			allowDanceTimer.start(allowDanceTime, function(_)
			{
				if (!danceDisabled)
				{
					canDance = true;
					dance();
				}
			});
		}
		else
		{
			animation.finishCallback = function(_)
			{
				if (!danceDisabled)
				{
					canDance = true;
					dance();
				}
				else
					stopAnimCallback();
			}
		}
	}

	public function doColorTween(duration:Float, fromColor:FlxColor, toColor:FlxColor, options:TweenOptions)
	{
		if (options == null)
			options = {type: ONESHOT};

		allowMissColor = false;
		FlxTween.color(this, duration, fromColor, toColor, {
			type: options.type,
			ease: options.ease,
			onStart: options.onStart,
			onUpdate: function(twn)
			{
				intendedColor = color;

				if (options.onUpdate != null)
					options.onUpdate(twn);
			},
			onComplete: function(twn)
			{
				allowMissColor = true;

				if (options.onComplete != null)
					options.onComplete(twn);
			},
			startDelay: options.startDelay,
			loopDelay: options.loopDelay
		});
	}

	public function setMissColor()
	{
		color = 0xFF565694;
	}

	public function resetColor()
	{
		color = intendedColor;
	}

	override function destroy()
	{
		super.destroy();
		charInfo = FlxDestroyUtil.destroy(charInfo);
		singAnimations = null;
		holdTimers = FlxDestroyUtil.destroyArray(holdTimers);
		allowDanceTimer = FlxDestroyUtil.destroy(allowDanceTimer);
		camOffset = FlxDestroyUtil.put(camOffset);
	}

	function initializeCharacter()
	{
		frames = Paths.getSpritesheet(charInfo.image, charInfo.mod);
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
				offset = [-offset[0], offset[1]];

			addAnim({
				name: anim.name,
				atlasName: anim.atlasName,
				indices: anim.indices.copy(),
				fps: anim.fps,
				loop: anim.loop,
				offset: offset
			});

			if (charInfo.psych && charInfo.scale != 1)
			{
				playAnim(anim.name, true);
				var offset = offsets.get(anim.name);
				offset[0] += (graphicWidth - frameWidth) / 2;
				offset[1] += (graphicHeight - frameHeight) / 2;
			}
		}

		state = Idle;
		danceStep = 0;
		playAnim(danceAnims[0], true);
		animation.finish();
		startWidth = width;
		startHeight = height;
		updateOffset();
		resetColor();

		xDifference = (429 - startWidth);
		updatePosition();

		if (flipped)
			singAnimations = ['singRIGHT', 'singDOWN', 'singUP', 'singLEFT'];
		else
			singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

		danceBeats = danceAnims.length > 1 ? 1 : 2;
	}

	function setCamOffsetFromLane(lane:Int = -1)
	{
		var offset = 15;
		switch (lane)
		{
			case 0:
				camOffset.set(-offset, 0);
			case 1:
				camOffset.set(0, offset);
			case 2:
				camOffset.set(0, -offset);
			case 3:
				camOffset.set(offset, 0);
			default:
				camOffset.set();
		}
	}

	function set_charInfo(value:CharacterInfo)
	{
		if (value != null && charInfo != value)
		{
			charInfo = value;
			initializeCharacter();
		}
		return value;
	}
}

enum CharacterState
{
	Idle;
	Sing(direction:Int);
	Miss(direction:Int);
	Special;
}
