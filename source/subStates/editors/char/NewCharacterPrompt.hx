package subStates.editors.char;

import data.Mods;
import data.char.CharacterInfo;
import flixel.addons.ui.FlxUIButton;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.io.Path;
import states.editors.CharacterEditorState;
import sys.FileSystem;
import ui.editors.EditorInputText;
import ui.editors.EditorPanel;
import ui.editors.EditorText;

class NewCharacterPrompt extends FNFSubState
{
	var state:CharacterEditorState;
	var modInput:EditorInputText;

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
		tabMenu.resize(278, 82);

		var tab = tabMenu.createTab('tab');
		var spacing = 4;
		var inputSpacing = 94;

		var charNameLabel = new EditorText(4, 4, 0, 'Character Name:');
		tab.add(charNameLabel);

		var charNameInput = new EditorInputText(charNameLabel.x + inputSpacing, charNameLabel.y - 1, 0, null, 8, true, camSubState);
		tab.add(charNameInput);

		var modLabel = new EditorText(charNameLabel.x, charNameLabel.y + charNameLabel.height + spacing, 0, 'Mod:');
		tab.add(modLabel);

		modInput = new EditorInputText(modLabel.x + inputSpacing, modLabel.y - 1, 0, null, 8, true, camSubState);
		tab.add(modInput);

		var createButton = new FlxUIButton(0, modLabel.y + modLabel.height + spacing, 'Create', function()
		{
			if (charNameInput.text.length < 1)
			{
				FlxTween.cancelTweensOf(charNameInput);
				FlxTween.color(charNameInput, 0.2, FlxColor.RED, FlxColor.WHITE, {startDelay: 0.2});
				return;
			}
			if (modInput.text.length < 1)
			{
				FlxTween.cancelTweensOf(modInput);
				FlxTween.color(modInput, 0.2, FlxColor.RED, FlxColor.WHITE, {startDelay: 0.2});
				return;
			}

			var fullPath = Path.join([Mods.modsPath, modInput.text, 'data/characters', charNameInput.text + '.json']);
			if (FileSystem.exists(fullPath))
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
			charInfo.name = charNameInput.text;
			charInfo.mod = modInput.text;

			charInfo.save(fullPath);
			state.setInfo(charInfo);
            close();
		});
        createButton.x += (tabMenu.width - createButton.width) / 2;
		tab.add(createButton);

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
		modInput.text = state.info.mod;
	}
}
