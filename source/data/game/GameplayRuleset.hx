package data.game;

import data.song.Song;

class GameplayRuleset
{
	public var scoreProcessors:Array<ScoreProcessor> = [];

	var song:Song;

	public function new(song:Song)
	{
		this.song = song;
	}
}
