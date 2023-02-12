package states;

import flixel.util.FlxColor;
import data.ReceptorSkin;
import flixel.FlxState;
import ui.Receptor;

class PlayState extends FlxState
{
	override public function create()
	{
		bgColor = FlxColor.GRAY;
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
		var receptor = new Receptor(0, 0, 0, skin);
		add(receptor);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
