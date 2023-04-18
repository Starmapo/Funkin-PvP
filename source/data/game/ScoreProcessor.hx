package data.game;

import data.song.Song;
import flixel.math.FlxMath;

class ScoreProcessor
{
	public var player:Int;
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
	var playbackRate:Float;
	var noFail:Bool;
	var autoplay:Bool;
	var totalJudgements:Int;
	var summedScore:Int;
	var multiplierCount:Int;
	var multiplierIndex:Int;
	var multiplierMaxIndex:Int = 15;
	var multiplierCountToIncreaseIndex:Int = 10;
	var maxMultiplierCount(get, never):Int;
	var scoreCount:Int;

	public function new(song:Song, player:Int, ?windows:JudgementWindows, playbackRate:Float = 1, noFail:Bool = false, autoplay:Bool = false)
	{
		this.song = song;
		this.player = player;
		this.playbackRate = playbackRate;
		this.noFail = noFail;
		this.autoplay = autoplay;

		initializeJudgementWindows(windows);
		initializeMods();

		totalJudgements = getTotalJudgementCount();
		summedScore = calculateSummedScore();
		initializeHealthWeighting();
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

	function initializeMods()
	{
		for (judgement => _ in judgementWindow)
			judgementWindow[judgement] *= playbackRate;
	}

	function getTotalJudgementCount()
	{
		var judgements = 0;
		for (note in song.notes)
		{
			if (note.isLongNote)
				judgements += 2;
			else
				judgements++;
		}
		return judgements;
	}

	function calculateSummedScore()
	{
		var summedScore = 0;

		var i = 1;
		while (i <= totalJudgements && i < maxMultiplierCount)
		{
			summedScore += judgementScoreWeighting[Judgement.MARV] + multiplierCountToIncreaseIndex * Math.floor(i / multiplierCountToIncreaseIndex);
			i++;
		}

		if (totalJudgements >= maxMultiplierCount)
			summedScore += (totalJudgements - (maxMultiplierCount - 1)) * (judgementScoreWeighting[Judgement.MARV] + maxMultiplierCount);

		return summedScore;
	}

	function initializeHealthWeighting()
	{
		if (autoplay)
			return;

		var density = song.getActionsPerSecond(playbackRate);
		if (density == 0 || density >= 12 || Math.isNaN(density))
			return;
		if (density > 0 && density < 2)
			density = 2;

		var values:Map<Judgement, Array<Float>> = [
			MARV => [-0.14, 2.68],
			SICK => [-0.2, 3.4],
			GOOD => [-0.14, 2.68],
			BAD => [0.084, -0.008],
			SHIT => [0.081, 0.028]
		];
		for (judgement => value in values)
		{
			var multiplier = value[0] * density + value[1];
			var weight = judgementHealthWeighting[judgement];
			judgementHealthWeighting[judgement] = FlxMath.roundDecimal(multiplier * weight, 2);
		}
	}

	function get_failed()
	{
		return health <= 0 && (!noFail || forceFail);
	}

	function get_maxMultiplierCount()
	{
		return multiplierMaxIndex * multiplierCountToIncreaseIndex;
	}
}
