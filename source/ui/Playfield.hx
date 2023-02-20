package ui;

import data.PlayerConfig;
import data.skin.NoteSkin;
import flixel.FlxG;
import flixel.group.FlxGroup;

/**
	Playfield contains everything for a player to see: receptors, splashes, ratings, score display,
	and of course, the notes themselves.
**/
class Playfield extends FlxGroup
{
	public var player(default, null):Int = 0;
	public var playerConfig(default, null):PlayerConfig;
	public var noteSkin(default, null):NoteSkin;
	public var receptors(default, null):FlxTypedGroup<Receptor>;

	public function new(player:Int = 0, noteSkin:NoteSkin)
	{
		super();
		this.player = player;
		this.noteSkin = noteSkin;
		playerConfig = FlxG.save.data.playerConfigs[player];

		initReceptors();
	}

	function initReceptors()
	{
		receptors = new FlxTypedGroup();
		add(receptors);

		var curX:Float = noteSkin.receptorsOffset[0];
		if (player == 1)
		{
			curX += FlxG.width / 2;
		}
		for (i in 0...4)
		{
			var receptor = new Receptor(curX, noteSkin.receptorsOffset[1], i, noteSkin);
			receptors.add(receptor);

			curX += receptor.width + noteSkin.receptorsPadding;
		}

		var newX = ((FlxG.width / 2) - CoolUtil.getGroupWidth(receptors)) / 2;
		for (receptor in receptors)
		{
			receptor.x += newX;
		}
	}
}
