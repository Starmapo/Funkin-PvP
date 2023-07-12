package ui.game;

import data.Settings;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class NPSDisplay extends FlxText
{
	public var nps:Float = 0;
	public var maxNPS:Float = 0;
	
	var currentTimes:Array<Float> = [];
	
	public function new(player:Int)
	{
		super(5 + (FlxG.width / 2) * player, 0, (FlxG.width / 2) - 10);
		setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		
		var config = Settings.playerConfigs[player];
		y = (config.downScroll ? 50 : FlxG.height - 60);
	}
	
	override function update(elapsed:Float)
	{
		var curTime = Sys.time();
		var i = currentTimes.length - 1;
		while (i >= 0)
		{
			var time = currentTimes[i];
			if (time + 1 < curTime)
				currentTimes.remove(time);
			else
				break;
			i--;
		}
		nps = currentTimes.length;
		if (nps > maxNPS)
			maxNPS = nps;
		updateText();
	}
	
	override function destroy()
	{
		super.destroy();
		currentTimes = null;
	}
	
	public function updateText()
	{
		var t = 'NPS: $nps';
		if (maxNPS > 0)
			t += ' (Max: $maxNPS)';
			
		if (text != t)
			text = t;
	}
	
	public function addTime(time:Float)
	{
		currentTimes.unshift(time);
		updateText();
	}
}
