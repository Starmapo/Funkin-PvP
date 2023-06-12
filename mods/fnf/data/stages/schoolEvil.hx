function onCreate()
{
	var evilTrail = new FlxTrail(opponent, null, 4, 24, 0.3, 0.069);
	addBehindOpponent(evilTrail);

	close();
}
