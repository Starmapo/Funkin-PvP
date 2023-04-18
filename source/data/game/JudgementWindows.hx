package data.game;

class JudgementWindows
{
	public var marvelous:Float = 18;
	public var sick:Float = 43;
	public var good:Float = 76;
	public var bad:Float = 106;
	public var shit:Float = 127;
	public var miss:Float = 164;
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
