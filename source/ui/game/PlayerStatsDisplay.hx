package ui.game;

import data.game.Judgement;
import data.game.ScoreProcessor;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class PlayerStatsDisplay extends FlxGroup
{
	var player:Int;
	var scoreProcessor:ScoreProcessor;
	var scoreText:FlxText;
	var gradeText:FlxText;
	var comboText:FlxText;
	var missText:FlxText;

	public function new(player:Int, scoreProcessor:ScoreProcessor)
	{
		super();
		this.player = player;
		this.scoreProcessor = scoreProcessor;

		var pos = 5 + (FlxG.width / 2) * player;

		scoreText = new FlxText(pos, FlxG.height * 0.8, (FlxG.width / 2) - 10);
		scoreText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(scoreText);

		gradeText = new FlxText(pos, scoreText.y + scoreText.height + 2, (FlxG.width / 2) - 10);
		gradeText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(gradeText);

		comboText = new FlxText(pos, gradeText.y + gradeText.height + 2, (FlxG.width / 2) - 10);
		comboText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(comboText);

		missText = new FlxText(pos, comboText.y + comboText.height + 2, (FlxG.width / 2) - 10);
		missText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(missText);
	}

	override function update(elapsed:Float)
	{
		scoreText.text = 'Score: ' + scoreProcessor.score;

		var accuracy = scoreProcessor.accuracy;
		gradeText.text = 'Grade: ' + getGradeFromAccuracy(accuracy) + ' (' + FlxMath.roundDecimal(accuracy, 2) + '%)' + getFCText();

		var maxCombo = scoreProcessor.maxCombo;
		comboText.text = 'Combo: ' + scoreProcessor.combo + (maxCombo > 0 ? ' (Max: $maxCombo)' : '');

		missText.text = 'Misses: ' + scoreProcessor.currentJudgements[Judgement.MISS];
	}

	function getGradeFromAccuracy(accuracy:Float)
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

	function getFCText()
	{
		if (scoreProcessor.currentJudgements[MISS] > 0
			|| scoreProcessor.currentJudgements[SHIT] > 0
			|| scoreProcessor.totalJudgementCount == 0)
			return '';
		if (scoreProcessor.currentJudgements[BAD] > 0)
			return ' [FC]';
		if (scoreProcessor.currentJudgements[GOOD] > 0)
			return ' [Good FC]';
		if (scoreProcessor.currentJudgements[SICK] > 0)
			return ' [Sick FC]';

		return ' [Marvelous FC]';
	}
}
