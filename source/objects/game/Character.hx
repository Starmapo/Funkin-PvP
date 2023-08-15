package objects.game;

import backend.game.GameplayGlobals;
import backend.structures.char.CharacterInfo;
import flixel.animation.FlxAnimationController;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxTimer;

class Character extends DancingSprite
{
	static final MISS_COLOR:FlxColor = 0xFF565694;
	static final DEFAULT_SING_ANIMS:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	
	public var info(default, set):CharacterInfo;
	public var charPosX(default, set):Float;
	public var charPosY(default, set):Float;
	public var charFlipX(default, set):Bool;
	public var debugMode:Bool = false;
	public var startWidth:Float;
	public var startHeight:Float;
	public var state:CharacterState = Idle;
	public var singAnimations:Array<String> = DEFAULT_SING_ANIMS.copy();
	public var holdTimers:Array<FlxTimer> = [];
	public var allowDanceTimer:FlxTimer = new FlxTimer();
	public var missColor:Bool = true;
	public var isGF:Bool;
	public var camOffset:FlxPoint = FlxPoint.get();
	public var danceDisabled:Bool = false;
	public var singDisabled:Bool = false;
	public var xDifference:Float = 0;
	public var onSing:FlxTypedSignal<Int->Bool->Void> = new FlxTypedSignal();
	
	public function new(x:Float = 0, y:Float = 0, info:CharacterInfo, charFlipX:Bool = false, isGF:Bool = false)
	{
		super(x, y);
		if (info == null)
			makeGraphic(1, 1, FlxColor.TRANSPARENT);
		offsetAngle = 0;
		this.isGF = isGF;
		this.info = info;
		this.charFlipX = charFlipX;
		setCharacterPosition(x, y);
		
		animation.finishCallback = function(name:String)
		{
			if (!debugMode && info != null)
			{
				final anim = info.getAnim(name);
				if (anim != null && anim.nextAnim.length > 0)
					playAnim(anim.nextAnim);
				else if (state == Special && !allowDanceTimer.active)
				{
					canDance = true;
					dance();
				}
			}
		}
	}
	
	public function setCharacterPosition(x:Float = 0, y:Float = 0)
	{
		charPosX = x;
		charPosY = y;
	}
	
	public function updatePosition()
	{
		setPosition(charPosX, charPosY);
		if (info != null)
		{
			final scaleX = (offsetScale != null ? offsetScale.x / scale.x : 1);
			if (charFlipX && !isGF)
				x += (-info.positionOffset[0] + xDifference) * scaleX;
			else
				x += info.positionOffset[0] * scaleX;
				
			final scaleY = (offsetScale != null ? offsetScale.y / scale.y : 1);
			y = charPosY + info.positionOffset[1] * scaleY;
		}
	}
	
	public function getCurAnim()
	{
		if (info == null)
			return null;
		return info.getAnim(animation.name);
	}
	
	public function getCurAnimIndex()
	{
		if (animation.name == null || info == null)
			return -1;
			
		for (i in 0...info.anims.length)
		{
			if (info.anims[i].name == animation.name)
				return i;
		}
		
		return -1;
	}
	
	public function getCurAnimOffset()
	{
		final anim = getCurAnim();
		if (anim != null && anim.offset.length >= 2)
			return anim.offset;
			
		return [0, 0];
	}
	
	public function playNoteAnim(note:Note, beatLength:Float)
	{
		final lane = note.info.playerLane;
		playSingAnim(lane, beatLength, false, note.animSuffix, !note.info.isLongNote);
		
		if (note.info.isLongNote && animation.curAnim != null)
		{
			if (holdTimers[lane] != null)
				holdTimers[lane].cancel();
				
			holdTimers[lane] = new FlxTimer().start(animation.curAnim.frameDuration * 4 / GameplayGlobals.playbackRate, function(tmr)
			{
				if (note.exists && note.currentlyBeingHeld && note.tail.visible)
					playSingAnim(lane, beatLength, true, note.animSuffix, false);
				else
				{
					tmr.cancel();
					holdTimers[lane] = null;
					startDanceTimer(beatLength / 1000);
				}
			}, 0);
		}
	}
	
