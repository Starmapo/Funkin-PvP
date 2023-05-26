package ui.game;

import data.PlayerConfig;
import data.Settings;
import data.game.Judgement;
import data.skin.NoteSkin;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

class Playfield extends FlxGroup
{
	public var player(default, null):Int = 0;
	public var config(default, null):PlayerConfig;
	public var noteSkin(default, null):NoteSkin;
	public var receptors(default, null):FlxTypedGroup<Receptor>;
	public var splashes(default, null):FlxTypedGroup<NoteSplash>;
	public var alpha:Float = 1;

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
						confirmOffset: [-1.5, 0]
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
				receptorsScale: 0.7,
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
				notesScale: 0.7,
				judgementsScale: 0.3,
				splashes: [
					{
						anim: 'note impact 1 purple',
						offset: [35, 35]
					},
					{
						anim: 'note impact 1  blue',
						offset: [35, 35]
					},
					{
						anim: 'note impact 1 green',
						offset: [35, 35]
					},
					{
						anim: 'note impact 1 red',
						offset: [35, 35]
					}
				],
				antialiasing: true
			});

		this.player = player;
		this.noteSkin = noteSkin;
		config = Settings.playerConfigs[player];

		initReceptors();
		initSplashes();
	}

	public function onLanePressed(lane:Int)
	{
		var receptor = receptors.members[lane];
		receptor.stopAnimCallback();
		receptor.playAnim('pressed');
	}

	public function onLaneReleased(lane:Int)
	{
		var receptor = receptors.members[lane];
		if (receptor.animation.name == 'pressed')
		{
			receptor.stopAnimCallback();
			receptor.playAnim('static');
		}
	}

	public function onNoteHit(note:Note, judgement:Judgement)
	{
		var receptor = receptors.members[note.info.playerLane];
		receptor.stopAnimCallback();
		receptor.playAnim('confirm', true);
		receptor.animation.finishCallback = function(anim)
		{
			if (note.currentlyBeingHeld)
				receptor.playAnim(anim, true);
			else
			{
				receptor.stopAnimCallback();
				receptor.playAnim('static');
			}
		}

		if (config.noteSplashes && (judgement == MARV || judgement == SICK))
			splashes.members[note.info.playerLane].startSplash();
	}

	override function draw()
	{
		var lastSpriteAlphas = new Map<FlxSprite, Float>();
		if (alpha != 1)
		{
			for (obj in receptors)
			{
				lastSpriteAlphas.set(obj, obj.alpha);
				obj.alpha *= alpha;
			}
		}

		super.draw();

		for (obj => objAlpha in lastSpriteAlphas)
			obj.alpha = objAlpha;
	}

	override function destroy()
	{
		super.destroy();
		config = null;
		noteSkin = null;
		receptors = null;
		splashes = null;
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
			var receptor = new Receptor(curX, 50 + noteSkin.receptorsOffset[1], i, noteSkin, config);
			if (config.downScroll)
				receptor.y = FlxG.height - receptor.height - 50 + noteSkin.receptorsOffset[1];
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
			splashes.add(new NoteSplash(i, noteSkin, receptors.members[i], config));
	}
}
