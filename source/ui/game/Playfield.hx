package ui.game;

import data.PlayerConfig;
import data.Settings;
import data.game.Judgement;
import data.skin.NoteSkin;
import data.skin.SplashSkin;
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

	public function new(player:Int = 0)
	{
		super();
		this.player = player;
		config = Settings.playerConfigs[player];
		noteSkin = new NoteSkin(NoteSkin.loadSkinFromName(config.noteSkin));
		if (noteSkin == null)
			noteSkin = new NoteSkin(NoteSkin.loadSkinFromName('fnf:default'));

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
				receptor.y = FlxG.height - receptor.height - receptor.y;
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

		var skin = SplashSkin.loadSkinFromName(config.splashSkin);

		for (i in 0...4)
			splashes.add(new NoteSplash(i, skin, receptors.members[i], config));
	}
}