	public function playSingAnim(lane:Int, beatLength:Float, hold:Bool = false, suffix:String = '', danceTimer:Bool = true)
	{
		if (lane < 0 || lane > singAnimations.length - 1 || singDisabled)
			return;
			
		var anim = singAnimations[lane] + suffix;
		if (!animation.exists(anim) && suffix.length > 0)
			anim = singAnimations[lane];
			
		if (animation.exists(anim))
		{
			canDance = false;
			state = Sing(lane);
			if (!hold || animation.name != anim || info == null || info.loopAnimsOnHold)
				playAnim(anim, true, false, (hold && info != null) ? info.holdLoopPoint : 0);
			resetColor();
			setCamOffsetFromLane(lane);
			
			if (danceTimer)
				startDanceTimer(beatLength / 1000);
			else
				cancelDanceTimer();
				
			onSing.dispatch(lane, hold);
		}
	}
	
	public function playMissAnim(lane:Int, beatLength:Float)
	{
		if (lane < 0 || lane > singAnimations.length - 1 || singDisabled || state == Special)
			return;
			
		var anim = singAnimations[lane] + 'miss';
		var fallback = false;
		if (!animation.exists(anim))
		{
			anim = singAnimations[lane];
			fallback = true;
		}
		if (animation.exists(anim))
		{
			canDance = false;
			state = Miss(lane);
			playAnim(anim, true, false);
			if (fallback)
				setMissColor();
			else
				resetColor();
			setCamOffsetFromLane();
			
			startDanceTimer(beatLength / 1000);
		}
	}
	
	public function playSpecialAnim(name:String, allowDanceTime:Float = 0, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		if (name == null || !animation.exists(name))
			return;
		if (animation.name == name && !force && !animation.curAnim.finished)
			return;
			
		cancelDanceTimer();
		
		canDance = false;
		state = Special;
		playAnim(name, force, reversed, frame);
		resetColor();
		setCamOffsetFromLane();
		
		if (allowDanceTime > 0)
			startDanceTimer(allowDanceTime);
	}
	
	public function doColorTween(duration:Float, fromColor:FlxColor, toColor:FlxColor, ?options:TweenOptions)
	{
		CoolUtil.tweenColor(this, duration, fromColor, toColor, options);
	}
	
	public function setMissColor()
	{
		missColor = true;
	}
	
	public function resetColor()
	{
		missColor = false;
	}
	
	public function initializeCharacter()
	{
		if (info == null)
			return;
			
		final lastAnim = animation.name;
		final lastFrame = animation.curAnim != null ? animation.curAnim.curFrame : 0;
		
		danceAnims = info.danceAnims.copy();
		antialiasing = info.antialiasing && Settings.antialiasing;
		scale.set(info.scale, info.scale);
		setOffsetScale(info.scale, info.scale);
		reloadImage();
		
		resetColor();
		danceBeats = danceAnims.length > 1 ? 1 : 2;
		
		if (lastAnim != null && animation.exists(lastAnim))
			playAnim(lastAnim, true, false, lastFrame);
		else if (state != Idle)
		{
			state = Idle;
			cancelDanceTimer();
			canDance = true;
		}
	}
	
	public function reloadImage()
	{
		if (info == null)
			return;
			
		final nameInfo = CoolUtil.getNameInfo(info.image, info.mod);
		var daFrames = Paths.getSpritesheet(nameInfo.name, nameInfo.mod);
		if (daFrames == null)
			daFrames = Paths.getSpritesheet(nameInfo.name, 'fnf');
		frames = daFrames;
		
		updateFlipped();
	}
	
	public function reloadAnimations()
	{
		if (info == null)
			return;
			
		animation.destroyAnimations();
		for (anim in info.anims)
		{
			var offset = anim.offset.copy();
			if (charFlipX)
				offset = [-offset[0], offset[1]];
				
			addAnim({
				name: anim.name,
				atlasName: anim.atlasName,
				indices: anim.indices.copy(),
				fps: anim.fps,
				loop: anim.loop,
				flipX: anim.flipX,
				flipY: anim.flipY,
				offset: offset
			});
		}
		
		danceStep = -1;
		updateSize();
		
		if (animation.curAnim != null)
			animation.curAnim.curFrame = animation.curAnim.numFrames - 1;
	}
	
