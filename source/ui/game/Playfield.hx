package ui.game;

import data.PlayerConfig;
import data.Settings;
import data.game.GameplayRuleset;
import data.game.InputManager;
import data.game.Judgement;
import data.game.NoteManager;
import data.game.ScoreProcessor;
import data.skin.NoteSkin;
import data.skin.SplashSkin;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxDestroyUtil;

class Playfield extends FlxGroup
{
	public var player(default, null):Int = 0;
	public var config(default, null):PlayerConfig;
	public var noteSkin(default, null):NoteSkin;
	public var receptors(default, null):FlxTypedGroup<Receptor>;
	public var splashes(default, null):FlxTypedGroup<NoteSplash>;
	public var alpha:Float = 1;
	public var ruleset(default, null):GameplayRuleset;
	public var scoreProcessor(default, null):ScoreProcessor;
	public var inputManager(default, null):InputManager;
	public var noteManager(default, null):NoteManager;

	public function new(ruleset:GameplayRuleset, player:Int = 0)
	{
		super();
		this.ruleset = ruleset;
		this.player = player;
		config = Settings.playerConfigs[player];
		noteSkin = NoteSkin.loadSkinFromName(config.noteSkin);
		if (noteSkin == null)
			noteSkin = NoteSkin.loadSkinFromName('fnf:default');

		initReceptors();
		initSplashes();

		scoreProcessor = new ScoreProcessor(ruleset, player);
		noteManager = new NoteManager(this, player);
		add(noteManager);
		inputManager = new InputManager(this, player);

		active = false;
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

	override function update(elapsed:Float)
	{
		noteManager.update(elapsed);
		super.update(elapsed);
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
		ruleset = null;
		scoreProcessor = FlxDestroyUtil.destroy(scoreProcessor);
		inputManager = FlxDestroyUtil.destroy(inputManager);
		noteManager = FlxDestroyUtil.destroy(noteManager);
	}

	function initReceptors()
	{
		receptors = new FlxTypedGroup();
		add(receptors);

		var curX:Float = noteSkin.receptorsOffset[0] * config.notesScale;
		if (player == 1)
			curX += FlxG.width / 2;

		for (i in 0...4)
		{
			var receptor = new Receptor(curX, 50 + noteSkin.receptorsOffset[1] * config.notesScale, i, noteSkin, config);
			if (config.downScroll)
				receptor.y = FlxG.height - receptor.height - receptor.y;
			receptors.add(receptor);

			curX += receptor.width + noteSkin.receptorsPadding * config.notesScale;
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
