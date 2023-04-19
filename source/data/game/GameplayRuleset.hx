package data.game;

import data.song.Song;
import flixel.util.FlxSignal.FlxTypedSignal;
import ui.game.Note;
import ui.game.Playfield;
import util.MusicTiming;

class GameplayRuleset
{
	public var scoreProcessors:Array<ScoreProcessor> = [];
	public var inputManagers:Array<InputManager> = [];
	public var playfields:Array<Playfield> = [];
	public var noteManagers:Array<NoteManager> = [];
	public var lanePressed:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	public var ghostTap:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal();
	public var noteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	public var noteMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	public var noteReleased:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
	public var noteReleaseMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();

	var song:Song;

	public var timing:MusicTiming;

	public function new(song:Song, timing:MusicTiming)
	{
		this.song = song;
		this.timing = timing;
		for (i in 0...2)
		{
			scoreProcessors.push(new ScoreProcessor(song, i));
			inputManagers.push(new InputManager(this, i));
			playfields.push(new Playfield(i));
			noteManagers.push(new NoteManager(this, song, i));
		}
	}

	public function update(elapsed:Float)
	{
		for (manager in noteManagers)
			manager.update();
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
}
