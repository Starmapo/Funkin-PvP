package subStates;

import data.PlayerSettings;
import data.Settings;
import data.game.Judgement;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.PlayState;
import states.pvp.SongSelectState;
import ui.game.PlayerStatsDisplay;

class ResultsScreen extends FNFSubState
{
	static final PLAYER_1_WIN:String = 'Player 1 wins!';
	static final PLAYER_2_WIN:String = 'Player 2 wins!';
	static final TIE:String = 'Tie!';

	public var winner:Int;

	var state:PlayState;
	var canExit:Bool = false;

	public function new(state:PlayState)
	{
		super();
		this.state = state;

		createCamera();
		camSubState.alpha = 0;

		var scores = [for (i in 0...2) state.ruleset.playfields[i].scoreProcessor];
		var winText = '';
		if (state.died)
		{
			if (!scores[0].failed)
				winText = PLAYER_1_WIN;
			else if (!scores[1].failed)
				winText = PLAYER_2_WIN;
			else
				winText = TIE;
		}
		else
		{
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
			winText = switch (Settings.winCondition)
			{
				case MISSES:
					compareReverse(conditions[0], conditions[1]);
				default:
					compare(conditions[0], conditions[1]);
			}
		}
		winner = switch (winText)
		{
			case PLAYER_1_WIN: 0;
			case PLAYER_2_WIN: 1;
			default: -1;
		}

		var titleText = new FlxText(0, 10, 0, winText);
		titleText.setFormat('PhantomMuff 1.5', 64, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		titleText.screenCenter(X);
		titleText.active = false;
		add(titleText);

		for (i in 0...2)
		{
			var display = new PlayerStatsDisplay(scores[i], 32, 180);
			add(display);

			if (!state.died)
			{
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
			}

			var addX = (i > 0 ? (FlxG.width / 2) : 0);

			var judgementText = new FlxText(5 + addX, display.missText.y + display.missText.height + 50, (FlxG.width / 2) - 10, 'Judgements:');
			judgementText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			judgementText.active = false;
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
				ratingText.active = false;
				add(ratingText);
				curY += ratingText.height + 2;
			}
		}

		var pressText = new FlxText(0, FlxG.height - 10, 0, 'Press ACCEPT to continue\nPress RESET to restart the song');
		pressText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		pressText.screenCenter(X);
		pressText.y -= pressText.height;
		pressText.active = false;
		add(pressText);

		FlxTween.tween(camSubState, {alpha: 1}, Main.getTransitionTime(), {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				canExit = true;
			}
		});
	}

	override function update(elapsed:Float)
	{
		if (canExit)
		{
			if (PlayerSettings.checkAction(ACCEPT_P))
			{
				canExit = false;
				state.exit(new SongSelectState());
				CoolUtil.playPvPMusic();
			}
			else if (PlayerSettings.checkAction(RESET_P))
			{
				canExit = false;
				state.exit(new PlayState(state.song));
			}
		}
	}

	override function destroy()
	{
		super.destroy();
		state = null;
	}

	function compare(a:Float, b:Float)
	{
		if (a > b)
			return PLAYER_1_WIN;
		else if (b > a)
			return PLAYER_2_WIN;
		else
			return TIE;
	}

	function compareReverse(a:Float, b:Float)
	{
		if (a < b)
			return PLAYER_1_WIN;
		else if (b < a)
			return PLAYER_2_WIN;
		else
			return TIE;
	}
}
