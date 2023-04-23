package states.editors;

import data.PlayerSettings;
import flixel.FlxG;
import flixel.FlxObject;
import states.editors.SongEditorState;
import states.menus.MainMenuState;
import ui.lists.TextMenuList;

class ToolboxState extends FNFState
{
	static var lastSelected:Int = 0;

	var items:TextMenuList;
	var camFollow:FlxObject;

	override function create()
	{
		if (!FlxG.sound.musicPlaying)
			CoolUtil.playMenuMusic();

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF353535;
		add(bg);

		items = new TextMenuList();
		items.onChange.add(onChange);
		add(items);

		createItem('Character Offset Editor', function()
		{
			FlxG.sound.music.stop();
			FlxG.switchState(new CharacterEditorState());
		});
		createItem('Song Editor', function()
		{
			FlxG.sound.music.stop();
			FlxG.switchState(new SongEditorState());
		});

		camFollow = new FlxObject(FlxG.width / 2);
		FlxG.camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);

		items.selectItem(lastSelected);
		FlxG.camera.snapToTarget();

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PlayerSettings.checkAction(BACK_P))
			FlxG.switchState(new MainMenuState());
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
