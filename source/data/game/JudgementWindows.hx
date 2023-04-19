package data.game;

class JudgementWindows
{
	public var marvelous:Float = 23;
	public var sick:Float = 57;
	public var good:Float = 101;
	public var bad:Float = 141;
	public var shit:Float = 169;
	public var miss:Float = 218;
	public var comboBreakJudgement:Judgement = MISS;

	public function new() {}

	public function getValueFromJudgement(judgement:Judgement)
	{
		return switch (judgement)
		{
			case MARV:
				return marvelous;
			case SICK:
				return sick;
			case GOOD:
				return good;
			case BAD:
				return bad;
			case SHIT:
				return shit;
			case MISS:
				return miss;
			case GHOST:
				return 0;
		}
	}
}
