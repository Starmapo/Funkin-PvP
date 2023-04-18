package data.game;

import data.song.Song;

class ScoreProcessor
{
	public var player:Int;
	public var playbackRate:Float;
	public var noFail:Bool;
	public var score:Int;
	public var accuracy:Float;
	public var health:Float = 100;
	public var combo:Int;
	public var maxCombo:Int;
	public var failed(get, never):Bool;
	public var forceFail:Bool = false;
	public var stats:Array<HitStat> = [];
	public var windows:JudgementWindows;
	public var currentJudgements:Map<Judgement, Int> = [MARV => 0, SICK => 0, GOOD => 0, BAD => 0, SHIT => 0, MISS => 0];
	public var judgementWindow:Map<Judgement, Float> = new Map();
	public var judgementScoreWeighting:Map<Judgement, Int> = [MARV => 100, SICK => 50, GOOD => 25, BAD => 10, SHIT => 5, MISS => 0];
	public var judgementHealthWeighting:Map<Judgement, Float> = [MARV => 0.5, SICK => 0.4, GOOD => 0.2, BAD => -3, SHIT => -4.5, MISS => -6];
	public var judgementAccuracyWeighting:Map<Judgement, Float> = [MARV => 100, SICK => 98.25, GOOD => 65, BAD => 25, SHIT => -100, MISS => -50];

	var song:Song;

	public function new(song:Song, ?windows:JudgementWindows, playbackRate:Float = 1, noFail:Bool = false)
	{
		this.song = song;
		this.playbackRate = playbackRate;
		this.noFail = noFail;

		initializeJudgementWindows(windows);
	}

	function initializeJudgementWindows(?windows:JudgementWindows)
	{
		if (windows == null)
			windows = new JudgementWindows();
		this.windows = windows;

		judgementWindow[Judgement.MARV] = windows.marvelous;
		judgementWindow[Judgement.SICK] = windows.sick;
		judgementWindow[Judgement.GOOD] = windows.good;
		judgementWindow[Judgement.BAD] = windows.bad;
		judgementWindow[Judgement.SHIT] = windows.shit;
		judgementWindow[Judgement.MISS] = windows.miss;
	}

	function get_failed()
	{
		return health <= 0 && (!noFail || forceFail);
	}
}
