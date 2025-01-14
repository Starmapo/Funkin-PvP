package backend.game;

import backend.game.HitStat.KeyPressType;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

/**
	Stores scoring information of a player in gameplay.
**/
class ScoreProcessor implements IFlxDestroyable
{
	/**
		Returns a grade from a player's accuracy.
	**/
	public static function getGradeFromAccuracy(accuracy:Float)
	{
		if (accuracy >= 100)
			return 'X';
		else if (accuracy >= 99)
			return 'SS';
		else if (accuracy >= 95)
			return 'S';
		else if (accuracy >= 90)
			return 'A';
		else if (accuracy >= 80)
			return 'B';
		else if (accuracy >= 70)
			return 'C';
			
		return 'D';
	}
	
	/**
		The player for this score processor.
	**/
	public var player:Int;
	
	/**
		The current score of this player.
	**/
	public var score:Int;
	
	/**
		The current accuracy of this player, from 0 to 100.
	**/
	public var accuracy:Float;
	
	/**
		The current health of this player, from 0 to 100.
	**/
	public var health:Float = 50;
	
	/**
		How many notes this player has currently hit without missing.
	**/
	public var combo:Int;
	
	/**
		The highest amount of notes this player has hit without missing.
	**/
	public var maxCombo:Int;
	
	/**
		Whether or not this player has failed the song.
	**/
	public var failed(get, never):Bool;
	
	/**
		Forces this player to fail regardless of their health.
	**/
	public var forceFail:Bool = false;
	
	/**
		The current hit/miss statistics for this player.
	**/
	public var stats:Array<HitStat> = [];
	
	/**
		The current count of each judgement for this player.
	**/
	public var currentJudgements:Map<Judgement, Int> = [MARV => 0, SICK => 0, GOOD => 0, BAD => 0, SHIT => 0, MISS => 0];
	
	/**
		The millisecond windows for each judgement.
	**/
	public var judgementWindow:Map<Judgement, Float> = new Map();
	
	/**
		The window release multiplier for long notes judgements.
	**/
	public var windowReleaseMultiplier:Map<Judgement, Float> = [MARV => 1.5, SICK => 1.5, GOOD => 1.5, BAD => 1.5, SHIT => 1.5];
	
	/**
		Gets the current total judgement count.
	**/
	public var totalJudgementCount(get, never):Int;
	
	var ruleset:GameplayRuleset;
	var totalJudgements:Int;
	var summedScore:Int;
	var multiplierCount:Int;
	var multiplierIndex:Int;
	var multiplierMaxIndex:Int = 15;
	var multiplierCountToIncreaseIndex:Int = 10;
	var maxMultiplierCount(get, never):Int;
	var scoreCount:Int;
	var judgementScoreWeighting:Map<Judgement, Int> = [MARV => 100, SICK => 50, GOOD => 25, BAD => 10, SHIT => 5, MISS => 0];
	var judgementHealthWeighting:Map<Judgement, Float> = [MARV => 0.5, SICK => 0.4, GOOD => 0.2, BAD => -3, SHIT => -4.5, MISS => -6];
	var judgementAccuracyWeighting:Map<Judgement, Float> = [MARV => 100, SICK => 98.25, GOOD => 65, BAD => 25, SHIT => -100, MISS => -50];
	
	public function new(ruleset:GameplayRuleset, player:Int)
	{
		this.ruleset = ruleset;
		this.player = player;
		
		initializeJudgementWindows();
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
	
	/**
		Returns an FC rating of this score processor.
	**/
	public function getFCText()
	{
		if (currentJudgements[Judgement.MISS] > 0 || currentJudgements[Judgement.SHIT] > 0 || totalJudgementCount == 0)
			return '';
		if (currentJudgements[Judgement.BAD] > 0)
			return ' [FC]';
		if (currentJudgements[Judgement.GOOD] > 0)
			return ' [Good FC]';
		if (currentJudgements[Judgement.SICK] > 0)
			return ' [Sick FC]';
			
		return ' [Marvelous FC]';
	}
	
	public function registerScore(judgement:Judgement, isLongNoteRelease:Bool = false)
	{
		currentJudgements[judgement]++;
		
		accuracy = calculateAccuracy();
		
		var comboBreakJudgement = Settings.comboBreakJudgement;
		if (comboBreakJudgement == MARV || comboBreakJudgement == GHOST)
			comboBreakJudgement = MISS;
			
		if ((judgement : Int) < (comboBreakJudgement : Int))
		{
			if ((judgement : Int) >= (Judgement.BAD : Int))
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
				forceFail = true;
		}
		
		multiplierCount = Std.int(FlxMath.bound(multiplierCount, 0, maxMultiplierCount));
		
		multiplierIndex = Math.floor(multiplierCount / multiplierCountToIncreaseIndex);
		scoreCount += judgementScoreWeighting[judgement] + multiplierIndex * multiplierCountToIncreaseIndex;
		
		final standardizedMaxScore = 1000000;
		score = Math.round(standardizedMaxScore * (scoreCount / summedScore));
		
		var healthAdd = judgementHealthWeighting[judgement];
		if (healthAdd > 0)
			healthAdd *= Settings.healthGain;
		else if (healthAdd < 0)
			healthAdd *= Settings.healthLoss;
		health = FlxMath.bound(health + healthAdd, 0, 100);
		
		ruleset.judgementAdded.dispatch(judgement, player);
	}
	
	public function destroy()
	{
		stats = FlxDestroyUtil.destroyArray(stats);
		currentJudgements = null;
		judgementWindow = null;
		judgementScoreWeighting = null;
		judgementHealthWeighting = null;
		judgementAccuracyWeighting = null;
		windowReleaseMultiplier = null;
		ruleset = null;
	}
	
	function initializeJudgementWindows()
	{
		judgementWindow[Judgement.MARV] = Settings.marvWindow;
		judgementWindow[Judgement.SICK] = Settings.sickWindow;
		judgementWindow[Judgement.GOOD] = Settings.goodWindow;
		judgementWindow[Judgement.BAD] = Settings.badWindow;
		judgementWindow[Judgement.SHIT] = Settings.shitWindow;
		judgementWindow[Judgement.MISS] = Settings.missWindow;
	}
	
	function initializeMods()
	{
		for (judgement => _ in judgementWindow)
			judgementWindow[judgement] *= GameplayGlobals.playbackRate;
	}
	
	function getTotalJudgementCount()
	{
		var judgements = 0;
		for (note in ruleset.song.notes)
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
		var density = ruleset.song.getActionsPerSecond(GameplayGlobals.playbackRate);
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
		return (health <= 0 && Settings.canDie) || forceFail;
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
