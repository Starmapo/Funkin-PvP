package ui.editors;

import flixel.FlxG;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import openfl.geom.Rectangle;

class EditorMenuBar extends FlxGroup
{
	var bg:FlxUI9SliceSprite;
	var menuButtons:FlxTypedGroup<EditorMenuButton>;
	var menuItems:FlxTypedGroup<EditorMenuGroup>;

	public function new()
	{
		super();

		bg = new FlxUI9SliceSprite(0, 0, Paths.getImage('editors/menuBar'), new Rectangle(0, 0, FlxG.width, 30), [6, 6, 11, 11]);
		add(bg);

		menuButtons = new FlxTypedGroup();
		add(menuButtons);

		menuItems = new FlxTypedGroup();
		add(menuItems);
	}

	public function createMenu(name:String)
	{
		var button = new EditorMenuButton(0, bg.height / 2, name, onMenuClick.bind(name));
		menuButtons.add(button);
	}

	function onMenuClick(name:String) {}
}

class EditorMenuButton extends FlxUIButton
{
	public function new(x:Float = 0, y:Float = 0, label:String, onClick:Void->Void)
	{
		super(x, y, label, onClick, true, false, 0xFF242424);
	}
}

class EditorMenuGroup extends FlxSpriteGroup
{
	var bg:FlxUI9SliceSprite;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		bg = new FlxUI9SliceSprite(0, 0, Paths.getImage('editors/menuBar'), new Rectangle(), [6, 6, 11, 11]);
		add(bg);
	}
}
