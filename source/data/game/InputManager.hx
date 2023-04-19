package data.game;

import data.Controls.Action;
import ui.game.Note;

class InputManager
{
	public var autoplay:Bool;

	var ruleset:GameplayRuleset;
	var player:Int;
	var realPlayer:Int;
	var controls:Controls;
	var bindingStore:Array<InputBinding>;

	public function new(ruleset:GameplayRuleset, player:Int, autoplay:Bool = false)
	{
		this.ruleset = ruleset;
		this.player = player;
		realPlayer = player;
		this.autoplay = autoplay;
		controls = PlayerSettings.players[player].controls;

		setInputBinds();
	}

	public function handleInput(elapsed:Float)
	{
		var manager = ruleset.noteManagers[player];

		if (autoplay)
		{
			for (lane in manager.activeNoteLanes)
			{
				for (note in lane)
				{
					if (manager.currentAudioPosition >= note.info.startTime)
					{
						ruleset.lanePressed.dispatch(note.info.playerLane, player);
						handleKeyPress(manager, note);
					}
				}
			}
			for (lane in manager.heldLongNoteLanes)
			{
				for (note in lane)
				{
					if (manager.currentAudioPosition >= note.info.endTime)
						handleKeyRelease(manager, note);
				}
			}
			return;
		}

		for (lane in 0...bindingStore.length)
		{
			var needsUpdating = false;
			var bind = bindingStore[lane];

			if (!bind.pressed && controls.checkByName(bind.justPressedAction))
			{
				bind.pressed = true;
				needsUpdating = true;
			}
			else if (bind.pressed && controls.checkByName(bind.justReleasedAction))
			{
				bind.pressed = false;
				needsUpdating = true;
			}

			if (!needsUpdating)
				continue;

			if (bind.pressed)
			{
				ruleset.lanePressed.dispatch(lane, player);
				var note = manager.getClosestTap(lane);
				if (note != null)
					handleKeyPress(manager, note);
			}
			else
			{
				ruleset.laneReleased.dispatch(lane, player);
				var note = manager.getClosestRelease(lane);
				if (note != null)
					handleKeyRelease(manager, note);
			}
		}
	}

	public function changePlayer(player:Int)
	{
		realPlayer = player;
		controls = PlayerSettings.players[player].controls;
	}

	function setInputBinds()
	{
		bindingStore = [
			new InputBinding(NOTE_LEFT_P, NOTE_LEFT, NOTE_LEFT_R),
			new InputBinding(NOTE_DOWN_P, NOTE_DOWN, NOTE_DOWN_R),
			new InputBinding(NOTE_UP_P, NOTE_UP, NOTE_UP_R),
			new InputBinding(NOTE_RIGHT_P, NOTE_RIGHT, NOTE_RIGHT_R)
		];
	}

	function handleKeyPress(manager:NoteManager, note:Note)
	{
		var time = manager.currentAudioPosition;
		var hitDifference = autoplay ? 0 : note.info.startTime - time;
		var judgement = ruleset.scoreProcessors[player].calculateScore(hitDifference, PRESS);
		var lane = note.info.playerLane;

		if (judgement == GHOST)
		{
			ruleset.ghostTap.dispatch(lane, player);
			return;
		}

		note = manager.activeNoteLanes[lane].shift();

		ruleset.scoreProcessors[player].stats.push(new HitStat(HIT, PRESS, note.info, time, judgement, hitDifference,
			ruleset.scoreProcessors[player].accuracy, ruleset.scoreProcessors[player].health));

		switch (judgement)
		{
			case MISS:
				if (note.info.isLongNote)
				{
					ruleset.scoreProcessors[player].registerScore(MISS, true);
					ruleset.scoreProcessors[player].stats.push(new HitStat(MISS, PRESS, note.info, time, MISS, time, ruleset.scoreProcessors[player].accuracy,
						ruleset.scoreProcessors[player].health));
				}
				ruleset.noteMissed.dispatch(note);
				manager.recyclePoolObject(note);
			default:
				ruleset.noteHit.dispatch(note);
				if (note.info.isLongNote)
					manager.changePoolObjectStatusToHeld(note);
				else
					manager.recyclePoolObject(note);
		}
	}

	function handleKeyRelease(manager:NoteManager, note:Note)
	{
		var lane = note.info.playerLane;
		var time = manager.currentAudioPosition;
		var hitDifference = autoplay ? 0 : manager.heldLongNoteLanes[lane][0].info.endTime - time;

		var judgement = ruleset.scoreProcessors[player].calculateScore(hitDifference, RELEASE);

		note = manager.heldLongNoteLanes[lane].shift();

		if (judgement != GHOST)
		{
			ruleset.scoreProcessors[player].stats.push(new HitStat(HIT, RELEASE, note.info, time, judgement, hitDifference,
				ruleset.scoreProcessors[player].accuracy, ruleset.scoreProcessors[player].health));

			ruleset.noteReleased.dispatch(note);

			if (judgement == MISS || judgement == SHIT)
				manager.killHoldPoolObject(note, judgement == MISS);
			else
				manager.recyclePoolObject(note);

			return;
		}

		final missedJudgement = Judgement.MISS;

		ruleset.scoreProcessors[player].stats.push(new HitStat(HIT, RELEASE, note.info, time, MISS, hitDifference, ruleset.scoreProcessors[player].accuracy,
			ruleset.scoreProcessors[player].health));

		ruleset.scoreProcessors[player].registerScore(missedJudgement, true);

		ruleset.noteReleaseMissed.dispatch(note);

		manager.killHoldPoolObject(note);
	}
}

class InputBinding
{
	public var justPressedAction:Action;
	public var pressedAction:Action;
	public var justReleasedAction:Action;
	public var pressed:Bool;

	public function new(justPressedAction:Action, pressedAction:Action, justReleasedAction:Action)
	{
		this.justPressedAction = justPressedAction;
		this.pressedAction = pressedAction;
		this.justReleasedAction = justReleasedAction;
	}
}
