package backend.game;

import backend.MusicTiming;
import backend.structures.song.NoteInfo;
import backend.structures.song.Song;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import objects.game.Note;
import objects.game.Playfield;

/**
	The gameplay ruleset which contains the playfields and signals.
**/
class GameplayRuleset implements IFlxDestroyable
{
	/**
		The song for this ruleset.
	**/
	public var song:Song;
	
	/**
		The timing object for this ruleset.
	**/
	public var timing:MusicTiming;
	
	/**
		The playfields of this ruleset.
	**/
	public var playfields:Array<Playfield> = [];
	
	/**
		Called when a player presses one of the note keys. (player -> lane)
	**/
	public var lanePressed:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	
	/**
		Called when a player releases one of the note keys. (player -> lane)
	**/
	public var laneReleased:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	
	/**
		Called when a player presses one of the note keys without hitting a note. (player -> lane)
	**/
	public var ghostTap:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	
	/**
		Called when a new note is spawned.
	**/
	public var noteSpawned:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	
	/**
		Called when a player hits a note. (note -> judgement -> millisecond difference)
	**/
	public var noteHit:FlxTypedSignal<Note->Judgement->Float->Void> = new FlxTypedSignal();
	
	/**
		Called when a player misses a note.
	**/
	public var noteMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	
	/**
		Called when a player successfully releases a long note. (note -> judgement -> millisecond difference)
	**/
	public var noteReleased:FlxTypedSignal<Note->Judgement->Float->Void> = new FlxTypedSignal();
	
	/**
		Called when a player misses a long note release.
	**/
	public var noteReleaseMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	
	/**
		Called when a new judgement is added. (judgement -> player)
	**/
	public var judgementAdded:FlxTypedSignal<Judgement->Int->Void> = new FlxTypedSignal();
	
	/**
		@param	song	The song for this ruleset.
		@param	timing	The timing object for this ruleset.
	**/
	public function new(song:Song, timing:MusicTiming)
	{
		this.song = song;
		this.timing = timing;
		for (i in 0...2)
			playfields.push(new Playfield(this, i));
	}
	
	public function update(elapsed:Float)
	{
		for (playfield in playfields)
			playfield.update(elapsed);
	}
	
	/**
		Handles the note input.
	**/
	public function handleInput(elapsed:Float)
	{
		for (playfield in playfields)
			playfield.inputManager.handleInput(elapsed);
	}
	
	/**
		Stops all note input.
	**/
	public function stopInput()
	{
		for (playfield in playfields)
			playfield.inputManager.stopInput();
	}
	
	/**
		Removes all current and queued notes.
	**/
	public function killNotes()
	{
		for (playfield in playfields)
		{
			var manager = playfield.noteManager;
			killInfoLanes(manager.noteQueueLanes);
			killNoteLanes(manager.activeNoteLanes);
			killNoteLanes(manager.heldLongNoteLanes);
			killNoteLanes(manager.deadNoteLanes);
		}
	}
	
	/**
		Called once the song is skipped forward in time.
	**/
	public function handleSkip()
	{
		for (playfield in playfields)
			playfield.noteManager.handleSkip();
	}
	
	/**
		Frees up memory.
	**/
	public function destroy()
	{
		playfields = FlxDestroyUtil.destroyArray(playfields);
		FlxDestroyUtil.destroy(lanePressed);
		FlxDestroyUtil.destroy(laneReleased);
		FlxDestroyUtil.destroy(ghostTap);
		FlxDestroyUtil.destroy(noteHit);
		FlxDestroyUtil.destroy(noteMissed);
		FlxDestroyUtil.destroy(noteReleased);
		FlxDestroyUtil.destroy(noteReleaseMissed);
		FlxDestroyUtil.destroy(judgementAdded);
		FlxDestroyUtil.destroy(noteSpawned);
		timing = null;
		song = null;
	}
	
	function killInfoLanes(lanes:Array<Array<NoteInfo>>)
	{
		for (lane in lanes)
			lane.resize(0);
	}
	
	function killNoteLanes(lanes:Array<Array<Note>>)
	{
		for (lane in lanes)
		{
			while (lane.length > 0)
			{
				var note = lane.shift();
				note.currentlyBeingHeld = false;
				note.destroy();
			}
		}
	}
}
