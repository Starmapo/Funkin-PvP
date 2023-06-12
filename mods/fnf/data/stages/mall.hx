function onCreate()
{
	if (!Settings.distractions)
		close();
}

function onBeatHit(beat, decBeat)
{
	if (!Settings.lowQuality && Settings.distractions)
		upperBoppers.animation.play('bop', true);
	if (Settings.distractions)
	{
		bottomBoppers.animation.play('bop', true);
		santa.animation.play('idle', true);
	}
}