	public function updateSize()
	{
		final lastAnim = animation.name;
		final lastFrame = animation.curAnim != null ? animation.curAnim.curFrame : 0;
		
		playAnim(danceAnims[danceAnims.length - 1], true);
		startWidth = width;
		startHeight = height;
		updateOffset(false);
		xDifference = (429 - startWidth);
		updatePosition();
		
		if (lastAnim != null)
			playAnim(lastAnim, true, false, lastFrame);
	}
	
	public function updateFlipped(hitbox:Bool = true)
	{
		if (info == null)
			return;
			
		reloadAnimations();
		
		flipX = info.flipX;
		if (charFlipX)
			flipX = !flipX;
			
		singAnimations = DEFAULT_SING_ANIMS.copy();
		if (charFlipX)
		{
			final left = singAnimations[0];
			singAnimations[0] = singAnimations[3];
			singAnimations[3] = left;
			
			if (info.flipAll)
			{
				final down = singAnimations[1];
				singAnimations[1] = singAnimations[2];
				singAnimations[2] = down;
			}
		}
		
		updateOffset(hitbox);
		updatePosition();
	}
	
	public function setCamOffsetFromLane(lane:Int = -1)
	{
		final offset = 15;
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
	
	public function changeCharacter(name:String)
	{
		info = CharacterInfo.loadCharacterFromName(name);
	}
	
	public function startDanceTimer(time:Float)
	{
		cancelDanceTimer();
		allowDanceTimer.start(time, function(_)
		{
			canDance = true;
			dance();
		});
	}
	
	public function cancelDanceTimer()
	{
		if (allowDanceTimer.active)
			allowDanceTimer.cancel();
	}
	
	override function draw()
	{
		final lastColor = color;
		if (missColor)
			color *= MISS_COLOR;
			
		super.draw();
		
		if (missColor)
			color = lastColor;
	}
	
	override function updateOffset(hitbox:Bool = true)
	{
		super.updateOffset(hitbox);
		
		if (charFlipX)
			offset.subtractPoint(calculateOffset(FlxPoint.weak(startWidth - width)));
	}
	
	override function dance(force:Bool = false)
	{
		if (!danceDisabled)
			super.dance(force);
	}
	
	override function destroy()
	{
		info = null;
		super.destroy();
		singAnimations = null;
		if (holdTimers != null)
		{
			for (timer in holdTimers)
			{
				if (timer != null)
					timer.cancel();
			}
			holdTimers = FlxDestroyUtil.destroyArray(holdTimers);
		}
		allowDanceTimer = FlxDestroyUtil.destroy(allowDanceTimer);
		camOffset = FlxDestroyUtil.put(camOffset);
		FlxDestroyUtil.destroy(onSing);
	}
	
	override function danced(_)
	{
		state = Idle;
		resetColor();
		setCamOffsetFromLane();
	}
	
	override function _playAnim(name:String, force:Bool, reversed:Bool, frame:Int)
	{
		if (info != null && info.constantLooping && animation.curAnim != null && !debugMode)
			animation.play(name, force, reversed, animation.curAnim.curFrame + 1);
		else
			super._playAnim(name, force, reversed, frame);
	}
	
	function set_info(value:CharacterInfo)
	{
		if (value != null && info != value)
		{
			info = value;
			initializeCharacter();
		}
		return value;
	}
	
	function set_charPosX(value:Float)
	{
		if (charPosX != value)
		{
			charPosX = value;
			updatePosition();
		}
		return value;
	}
	
	function set_charPosY(value:Float)
	{
		if (charPosY != value)
		{
			charPosY = value;
			updatePosition();
		}
		return value;
	}
	
	function set_charFlipX(value:Bool)
	{
		if (charFlipX != value)
		{
			charFlipX = value;
			updateFlipped(false);
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
