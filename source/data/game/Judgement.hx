package data.game;

enum abstract Judgement(Int) from Int to Int
{
	var MARV = 0;
	var SICK = 1;
	var GOOD = 2;
	var BAD = 3;
	var SHIT = 4;
	var MISS = 5;
	var GHOST = 6;

	public static function getJudgementName(judgement:Judgement)
	{
		return switch (judgement)
		{
			case MARV: 'Marvelous';
			case SICK: 'Sick';
			case GOOD: 'Good';
			case BAD: 'Bad';
			case SHIT: 'Shit';
			case MISS: 'Miss';
			case GHOST: 'Ghost Tap';
			default: '';
		}
	}
}
