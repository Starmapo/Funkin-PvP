function onEvent(event, params)
{
	switch (event)
	{
		case "Play Animation":
			if (opponent.animation.name == "plantoidsplus_giveup")
				opponent.danceDisabled = true;
		case "Switch Alt":
			if (opponent.info.mod != modID)
				return;
			if (opponent.info.name == "aero-sad")
				opponent.changeCharacter("aero-sad-alt");
			else if (opponent.info.name == "aero-sad-alt")
				opponent.changeCharacter("aero-sad");
	}
}