package states;

import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import openfl.utils.Assets;

class TestState extends FNFState
{
	override function create()
	{
		FlxG.camera.bgColor = 0;
		
		var button = new FlxUIButton(0, 0, "Play", function()
		{
			var audio = Assets.loadSound("mods/indiecross/music/Menu Theme/audio.ogg");
			audio.onComplete(function(sound)
			{
				FlxG.log.add("Sound loaded");
			});
		});
		button.screenCenter();
		add(button);
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
}
