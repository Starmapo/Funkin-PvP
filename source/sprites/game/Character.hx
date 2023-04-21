package sprites.game;

import data.char.CharacterInfo;

class Character extends DancingSprite
{
	public var charInfo:CharacterInfo;
	public var charPosX:Float;
	public var charPosY:Float;

	public function new(x:Float = 0, y:Float = 0, charInfo:CharacterInfo)
	{
		super(x, y);
		this.charInfo = charInfo;
		initializeCharacter();
	}

	public function setCharacterPosition(x:Float, y:Float)
	{
		charPosX = x;
		charPosY = y;
		updatePosition();
	}

	public function updatePosition()
	{
		var animOffset = getCurAnimOffset();
		x = charPosX - (width / 2) + charInfo.positionOffset[0] + animOffset[0];
		y = charPosY - height + charInfo.positionOffset[1] + animOffset[1];
	}

	public function getCurAnim()
	{
		if (animation.name == null)
			return null;

		for (anim in charInfo.anims)
		{
			if (anim.name == animation.name)
				return anim;
		}

		return null;
	}

	function initializeCharacter()
	{
		frames = Paths.getSpritesheet(charInfo.image);
		danceAnims = charInfo.danceAnims.copy();
		flipX = charInfo.flipX;
		antialiasing = charInfo.antialiasing;

		for (anim in charInfo.anims)
		{
			addAnim({
				name: anim.name,
				atlasName: anim.atlasName,
				indices: anim.indices.copy(),
				fps: anim.fps,
				loop: anim.loop
			});
		}

		danceStep = 0;
		playAnim(danceAnims[0], true);
		scale.set(charInfo.scale, charInfo.scale);
		updateHitbox();

		updatePosition();
	}

	function getCurAnimOffset()
	{
		var anim = getCurAnim();
		if (anim != null)
			return anim.offset;

		return [0, 0];
	}
}
