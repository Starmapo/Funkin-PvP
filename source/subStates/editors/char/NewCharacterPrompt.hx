package subStates.editors.char;

import data.Mods;
import data.char.CharacterInfo;
import flixel.addons.ui.FlxUIButton;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import haxe.io.Path;
import states.editors.CharacterEditorState;
import sys.FileSystem;
import ui.editors.EditorDropdownMenu;
import ui.editors.EditorInputText;
import ui.editors.EditorPanel;
import ui.editors.EditorText;

class NewCharacterPrompt extends FNFSubState
{
	var state:CharacterEditorState;
	var modDropdown:EditorDropdownMenu;
	
	public function new(state:CharacterEditorState)
	{
		super();
		this.state = state;
		checkObjects = true;
		
		createCamera();
		
		var tabMenu = new EditorPanel([
			{
				name: 'tab',
				label: 'Create a new character...'
			}
		]);
		tabMenu.resize(278, 90);
		
		var tab = tabMenu.createTab('tab');
		var spacing = 4;
		var inputSpacing = 94;
		
		var charNameLabel = new EditorText(4, 4, 0, 'Character Name:');
		tab.add(charNameLabel);
		
		var charNameInput = new EditorInputText(charNameLabel.x + inputSpacing, charNameLabel.y - 1, 0, null, 8, true, camSubState);
		tab.add(charNameInput);
		
		var modLabel = new EditorText(charNameLabel.x, charNameLabel.y + charNameLabel.height + spacing, 0, 'Mod:');
		tab.add(modLabel);
		
		modDropdown = new EditorDropdownMenu(modLabel.x + inputSpacing, modLabel.y, EditorDropdownMenu.makeStrIdLabelArray(Mods.getMods()), null, tabMenu);
		modDropdown.selectedLabel = Mods.currentMod;
		
		var createButton = new FlxUIButton(0, modDropdown.y + modDropdown.height + spacing, 'Create', function()
		{
			var char = charNameInput.text;
			if (char.length < 1 || FlxStringUtil.hasInvalidChars(char))
			{
				FlxTween.cancelTweensOf(charNameInput);
				FlxTween.color(charNameInput, 0.2, FlxColor.RED, FlxColor.WHITE, {startDelay: 0.2});
				return;
			}
			
			var mod = modDropdown.selectedLabel;
			var fullPath = Path.join([Mods.modRoot, mod, 'data/characters', char + '.json']);
			if (Paths.exists(fullPath))
			{
				FlxTween.cancelTweensOf(charNameInput);
				FlxTween.color(charNameInput, 0.2, FlxColor.RED, FlxColor.WHITE, {startDelay: 0.2});
				return;
			}
			
			state.save(false);
			
			var path = Path.directory(fullPath);
			FileSystem.createDirectory(path);
			
			var charInfo = new CharacterInfo({
				image: 'characters/dad',
				anims: [
					{
						name: 'idle',
						atlasName: 'Dad idle dance'
					}
				]
			});
			charInfo.directory = path;
			charInfo.name = char;
			charInfo.mod = mod;
			
			charInfo.save(fullPath);
			state.setInfo(charInfo);
			close();
		});
		createButton.x += (tabMenu.width - createButton.width) / 2;
		tab.add(createButton);
		
		tab.add(modDropdown);
		tabMenu.addGroup(tab);
		tabMenu.screenCenter();
		add(tabMenu);
		
		var closeButton = new FlxUIButton(tabMenu.x + tabMenu.width - 20 - spacing, tabMenu.y + spacing, "X", function()
		{
			close();
		});
		closeButton.resize(20, 20);
		closeButton.color = FlxColor.RED;
		closeButton.label.color = FlxColor.WHITE;
		add(closeButton);
	}
	
	override function destroy()
	{
		super.destroy();
		state = null;
	}
	
	public function updateMod()
	{
		modDropdown.selectedLabel = state.info.mod;
	}
}
