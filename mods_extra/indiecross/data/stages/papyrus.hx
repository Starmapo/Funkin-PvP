var preventDance:Array<String> = ["indiecross_ohyoumotherfucker"];
var papyrusAlt:Bool = false;

function onCreatePost()
{
	setupStrumline(gf, "!sans");
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Play Animation":
			if (preventDance.contains(params[0]))
			{
				var char = switch (params[1])
				{
					case "bf", "boyfriend", "1":
						bf;
					case "gf", "girlfriend", "2":
						gf;
					default:
						opponent;
				}
				if (char.animation.exists(params[0]))
					char.danceDisabled = char.singDisabled = true;
			}
		case "Papyrus Alt":
			if (opponent.info.name != "papyrus" || opponent.info.mod != modID)
				return;
			papyrusAlt = !papyrusAlt;
			opponent.danceAnims = [papyrusAlt ? "idle-alt" : "idle"];
			opponent.danceBeats = papyrusAlt ? 1 : 2;
			opponent.danceDisabled = opponent.singDisabled = false;
		case "Sans Bones":
			if (gf.info.name == "sanswinter")
				gf.changeCharacter("sanswinter-bone");
			else
				gf.changeCharacter("sanswinter");
			gf.dance();
		case "Bruh":
			if (opponent.info.name != "papyrus" || opponent.info.mod != modID)
				return;
			if (opponent.animation.name != "indiecross_bruh")
			{
				opponent.danceDisabled = true;
				opponent.playAnim("indiecross_bruh");
			}
			else
			{
				opponent.danceDisabled = false;
				opponent.canDance = true;
				opponent.dance();
			}
	}
}