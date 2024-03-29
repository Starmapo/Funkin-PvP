package subStates.editors.char;

import backend.editors.char.CharacterEditorActionManager;
import backend.structures.char.CharacterInfo;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import objects.editors.EditorPanel;
import objects.menus.ScrollBar;
import openfl.geom.Rectangle;
import states.editors.CharacterEditorState;

class AtlasNamePrompt extends FNFSubState
{
	public var anim:AnimInfo;
	
	var state:CharacterEditorState;
	var contentCamera:FlxCamera;
	var buttonGroup:FlxTypedGroup<FlxUIButton>;
	var scrollBar:ScrollBar;
	
	public function new(state:CharacterEditorState)
	{
		super();
		this.state = state;
		
		createCamera();
		
		var tabMenu = new EditorPanel([
			{
				name: 'tab',
				label: 'Select atlas animation...'
			}
		]);
		tabMenu.resize(FlxG.width / 2, FlxG.height - 50);
		tabMenu.screenCenter();
		add(tabMenu);
		
		var tab = tabMenu.createTab('tab');
		tabMenu.addGroup(tab);
		
		contentCamera = new FlxCamera(Std.int(tabMenu.x + 4), Std.int(tabMenu.y + 28), Std.int(tabMenu.width - 32), Std.int(tabMenu.height - 32));
		contentCamera.bgColor = FlxColor.WHITE;
		contentCamera.visible = false;
		FlxG.cameras.add(contentCamera, false);
		
		var dropPanel = new FlxUI9SliceSprite(0, 0, FlxUIAssets.IMG_BOX, new Rectangle(0, 0, contentCamera.width, contentCamera.height), [1, 1, 14, 14]);
		dropPanel.cameras = [contentCamera];
		add(dropPanel);
		
		buttonGroup = new FlxTypedGroup();
		add(buttonGroup);
		
		scrollBar = new ScrollBar(contentCamera.x + contentCamera.width + 4, contentCamera.y, 0, contentCamera);
		add(scrollBar);
		
		var closeButton = new FlxUIButton(tabMenu.x + tabMenu.width - 24, tabMenu.y + 4, "X", function()
		{
			close();
		});
		closeButton.resize(20, 20);
		closeButton.color = FlxColor.RED;
		closeButton.label.color = FlxColor.WHITE;
		add(closeButton);
		
		state.actionManager.onEvent.add(onEvent);
	}
	
	override function destroy()
	{
		super.destroy();
		state = null;
		if (contentCamera != null && FlxG.cameras.list.contains(contentCamera))
			FlxG.cameras.remove(contentCamera);
		contentCamera = null;
		buttonGroup = null;
	}
	
	override function onOpen()
	{
		contentCamera.visible = true;
		super.onOpen();
	}
	
	override function onClose()
	{
		contentCamera.visible = false;
		super.onClose();
	}
	
	public function refreshAtlasNames()
	{
		buttonGroup.forEach(function(button)
		{
			button.destroy();
		});
		buttonGroup.clear();
		
		var atlasNames:Array<String> = [];
		if (state.char.frames != null)
		{
			for (frame in state.char.frames.frames)
			{
				var atlasName = CoolUtil.getAtlasName(frame.name);
				if (!atlasNames.contains(atlasName))
					atlasNames.push(atlasName);
			}
			FlxStringUtil.sortAlphabetically(atlasNames);
		}
		
		var buttonHeight = 20;
		for (i in 0...atlasNames.length)
		{
			var atlasName = atlasNames[i];
			var button = new FlxUIButton(1, buttonGroup.length * buttonHeight, atlasName);
			button.broadcastToFlxUI = false;
			button.onUp.callback = onClickItem.bind(i);
			
			button.name = atlasName;
			
			button.loadGraphicSlice9([FlxUIAssets.IMG_INVIS, FlxUIAssets.IMG_HILIGHT, FlxUIAssets.IMG_HILIGHT], contentCamera.width - 2, buttonHeight - 1,
				[[1, 1, 3, 3], [1, 1, 3, 3], [1, 1, 3, 3]]);
			button.labelOffsets[FlxButton.PRESSED].y -= 1;
			
			button.over_color = FlxColor.WHITE;
			button.down_color = FlxColor.WHITE;
			
			button.label.alignment = LEFT;
			button.autoCenterLabel();
			
			for (offset in button.labelOffsets)
				offset.x += 2;
				
			button.cameras = [contentCamera];
			buttonGroup.add(button);
		}
		
		updateAtlasNames();
		
		scrollBar.contentHeight = buttonGroup.length * buttonHeight;
	}
	
	function updateAtlasNames()
	{
		var usedNames:Array<String> = [];
		for (anim in state.info.anims)
		{
			var name = anim.prefix;
			if (name.length > 0 && !usedNames.contains(anim.name))
				usedNames.push(name);
		}
		
		for (button in buttonGroup)
			button.label.color = button.up_color = (usedNames.contains(button.name)) ? 0xFF00B200 : FlxColor.BLACK;
	}
	
	function onEvent(event:String, params:Dynamic)
	{
		switch (event)
		{
			case CharacterEditorActionManager.CHANGE_IMAGE:
				refreshAtlasNames();
			case CharacterEditorActionManager.ADD_ANIM, CharacterEditorActionManager.REMOVE_ANIM, CharacterEditorActionManager.CHANGE_ANIM_PREFIX:
				updateAtlasNames();
		}
	}
	
	function onClickItem(i:Int)
	{
		if (anim != null)
			state.actionManager.perform(new ActionChangeAnimPrefix(state, anim, buttonGroup.members[i].name));
			
		close();
	}
}
