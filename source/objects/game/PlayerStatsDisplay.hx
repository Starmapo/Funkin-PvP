package objects.game;

import backend.game.Judgement;
import backend.game.ScoreProcessor;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

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
			var config = Settings.playerConfigs[player];
			startY = (config.downScroll ? 120 : FlxG.height - 200);
		}
		
		var pos = 5 + (FlxG.width / 2) * player;
		
		scoreText = new FlxText(pos, startY, (FlxG.width / 2) - 10);
		scoreText.setFormat(Paths.FONT_VCR, size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(scoreText);
		
		gradeText = new FlxText(pos, scoreText.y + scoreText.height + 2, (FlxG.width / 2) - 10);
		gradeText.setFormat(Paths.FONT_VCR, size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(gradeText);
		
		comboText = new FlxText(pos, gradeText.y + gradeText.height + 2, (FlxG.width / 2) - 10);
		comboText.setFormat(Paths.FONT_VCR, size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(comboText);
		
		missText = new FlxText(pos, comboText.y + comboText.height + 2, (FlxG.width / 2) - 10);
		missText.setFormat(Paths.FONT_VCR, size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
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
		scoreText = FlxDestroyUtil.destroy(scoreText);
		gradeText = FlxDestroyUtil.destroy(gradeText);
		comboText = FlxDestroyUtil.destroy(comboText);
		missText = FlxDestroyUtil.destroy(missText);
	}
	
	public function updateText()
	{
		scoreText.text = 'Score: ' + scoreProcessor.score;
		
		var accuracy = FlxMath.roundDecimal(scoreProcessor.accuracy, 2);
		gradeText.text = 'Grade: ' + ScoreProcessor.getGradeFromAccuracy(accuracy) + ' (' + accuracy + '%)' + scoreProcessor.getFCText();
		
		var maxCombo = scoreProcessor.maxCombo;
		comboText.text = 'Combo: ' + scoreProcessor.combo + (maxCombo > 0 ? ' (Max: $maxCombo)' : '');
		
		missText.text = 'Misses: ' + scoreProcessor.currentJudgements[MISS];
	}
}
