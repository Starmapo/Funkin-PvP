package ui;

import data.ReceptorSkin;
import flixel.FlxSprite;

/**
	A receptor is a static arrow that indicates when you should hit a note.
	It also gives feedback whenever you press it and if you hit a note or not.
**/
class Receptor extends FlxSprite
{
	public var id(default, null):Int;
	public var skin(default, null):ReceptorSkin;

	public function new(x:Float = 0, y:Float = 0, id:Int = 0, ?skin:ReceptorSkin)
	{
		super(x, y);
		this.id = id;
		this.skin = skin;

		if (skin != null && skin.receptors[id] != null)
		{
			addAnimation('static', skin.receptors[id].staticAnim, skin.receptors[id].staticFPS);
			addAnimation('pressed', skin.receptors[id].pressedAnim, skin.receptors[id].pressedFPS);
			addAnimation('confirm', skin.receptors[id].confirmAnim, skin.receptors[id].confirmFPS);
		}
	}

	public function addAnimation(name:String, atlasName:String, ?fps:Float)
	{
		if (fps == null)
			fps = 24;

		animation.addByAtlasName(name, atlasName, fps);
	}
}
