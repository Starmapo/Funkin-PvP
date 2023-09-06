function onBeatHit(beat, decBeat)
{
	gosebg.animation.play('bop', true);
}

function onEvent(event, params)
{
	switch (event)
	{
		case "MLG":
			if (opponent.info.name == "gose" && opponent.info.mod == modID)
			{
				opponent.changeCharacter("gose-mlg");
				if (params[0] == "1")
					opponent.playSpecialAnim("intro");
			}
		case "Normal":
			if (opponent.info.name == "gose-mlg" && opponent.info.mod == modID)
				opponent.changeCharacter("gose");
	}
}