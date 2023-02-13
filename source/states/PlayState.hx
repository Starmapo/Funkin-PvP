package states;

import data.ReceptorSkin;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.Receptor;

class PlayState extends FlxState
{
	var receptor:Receptor;
	var text:FlxText;
	var camHUD:FlxCamera;

	override public function create()
	{
		FlxG.camera.bgColor = FlxColor.GRAY;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		var skin:ReceptorSkin = {
			receptors: [
				{
					staticAnim: 'arrow static instance 1',
					pressedAnim: 'left press',
					confirmAnim: 'left confirm'
				}
			],
			receptorsCenterAnimation: true,
			receptorsImage: 'NOTE_assets',
			receptorsOffset: [0, 5],
			receptorsPadding: 0,
			receptorsScale: 0.7,
			antialiasing: true
		};
		receptor = new Receptor(0, 0, 0, skin);
		add(receptor);

		text = new FlxText(0, 0, 0, '', 16);
		text.screenCenter();
		text.cameras = [camHUD];
		add(text);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;

		if (FlxG.keys.pressed.LEFT)
		{
			FlxG.camera.angle -= elapsed * 50;
		}
		else if (FlxG.keys.pressed.RIGHT)
		{
			FlxG.camera.angle += elapsed * 50;
		}

		/*var rect = receptor.getScreenBounds();
			var newRect = FlxRect.get(rect.x, rect.y, rect.width, rect.height);
			if (FlxG.camera.angle != 0)
			{
				newRect.x -= FlxG.camera.width / 2;
				newRect.y -= FlxG.camera.height / 2;
				newRect.getRotatedBounds(FlxG.camera.angle, null, newRect);
				newRect.x += FlxG.camera.width / 2;
				newRect.y += FlxG.camera.height / 2;
		}*/

		text.text = FlxG.camera.angle + '\n' + receptor.isOnScreen() + '\n' + FlxG.mouse.overlaps(receptor);
	}
}
