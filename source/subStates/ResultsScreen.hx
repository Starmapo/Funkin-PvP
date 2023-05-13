package subStates;

import data.PlayerSettings;
import data.Settings;
import data.game.Judgement;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.PlayState;
import states.pvp.SongSelectState;
import ui.game.PlayerStatsDisplay;

class ResultsScreen extends FlxSubState
{
	var state:PlayState;
	var camSubState:FlxCamera;
	var canExit:Bool = false;

	public function new(state:PlayState)
	{
		super();
		this.state = state;

		camSubState = new FlxCamera();
		camSubState.bgColor = FlxColor.fromRGBFloat(0, 0, 0, 0.6);
		camSubState.alpha = 0;
		FlxG.cameras.add(camSubState, false);
		cameras = [camSubState];

		var scores = [for (i in 0...2) state.ruleset.scoreProcessors[i]];
		var conditions = [
			for (i in 0...2)
				switch (Settings.winCondition)
				{
					case ACCURACY:
						FlxMath.roundDecimal(scores[i].accuracy, 2);
					case MISSES:
						scores[i].currentJudgements[Judgement.MISS];
					default:
						scores[i].score;
				}
		];
		var winText = switch (Settings.winCondition)
		{
			case MISSES:
				compareReverse(conditions[0], conditions[1]);
			default:
				compare(conditions[0], conditions[1]);
		}
		var winner = switch (winText)
		{
			case 'Player 1 wins!': 0;
			case 'Player 2 wins!': 1;
			default: -1;
		}

		var titleText = new FlxText(0, 10, 0, winText);
		titleText.setFormat('PhantomMuff 1.5', 64, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		titleText.screenCenter(X);
		add(titleText);

		for (i in 0...2)
		{
			var display = new PlayerStatsDisplay(scores[i], 32, 180);
			add(display);

			var color = (winner < 0 || i == winner) ? FlxColor.LIME : FlxColor.RED;
			switch (Settings.winCondition)
			{
				case SCORE:
					display.scoreText.color = color;
				case ACCURACY:
					display.gradeText.color = color;
				case MISSES:
					display.missText.color = color;
			}

			var addX = (i > 0 ? (FlxG.width / 2) : 0);

			var judgementText = new FlxText(5 + addX, display.missText.y + display.missText.height + 50, (FlxG.width / 2) - 10, 'Judgements:');
			judgementText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			add(judgementText);

			var curY = judgementText.y + judgementText.height + 2;
			for (judgement in 0...5)
			{
				var ratingText = new FlxText(5
					+ addX, curY, (FlxG.width / 2)
					- 10,
					Judgement.getJudgementName(judgement)
					+ ': '
					+ scores[i].currentJudgements[judgement]);
				ratingText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				add(ratingText);
				curY += ratingText.height + 2;
			}
		}

		var pressText = new FlxText(0, FlxG.height - 10, 0, 'Press ACCEPT to continue');
		pressText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		pressText.screenCenter(X);
		pressText.y -= pressText.height;
		add(pressText);

		FlxTween.tween(camSubState, {alpha: 1}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				canExit = true;
			}
		});
	}

	override function update(elapsed:Float)
	{
		if (canExit && PlayerSettings.checkAction(ACCEPT_P))
		{
			canExit = false;
			state.exit(new SongSelectState());
			CoolUtil.playPvPMusic();
		}
	}

	override function destroy()
	{
		super.destroy();
		state = null;
		camSubState = null;
	}

	function compare(a:Float, b:Float)
	{
		if (a > b)
			return 'Player 1 wins!';
		else if (b > a)
			return 'Player 2 wins!';
		else
			return 'Tie!';
	}

	function compareReverse(a:Float, b:Float)
	{
		if (a < b)
			return 'Player 1 wins!';
		else if (b < a)
			return 'Player 2 wins!';
		else
			return 'Tie!';
	}
}
