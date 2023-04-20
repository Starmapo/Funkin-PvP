package ui.game;

import data.PlayerConfig;
import data.game.Judgement;
import data.skin.NoteSkin;
import flixel.FlxG;
import flixel.group.FlxGroup;

class Playfield extends FlxGroup
{
	public var player(default, null):Int = 0;
	public var config(default, null):PlayerConfig;
	public var noteSkin(default, null):NoteSkin;
	public var receptors(default, null):FlxTypedGroup<Receptor>;
	public var splashes(default, null):FlxTypedGroup<NoteSplash>;

	public function new(player:Int = 0, ?noteSkin:NoteSkin)
	{
		super();
		if (noteSkin == null)
			noteSkin = new NoteSkin({
				receptors: [
					{
						staticAnim: 'arrow static instance 1',
						pressedAnim: 'left press instance 1',
						confirmAnim: 'left confirm instance 1'
					},
					{
						staticAnim: 'arrow static instance 2',
						pressedAnim: 'down press instance 1',
						confirmAnim: 'down confirm instance 1',
						confirmOffset: [-2, 0]
					},
					{
						staticAnim: 'arrow static instance 4',
						pressedAnim: 'up press instance 1',
						confirmAnim: 'up confirm instance 1'
					},
					{
						staticAnim: 'arrow static instance 3',
						pressedAnim: 'right press instance 1',
						confirmAnim: 'right confirm instance 1'
					}
				],
				receptorsCenterAnimation: true,
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
				notesScale: 0.5,
				judgementsScale: 0.3,
				splashes: [
					{
						anim: 'note impact 1 purple',
						offset: [25, 25]
					},
					{
						anim: 'note impact 1  blue',
						offset: [25, 25]
					},
					{
						anim: 'note impact 1 green',
						offset: [25, 25]
					},
					{
						anim: 'note impact 1 red',
						offset: [25, 25]
					}
				],
				splashesScale: 0.71,
				antialiasing: true
			});

		this.player = player;
		this.noteSkin = noteSkin;
		config = FlxG.save.data.playerConfigs[player];

		initReceptors();
		initSplashes();
	}

	public function onLanePressed(lane:Int)
	{
		receptors.members[lane].playAnim('pressed');
	}

	public function onLaneReleased(lane:Int)
	{
		var receptor = receptors.members[lane];
		receptor.animation.finishCallback = null;
		receptor.playAnim('static');
	}

	public function onNoteHit(note:Note, judgement:Judgement)
	{
		var receptor = receptors.members[note.info.playerLane];
		receptor.animation.finishCallback = null;

		receptor.playAnim('confirm', true);

		receptor.animation.finishCallback = function(anim)
		{
			if (anim == 'confirm')
			{
				if (note.currentlyBeingHeld)
					receptor.playAnim('confirm', true);
				else
				{
					receptor.playAnim('static', true);
					receptor.animation.finishCallback = null;
				}
			}
		}

		if (config.noteSplashes && (judgement == MARV || judgement == SICK))
			splashes.members[note.info.playerLane].startSplash();
	}

	function initReceptors()
	{
		receptors = new FlxTypedGroup();
		add(receptors);

		var curX:Float = noteSkin.receptorsOffset[0];
		if (player == 1)
			curX += FlxG.width / 2;

		for (i in 0...4)
		{
			var receptor = new Receptor(curX, 50 + noteSkin.receptorsOffset[1], i, noteSkin);
			receptors.add(receptor);

			curX += receptor.width + noteSkin.receptorsPadding;
		}

		var newX = ((FlxG.width / 2) - CoolUtil.getGroupWidth(receptors)) / 2;
		for (receptor in receptors)
			receptor.x += newX;
	}

	function initSplashes()
	{
		splashes = new FlxTypedGroup();
		add(splashes);

		if (!config.noteSplashes)
			return;

		for (i in 0...4)
			splashes.add(new NoteSplash(i, noteSkin, receptors.members[i]));
	}
}
