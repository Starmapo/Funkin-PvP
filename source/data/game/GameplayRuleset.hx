package data.game;

import data.song.Song;
import ui.game.Playfield;
import util.MusicTiming;

class GameplayRuleset
{
	public var scoreProcessors:Array<ScoreProcessor> = [];
	public var inputManagers:Array<InputManager> = [];
	public var playfields:Array<Playfield> = [];
	public var noteManagers:Array<NoteManager> = [];

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

	public function update()
	{
		for (manager in noteManagers)
			manager.update();
	}

	public function handleInput(elapsed:Float)
	{
		for (inputManager in inputManagers)
			inputManager.handleInput(elapsed);
	}
}
