package states.menus;

import backend.github.GitHubRelease;
import backend.util.MarkdownUtil;
import backend.util.UpdateUtil;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.menus.ScrollBar;

using StringTools;

class UpdateState extends FNFState
{
	var updateCheck:UpdateCheckCallback;
	var release:GitHubRelease;
	var changelogCamera:FlxCamera;
	var downloadText:FlxText;
	var skipText:FlxText;
	var onSkip:Bool = false;
	
	public function new(updateCheck:UpdateCheckCallback)
	{
		super();
		this.updateCheck = updateCheck;
		release = updateCheck.release;
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
		
		downloadText = new FlxText(0, changelogCamera.y + changelogCamera.height + 30, 0, "Download");
		downloadText.setFormat(Paths.FONT_PHANTOMMUFF, 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		downloadText.x += (FlxG.width / 2 - downloadText.width) / 2;
		add(downloadText);
		
		skipText = new FlxText(FlxG.width / 2, downloadText.y, 0, "Skip");
		skipText.setFormat(Paths.FONT_PHANTOMMUFF, 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		skipText.x += (FlxG.width / 2 - skipText.width) / 2;
		add(skipText);
		
		updateSelected();
		
		super.create();
	}
	
	override function update(elapsed)
	{
		if (PlayerSettings.checkAction(UI_LEFT_P) || PlayerSettings.checkAction(UI_RIGHT_P))
		{
			onSkip = !onSkip;
			updateSelected();
			CoolUtil.playScrollSound();
		}
		
		if (PlayerSettings.checkAction(ACCEPT_P))
		{
			if (onSkip)
			{
				FlxG.switchState(new MainMenuState());
				CoolUtil.playCancelSound();
			}
			else
			{
				FlxG.openURL(release.html_url);
				CoolUtil.playConfirmSound();
			}
		}
		
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
	
	override function destroy()
	{
		super.destroy();
		updateCheck = null;
		release = null;
		changelogCamera = null;
		downloadText = null;
		skipText = null;
	}
	
	function updateSelected()
	{
		downloadText.alpha = !onSkip ? 1 : 0.6;
		skipText.alpha = onSkip ? 1 : 0.6;
	}
}
