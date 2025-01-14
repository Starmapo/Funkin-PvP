package objects.game;

import backend.game.Judgement;
import backend.game.ScoreProcessor;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class JudgementCounter extends FlxText
{
	var scoreProcessor:ScoreProcessor;
	var right:Bool;
	
	public function new(scoreProcessor:ScoreProcessor)
	{
		super();
		this.scoreProcessor = scoreProcessor;
		
		right = scoreProcessor.player > 0;
		setFormat(Paths.FONT_VCR, 16, FlxColor.WHITE, right ? RIGHT : LEFT, OUTLINE, FlxColor.BLACK);
		
		updateText();
	}
	
	override function update(elapsed:Float) {}
	
	public function updateText()
	{
		var t = '';
		for (i in 0...5)
		{
			t += ((i : Judgement).getName()) + ': ' + scoreProcessor.currentJudgements[i];
			if (i < 4)
				t += '\n';
		}
		
		if (text != t)
		{
			text = t;
			x = (right ? (FlxG.width - width - 5) : 5);
			screenCenter(Y);
		}
	}
	
	override function destroy()
	{
		super.destroy();
		scoreProcessor = null;
	}
}
