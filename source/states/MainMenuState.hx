package states;

import data.PlayerSettings;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import sprites.AnimatedSprite;

class MainMenuState extends FNFState
{
	var camHUD:FlxCamera;
	var transWhite:FlxSprite;
	var transitioning:Bool = true;

	override function create()
	{
		transIn = transOut = null;

		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);

		var bg = CoolUtil.createMenuBG('menus/menuBG', 1.2);
		add(bg);

		transWhite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		transWhite.alpha = 0;
		transWhite.cameras = [camHUD];
		add(transWhite);

		FlxG.camera.zoom = 3;
		FlxG.camera.alpha = 0;
		FlxTween.tween(FlxG.camera, {zoom: 1, alpha: 1}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
			}
		});

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (PlayerSettings.checkAction(BACK_P) && !transitioning)
		{
			FlxTween.tween(transWhite, {alpha: 1}, Main.TRANSITION_TIME, {ease: FlxEase.expoIn});
			FlxTween.tween(FlxG.camera, {zoom: 5, alpha: 0}, Main.TRANSITION_TIME, {
				ease: FlxEase.expoIn,
				onComplete: function(_)
				{
					FlxG.switchState(new TitleState());
				}
			});
			CoolUtil.playCancelSound();
			transitioning = true;
		}

		super.update(elapsed);
	}
}

class MainMenuItem extends AnimatedSprite {}
