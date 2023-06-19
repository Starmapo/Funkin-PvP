package data.game;

import data.song.NoteInfo;
import data.song.Song;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import ui.game.Note;
import ui.game.Playfield;
import util.MusicTiming;

class GameplayRuleset implements IFlxDestroyable
{
	public var playfields:Array<Playfield> = [];
	public var song:Song;
	public var lanePressed:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	public var laneReleased:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	public var ghostTap:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	public var noteHit:FlxTypedSignal<Note->Judgement->Float->Void> = new FlxTypedSignal();
	public var noteMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	public var noteReleased:FlxTypedSignal<Note->Judgement->Float->Void> = new FlxTypedSignal();
	public var noteReleaseMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	public var judgementAdded:FlxTypedSignal<Judgement->Int->Void> = new FlxTypedSignal();
	public var noteSpawned:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	public var timing:MusicTiming;

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

	public function handleInput(elapsed:Float)
	{
		for (playfield in playfields)
			playfield.inputManager.handleInput(elapsed);
	}

	public function stopInput()
	{
		for (playfield in playfields)
			playfield.inputManager.stopInput();
	}

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

	public function killInfoLanes(lanes:Array<Array<NoteInfo>>)
	{
		for (lane in lanes)
			lane.resize(0);
	}

	public function killNoteLanes(lanes:Array<Array<Note>>)
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

	public function handleSkip()
	{
		for (playfield in playfields)
			playfield.noteManager.handleSkip();
	}

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
}
