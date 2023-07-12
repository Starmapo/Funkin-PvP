package data.game;

import data.Controls.Action;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import ui.game.Note;
import ui.game.Playfield;

/**
	Handles note input for gameplay.
**/
class InputManager implements IFlxDestroyable
{
	/**
		Whether this side should be automatically played.
	**/
	public var autoplay:Bool;
	
	var bindingStore:Array<InputBinding>;
	var playfield:Playfield;
	var player:Int;
	var realPlayer:Int;
	var controls:Controls;
	var noteManager(get, never):NoteManager;
	var config:PlayerConfig;
	var ruleset(get, never):GameplayRuleset;
	var scoreProcessor(get, never):ScoreProcessor;
	
	public function new(playfield:Playfield, player:Int)
	{
		this.playfield = playfield;
		this.player = player;
		realPlayer = player;
		config = Settings.playerConfigs[player];
		autoplay = config.autoplay;
		controls = PlayerSettings.players[player].controls;
		
		setInputBinds();
	}
	
	public function handleInput(elapsed:Float)
	{
		if (autoplay)
		{
			for (lane in noteManager.heldLongNoteLanes)
			{
				while (lane.length > 0 && noteManager.currentAudioPosition >= lane[0].info.endTime)
				{
					var note = lane[0];
					ruleset.laneReleased.dispatch(note.info.playerLane, player);
					handleKeyRelease(note);
				}
			}
			for (lane in noteManager.activeNoteLanes)
			{
				while (lane.length > 0 && noteManager.currentAudioPosition >= lane[0].info.startTime)
				{
					var note = lane[0];
					ruleset.lanePressed.dispatch(note.info.playerLane, player);
					handleKeyPress(note);
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
				var note = noteManager.getClosestTap(lane);
				if (note != null)
					handleKeyPress(note);
			}
			else
			{
				ruleset.laneReleased.dispatch(lane, player);
				var note = noteManager.getClosestRelease(lane);
				if (note != null)
					handleKeyRelease(note);
			}
		}
	}
	
	/**
		Changes the player that will play this side.
	**/
	public function changePlayer(player:Int)
	{
		realPlayer = player;
		controls = PlayerSettings.players[player].controls;
	}
	
	/**
		Frees up memory.
	**/
	public function destroy()
	{
		bindingStore = null;
		playfield = null;
		controls = null;
		config = null;
	}
	
	/**
		Stops all current input.
	**/
	public function stopInput()
	{
		for (i in 0...bindingStore.length)
		{
			bindingStore[i].pressed = false;
			ruleset.laneReleased.dispatch(i, player);
			var note = noteManager.getClosestRelease(i);
			if (note != null)
				handleKeyRelease(note);
		}
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
	
	function handleKeyPress(note:Note)
	{
		var time = noteManager.currentAudioPosition;
		var hitDifference = autoplay ? 0 : note.info.startTime - time;
		var judgement = scoreProcessor.calculateScore(hitDifference, PRESS);
		var lane = note.info.playerLane;
		
		if (judgement == GHOST)
		{
			if (!Settings.ghostTapping)
			{
				scoreProcessor.registerScore(MISS);
				scoreProcessor.stats.push(new HitStat(MISS, PRESS, null, time, MISS, time, scoreProcessor.accuracy, scoreProcessor.health));
			}
			ruleset.ghostTap.dispatch(lane, player);
			return;
		}
		
		note = noteManager.activeNoteLanes[lane].shift();
		
		scoreProcessor.stats.push(new HitStat(HIT, PRESS, note.info, time, judgement, hitDifference, scoreProcessor.accuracy, scoreProcessor.health));
		
		switch (judgement)
		{
			case MISS:
				if (note.info.isLongNote)
				{
					scoreProcessor.registerScore(MISS, true);
					scoreProcessor.stats.push(new HitStat(MISS, PRESS, note.info, time, MISS, time, scoreProcessor.accuracy, scoreProcessor.health));
				}
				ruleset.noteMissed.dispatch(note);
				noteManager.recyclePoolObject(note);
			default:
				ruleset.noteHit.dispatch(note, judgement, hitDifference);
				if (note.info.isLongNote)
					noteManager.changePoolObjectStatusToHeld(note);
				else
					noteManager.recyclePoolObject(note);
		}
	}
	
	function handleKeyRelease(note:Note)
	{
		var lane = note.info.playerLane;
		var time = noteManager.currentAudioPosition;
		var endTime = noteManager.heldLongNoteLanes[lane][0].info.endTime;
		var hitDifference = (autoplay || time >= endTime) ? 0 : endTime - time;
		
		var judgement = scoreProcessor.calculateScore(hitDifference, RELEASE);
		
		note = noteManager.heldLongNoteLanes[lane].shift();
		
		if (judgement != GHOST)
		{
			scoreProcessor.stats.push(new HitStat(HIT, RELEASE, note.info, time, judgement, hitDifference, scoreProcessor.accuracy, scoreProcessor.health));
			
			ruleset.noteReleased.dispatch(note, judgement, hitDifference);
			
			if (judgement == MISS)
				ruleset.noteReleaseMissed.dispatch(note);
				
			if (judgement == MISS || judgement == SHIT)
				noteManager.killHoldPoolObject(note, judgement == MISS);
			else
				noteManager.recyclePoolObject(note);
				
			return;
		}
		
		final missedJudgement = Judgement.MISS;
		
		scoreProcessor.stats.push(new HitStat(HIT, RELEASE, note.info, time, MISS, hitDifference, scoreProcessor.accuracy, scoreProcessor.health));
		
		scoreProcessor.registerScore(missedJudgement, true);
		
		ruleset.noteReleaseMissed.dispatch(note);
		
		noteManager.killHoldPoolObject(note);
	}
	
	function get_noteManager()
	{
		return playfield.noteManager;
	}
	
	function get_ruleset()
	{
		return playfield.ruleset;
	}
	
	function get_scoreProcessor()
	{
		return playfield.scoreProcessor;
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
