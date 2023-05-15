package ui.game;

import data.PlayerSettings;
import data.game.Judgement;
import data.game.ScoreProcessor;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class PlayerStatsDisplay extends FlxGroup
{
	public var scoreText:FlxText;
	public var gradeText:FlxText;
	public var comboText:FlxText;
	public var missText:FlxText;

	var scoreProcessor:ScoreProcessor;

	public function new(scoreProcessor:ScoreProcessor, size:Int = 16, ?startY:Float)
	{
		super();
		this.scoreProcessor = scoreProcessor;
		var player = scoreProcessor.player;
		if (startY == null)
		{
			var config = PlayerSettings.players[player].config;
			startY = (config.downScroll ? 120 : FlxG.height - 200);
		}

		var pos = 5 + (FlxG.width / 2) * player;

		scoreText = new FlxText(pos, startY, (FlxG.width / 2) - 10);
		scoreText.setFormat('VCR OSD Mono', size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(scoreText);

		gradeText = new FlxText(pos, scoreText.y + scoreText.height + 2, (FlxG.width / 2) - 10);
		gradeText.setFormat('VCR OSD Mono', size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(gradeText);

		comboText = new FlxText(pos, gradeText.y + gradeText.height + 2, (FlxG.width / 2) - 10);
		comboText.setFormat('VCR OSD Mono', size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(comboText);

		missText = new FlxText(pos, comboText.y + comboText.height + 2, (FlxG.width / 2) - 10);
		missText.setFormat('VCR OSD Mono', size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(missText);

		updateText();
	}

	override function update(elapsed:Float)
	{
		updateText();
	}

	override function destroy()
	{
		super.destroy();
		scoreProcessor = null;
		scoreText = null;
		gradeText = null;
		comboText = null;
		missText = null;
	}

	public function updateText()
	{
		scoreText.text = 'Score: ' + scoreProcessor.score;

		var accuracy = FlxMath.roundDecimal(scoreProcessor.accuracy, 2);
		gradeText.text = 'Grade: ' + CoolUtil.getGradeFromAccuracy(accuracy) + ' (' + accuracy + '%)' + CoolUtil.getFCText(scoreProcessor);

		var maxCombo = scoreProcessor.maxCombo;
		comboText.text = 'Combo: ' + scoreProcessor.combo + (maxCombo > 0 ? ' (Max: $maxCombo)' : '');

		missText.text = 'Misses: ' + scoreProcessor.currentJudgements[MISS];
	}
}
