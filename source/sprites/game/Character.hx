package sprites.game;

import data.char.CharacterInfo;

class Character extends DancingSprite
{
	public var charInfo:CharacterInfo;
	public var charPosX:Float;
	public var charPosY:Float;
	public var flipped:Bool;
	public var debugMode:Bool = false;

	var startWidth:Float;

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
		updatePosition();
		animation.finishCallback = function(name:String)
		{
			var anim = charInfo.getAnim(name);
			if (anim != null && anim.nextAnim.length > 0)
				playAnim(anim.nextAnim);
			animation.finishCallback = null;
		}
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
			x = charPosX + charInfo.positionOffset[0] + (startWidth - width);
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

		danceStep = 0;
		playAnim(danceAnims[0], true);
		startWidth = frameWidth;

		updatePosition();
	}
}
