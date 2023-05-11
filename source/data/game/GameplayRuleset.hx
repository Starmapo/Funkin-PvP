package data.game;

import data.song.Song;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import ui.game.Note;
import ui.game.Playfield;
import util.MusicTiming;

class GameplayRuleset implements IFlxDestroyable
{
	public var scoreProcessors:Array<ScoreProcessor> = [];
	public var inputManagers:Array<InputManager> = [];
	public var playfields:Array<Playfield> = [];
	public var noteManagers:Array<NoteManager> = [];
	public var lanePressed:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	public var laneReleased:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	public var ghostTap:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	public var noteHit:FlxTypedSignal<Note->Judgement->Void> = new FlxTypedSignal();
	public var noteMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	public var noteReleased:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	public var noteReleaseMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	public var judgementAdded:FlxTypedSignal<Judgement->Int->Void> = new FlxTypedSignal();
	public var startDelay:Float;
	public var timing:MusicTiming;

	var song:Song;

	public function new(song:Song, timing:MusicTiming)
	{
		this.song = song;
		this.timing = timing;
		startDelay = timing.startDelay;
		for (i in 0...2)
		{
			scoreProcessors.push(new ScoreProcessor(this, song, i));
			inputManagers.push(new InputManager(this, i));
			playfields.push(new Playfield(i));
			noteManagers.push(new NoteManager(this, song, i));
		}
	}

	public function update(elapsed:Float)
	{
		for (manager in noteManagers)
			manager.update(elapsed);
		for (playfield in playfields)
			playfield.update(elapsed);
	}

	public function updateCurrentTrackPosition()
	{
		for (manager in noteManagers)
			manager.updateCurrentTrackPosition();
	}

	public function handleInput(elapsed:Float)
	{
		for (inputManager in inputManagers)
			inputManager.handleInput(elapsed);
	}

	public function destroy()
	{
		scoreProcessors = FlxDestroyUtil.destroyArray(scoreProcessors);
		inputManagers = FlxDestroyUtil.destroyArray(inputManagers);
		playfields = FlxDestroyUtil.destroyArray(playfields);
		noteManagers = FlxDestroyUtil.destroyArray(noteManagers);
		FlxDestroyUtil.destroy(lanePressed);
		FlxDestroyUtil.destroy(laneReleased);
		FlxDestroyUtil.destroy(ghostTap);
		FlxDestroyUtil.destroy(noteHit);
		FlxDestroyUtil.destroy(noteMissed);
		FlxDestroyUtil.destroy(noteReleased);
		FlxDestroyUtil.destroy(noteReleaseMissed);
		FlxDestroyUtil.destroy(judgementAdded);
		timing = null;
		song = null;
	}
}
