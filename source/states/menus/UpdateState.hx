package states.menus;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.ScrollBar;
import util.DiscordClient;
import util.MarkdownUtil;
import util.UpdateUtil.UpdateCheckCallback;

using StringTools;

class UpdateState extends FNFState
{
	var updateCheck:UpdateCheckCallback;
	var changelogCamera:FlxCamera;
	
	public function new(updateCheck:UpdateCheckCallback)
	{
		super();
		this.updateCheck = updateCheck;
	}
	
	override function create()
	{
		DiscordClient.changePresence(null, "Update Found");
		
		changelogCamera = new FlxCamera(0, 180, FlxG.width - 20, Std.int(FlxG.height / 2));
		changelogCamera.bgColor = 0;
		FlxG.cameras.add(changelogCamera, false);
		
		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF353535;
		add(bg);
		
		var updateText = new FlxText(0, 10, 0, "New update found");
		updateText.setFormat(Paths.FONT_PHANTOMMUFF, 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		updateText.screenCenter(X);
		add(updateText);
		
		var release = updateCheck.release;
		
		var versionText = new FlxText(0, updateText.y + updateText.height + 10, 0, updateCheck.currentVersionTag + " < " + release.tag_name);
		versionText.setFormat(Paths.FONT_PHANTOMMUFF, 28, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		versionText.screenCenter(X);
		add(versionText);
		
		var changelog = release.body.replace('\r', '').trim();
		var changelogText = new FlxText(0, 0, changelogCamera.width);
		changelogText.setFormat("_sans", 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		MarkdownUtil.applyMarkdown(changelogText, changelog);
		changelogText.cameras = [changelogCamera];
		add(changelogText);
		
		var scrollBar = new ScrollBar(changelogCamera.x + changelogCamera.width, changelogCamera.y, changelogText.height, changelogCamera);
		add(scrollBar);
		
		super.create();
	}
	
	override function update(elapsed)
	{
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
	
	override function destroy()
	{
		super.destroy();
		updateCheck = null;
		changelogCamera = null;
	}
}
