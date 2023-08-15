package states.editors;

import flixel.FlxG;
import flixel.FlxObject;
import objects.menus.lists.TextMenuList;
import states.editors.SongEditorState;
import states.menus.MainMenuState;

class ToolboxState extends FNFState
{
	static var lastSelected:Int = 0;
	
	var items:TextMenuList;
	var camFollow:FlxObject;
	
	override function destroy()
	{
		super.destroy();
		items = null;
		camFollow = null;
	}
	
	override function create()
	{
		DiscordClient.changePresence(null, "Toolbox Menu");

		FlxG.cameras.reset(new FNFCamera());
		
		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF353535;
		add(bg);
		
		items = new TextMenuList();
		items.onChange.add(onChange);
		add(items);
		
		createItem('Character Editor', function()
		{
			FlxG.sound.music.stop();
			Paths.clearCache = true;
			FlxG.switchState(new CharacterEditorState());
		});
		createItem('Song Editor', function()
		{
			FlxG.sound.music.stop();
			Paths.clearCache = true;
			FlxG.switchState(new SongEditorState(null, 0, false));
		});
		createItem('Image Optimizer', function()
		{
			FlxG.sound.music.stop();
			FlxG.switchState(new ImageOptimizerState());
		});
		
		camFollow = new FlxObject(FlxG.width / 2);
		FlxG.camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);
		
		items.selectItem(lastSelected);
		FlxG.camera.snapToTarget();
		
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			CoolUtil.playMenuMusic();
			
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (PlayerSettings.checkAction(BACK_P))
			FlxG.switchState(new MainMenuState());
			
		if (FlxG.mouse.visible)
			FlxG.mouse.visible = false;
	}
	
	function createItem(name:String, callback:Void->Void)
	{
		var item = new TextMenuItem(0, items.length * 100, name, callback);
		item.screenCenter(X);
		return items.addItem(name, item);
	}
	
	function onChange(item:TextMenuItem)
	{
		updateCamFollow();
		lastSelected = item.ID;
	}
	
	function updateCamFollow()
	{
		var midpoint = items.selectedItem.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}
}
