package data.game;

import data.game.HitStat.KeyPressType;
import data.song.Song;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

class ScoreProcessor implements IFlxDestroyable
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
	public var judgementHealthWeighting:Map<Judgement, Float> = [MARV => 0.5, SICK => 0.4, GOOD => 0.2, BAD => 0.1, SHIT => 0, MISS => -3];
	public var judgementAccuracyWeighting:Map<Judgement, Float> = [MARV => 100, SICK => 100, GOOD => 70, BAD => 40, SHIT => 0, MISS => -50];
	public var windowReleaseMultiplier:Map<Judgement, Float> = [MARV => 1.5, SICK => 1.5, GOOD => 1.5, BAD => 1.5, SHIT => 1.5];
	public var totalJudgementCount(get, never):Int;

	var ruleset:GameplayRuleset;
	var song:Song;
	var totalJudgements:Int;
	var summedScore:Int;
	var multiplierCount:Int;
	var multiplierIndex:Int;
	var multiplierMaxIndex:Int = 15;
	var multiplierCountToIncreaseIndex:Int = 10;
	var maxMultiplierCount(get, never):Int;
	var scoreCount:Int;

	public function new(ruleset:GameplayRuleset, song:Song, player:Int, ?windows:JudgementWindows)
	{
		this.ruleset = ruleset;
		this.song = song;
		this.player = player;

		initializeJudgementWindows(windows);
		initializeMods();

		totalJudgements = getTotalJudgementCount();
		summedScore = calculateSummedScore();
		initializeHealthWeighting();
	}

	public function calculateScore(hitDifference:Float, keyPressType:KeyPressType, calculateAllStats:Bool = true)
	{
		var absoluteDifference:Float;
		if (hitDifference != FlxMath.MIN_VALUE_FLOAT)
			absoluteDifference = Math.abs(hitDifference);
		else
			return Judgement.MISS;

		var judgement = Judgement.GHOST;

		for (i in 0...7)
		{
			var j:Judgement = i;
			var window = judgementWindow[j];
			if (keyPressType == RELEASE && j == MISS)
				break;

			var window = keyPressType == RELEASE ? window * windowReleaseMultiplier[j] : window;
			if (absoluteDifference > window)
				continue;

			if (keyPressType == RELEASE && j == SHIT)
			{
				judgement = BAD;
				break;
			}

			judgement = j;
			break;
		}

		if (judgement == GHOST)
			return judgement;

		if (calculateAllStats)
			registerScore(judgement, keyPressType == RELEASE);

		return judgement;
	}

	public function registerScore(judgement:Judgement, isLongNoteRelease:Bool = false)
	{
		currentJudgements[judgement]++;

		accuracy = calculateAccuracy();

		var comboBreakJudgement = windows.comboBreakJudgement;
		if (comboBreakJudgement == MARV || comboBreakJudgement == GHOST)
			comboBreakJudgement = MISS;

		if ((judgement : Int) < (comboBreakJudgement : Int))
		{
			if (judgement == BAD || judgement == SHIT)
				multiplierCount -= multiplierCountToIncreaseIndex;
			else
				multiplierCount++;

			combo++;

			if (combo > maxCombo)
				maxCombo = combo;
		}
		else
		{
			multiplierCount -= multiplierCountToIncreaseIndex * 2;
			combo = 0;

			if (Settings.noMiss)
			{
				health = 0;
				forceFail = true;
				return;
			}
		}

		multiplierCount = FlxMath.boundInt(multiplierCount, 0, maxMultiplierCount);

		multiplierIndex = Math.floor(multiplierCount / multiplierCountToIncreaseIndex);
		scoreCount += judgementScoreWeighting[judgement] + multiplierIndex * multiplierCountToIncreaseIndex;

		final standardizedMaxScore = 1000000;
		score = Std.int(standardizedMaxScore * (scoreCount / summedScore));

		health = FlxMath.bound(health + judgementHealthWeighting[judgement], 0, 100);

		ruleset.judgementAdded.dispatch(judgement, player);
	}

	public function destroy()
	{
		stats = FlxDestroyUtil.destroyArray(stats);
		windows = null;
		currentJudgements = null;
		judgementWindow = null;
		judgementScoreWeighting = null;
		judgementHealthWeighting = null;
		judgementAccuracyWeighting = null;
		windowReleaseMultiplier = null;
		ruleset = null;
		song = null;
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
			judgementWindow[judgement] *= Settings.playbackRate;
	}

	function getTotalJudgementCount()
	{
		var judgements = 0;
		for (note in song.notes)
		{
			if (note.player != player)
				continue;

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
		var density = song.getActionsPerSecond(Settings.playbackRate);
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

	function calculateAccuracy()
	{
		var accuracy:Float = 0;

		for (judgement => value in currentJudgements)
			accuracy += value * judgementAccuracyWeighting[judgement];

		return Math.max(accuracy / (totalJudgementCount * judgementAccuracyWeighting[Judgement.MARV]), 0) * judgementAccuracyWeighting[Judgement.MARV];
	}

	function get_failed()
	{
		return health <= 0 && (Settings.canDie || forceFail);
	}

	function get_maxMultiplierCount()
	{
		return multiplierMaxIndex * multiplierCountToIncreaseIndex;
	}

	function get_totalJudgementCount()
	{
		var sum = 0;
		for (_ => value in currentJudgements)
			sum += value;
		return sum;
	}
}
