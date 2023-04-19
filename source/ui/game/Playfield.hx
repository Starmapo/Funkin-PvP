package ui.game;

import data.PlayerConfig;
import data.skin.NoteSkin;
import flixel.FlxG;
import flixel.group.FlxGroup;

class Playfield extends FlxGroup
{
	public var player(default, null):Int = 0;
	public var playerConfig(default, null):PlayerConfig;
	public var noteSkin(default, null):NoteSkin;
	public var receptors(default, null):FlxTypedGroup<Receptor>;

	public function new(player:Int = 0, ?noteSkin:NoteSkin)
	{
		super();
		if (noteSkin == null)
			noteSkin = new NoteSkin({
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
				receptorsImage: 'notes/NOTE_assets',
				receptorsOffset: [0, 0],
				receptorsPadding: 0,
				receptorsScale: 0.5,
				notes: [
					{
						headAnim: 'purple instance 1',
						bodyAnim: 'purple hold piece instance 1',
						tailAnim: 'pruple end hold instance 1'
					},
					{
						headAnim: 'blue instance 1',
						bodyAnim: 'blue hold piece instance 1',
						tailAnim: 'blue hold end instance 1'
					},
					{
						headAnim: 'green instance 1',
						bodyAnim: 'green hold piece instance 1',
						tailAnim: 'green hold end instance 1'
					},
					{
						headAnim: 'red instance 1',
						bodyAnim: 'red hold piece instance 1',
						tailAnim: 'red hold end instance 1'
					}
				],
				notesImage: 'notes/NOTE_assets',
				notesScale: 0.5,
				antialiasing: true
			});

		this.player = player;
		this.noteSkin = noteSkin;
		playerConfig = FlxG.save.data.playerConfigs[player];

		initReceptors();
	}

	function initReceptors()
	{
		receptors = new FlxTypedGroup();
		add(receptors);

		var curX:Float = noteSkin.receptorsOffset[0];
		if (player == 1)
		{
			curX += FlxG.width / 2;
		}
		for (i in 0...4)
		{
			var receptor = new Receptor(curX, 50 + noteSkin.receptorsOffset[1], i, noteSkin);
			receptors.add(receptor);

			curX += receptor.width + noteSkin.receptorsPadding;
		}

		var newX = ((FlxG.width / 2) - CoolUtil.getGroupWidth(receptors)) / 2;
		for (receptor in receptors)
		{
			receptor.x += newX;
		}
	}
}
