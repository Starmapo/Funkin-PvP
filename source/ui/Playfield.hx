package ui;

import data.PlayerConfig;
import data.ReceptorSkin;
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
	public var skin(default, null):ReceptorSkin;
	public var receptors(default, null):FlxTypedGroup<Receptor>;

	public function new(player:Int = 0, skin:ReceptorSkin)
	{
		super();
		this.player = player;
		this.skin = skin;
		playerConfig = FlxG.save.data.playerConfigs[player];

		initReceptors();
	}

	function initReceptors()
	{
		receptors = new FlxTypedGroup();

		var curX:Float = skin.receptorsOffset[0];
		for (i in 0...4)
		{
			var receptor = new Receptor(curX, skin.receptorsOffset[1], i, skin);
			receptors.add(receptor);

			curX += receptor.width + skin.receptorsPadding;
		}

		var newX = ((FlxG.width / 2) - CoolUtil.getGroupWidth(cast receptors));
		for (receptor in receptors)
		{
			receptor.x += newX;
		}
	}
}
