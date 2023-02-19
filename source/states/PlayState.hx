package states;

import data.ReceptorSkin;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import ui.Playfield;

class PlayState extends FlxState
{
	var camHUD:FlxCamera;
	var playfields:FlxTypedGroup<Playfield>;

	override public function create()
	{
		FlxG.camera.bgColor = FlxColor.GRAY;
		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);

		var skin:ReceptorSkin = new ReceptorSkin({
			receptors: [
				{
					staticAnim: 'arrow static instance 1',
					pressedAnim: 'left press',
					confirmAnim: 'left confirm'
				},
				{
					staticAnim: 'arrow static instance 2',
					pressedAnim: 'down press',
					confirmAnim: 'down confirm'
				},
				{
					staticAnim: 'arrow static instance 4',
					pressedAnim: 'up press',
					confirmAnim: 'up confirm'
				},
				{
					staticAnim: 'arrow static instance 3',
					pressedAnim: 'right press',
					confirmAnim: 'right confirm'
				}
			],
			receptorsCenterAnimation: true,
			receptorsImage: 'NOTE_assets',
			receptorsOffset: [0, 5],
			receptorsPadding: 0,
			receptorsScale: 0.5,
			antialiasing: true
		});

		playfields = new FlxTypedGroup();
		playfields.cameras = [camHUD];
		add(playfields);

		createPlayfield(0, skin);
		createPlayfield(1, skin);

		super.create();
	}

	public function createPlayfield(player:Int = 0, ?skin:ReceptorSkin)
	{
		var playfield = new Playfield(player, skin);
		playfields.add(playfield);
		return playfield;
	}
}
