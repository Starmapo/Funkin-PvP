package states.menus;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.DiscordClient;
import util.UpdateUtil.UpdateCheckCallback;

class UpdateState extends FNFState
{
	var updateCheck:UpdateCheckCallback;
	
	public function new(updateCheck:UpdateCheckCallback)
	{
		super();
		this.updateCheck = updateCheck;
	}
	
	override function create()
	{
		DiscordClient.changePresence(null, "Update Found");
		
		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF353535;
		add(bg);
		
		var updateText = new FlxText(0, 10, 0, "New update found");
		updateText.setFormat(Paths.FONT_PHANTOMMUFF, 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		updateText.screenCenter(X);
		add(updateText);
		
		super.create();
	}
	
	override function destroy()
	{
		super.destroy();
		updateCheck = null;
	}
}
