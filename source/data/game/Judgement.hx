package data.game;

/**
	States how well you hit (or missed) a note.

	Can be passed to or from `Int`.
**/
enum abstract Judgement(Int) from Int to Int
{
	/**
		"Marvelous" rating.
	**/
	var MARV = 0;
	
	/**
		"Sick" rating.
	**/
	var SICK = 1;
	
	/**
		"Good" rating.
	**/
	var GOOD = 2;
	
	/**
		"Bad" rating.
	**/
	var BAD = 3;
	
	/**
		"Shit" rating.
	**/
	var SHIT = 4;
	
	/**
		"Miss" rating.
	**/
	var MISS = 5;
	
	/**
		Ghost tap.
	**/
	var GHOST = 6;
	
	/**
		Gets the name of this judgement.
	**/
	public function getName()
	{
		return switch (abstract)
		{
			case MARV: 'Marvelous';
			case SICK: 'Sick';
			case GOOD: 'Good';
			case BAD: 'Bad';
			case SHIT: 'Shit';
			case MISS: 'Miss';
			case GHOST: 'Ghost Tap';
			default: throw 'Unknown judgement';
		}
	}
}
