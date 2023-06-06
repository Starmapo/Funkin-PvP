package subStates.editors.song;

import data.Mods;
import data.song.Song;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.io.Path;
import states.editors.SongEditorState;
import sys.FileSystem;
import sys.io.File;
import systools.Dialogs;
import ui.editors.EditorInputText;
import ui.editors.EditorPanel;
import ui.editors.EditorText;

class SongEditorNewSongPrompt extends FNFSubState
{
	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;
		checkObjects = true;

		createCamera();

		var tabMenu = new EditorPanel([
			{
				name: 'tab',
				label: 'Create a new song...'
			}
		]);
		tabMenu.resize(244, 150);

		var tab = tabMenu.createTab('tab');
		var spacing = 4;
		var inputSpacing = 84;

		var instFile = '';
		var vocalsFile = '';

		var instButton:FlxUIButton = null;
		instButton = new FlxUIButton(0, 4, 'Instrumental File', function()
		{
			var result = Dialogs.openFile("Select the instrumental file", '', {
				count: 1,
				descriptions: ['OGG files'],
				extensions: ['*.ogg']
			});
			if (result == null || result[0] == null)
			{
				if (instFile.length > 0)
				{
					FlxTween.cancelTweensOf(instButton);
					FlxTween.color(instButton, 0.2, instButton.color, FlxColor.RED);
				}
				instFile = '';
				return;
			}

			instFile = Path.normalize(result[0]);
			FlxTween.cancelTweensOf(instButton);
			FlxTween.color(instButton, 0.2, instButton.color, FlxColor.LIME);
		});
		instButton.resize(120, instButton.height);
		instButton.x += (tabMenu.width - instButton.width) / 2;

		var vocalsButton:FlxUIButton = null;
		vocalsButton = new FlxUIButton(0, instButton.y + instButton.height + spacing, 'Vocals File', function()
		{
			var result = Dialogs.openFile("Select the vocals file", '', {
				count: 1,
				descriptions: ['OGG files'],
				extensions: ['*.ogg']
			});
			if (result == null || result[0] == null)
			{
				if (vocalsFile.length > 0)
				{
					FlxTween.cancelTweensOf(vocalsButton);
					FlxTween.color(vocalsButton, 0.2, vocalsButton.color, FlxColor.WHITE);
				}
				vocalsFile = '';
				return;
			}

			vocalsFile = Path.normalize(result[0]);
			FlxTween.cancelTweensOf(vocalsButton);
			FlxTween.color(vocalsButton, 0.2, vocalsButton.color, FlxColor.LIME);
		});
		vocalsButton.resize(120, vocalsButton.height);
		vocalsButton.x += (tabMenu.width - vocalsButton.width) / 2;

		var songNameLabel = new EditorText(4, vocalsButton.y + vocalsButton.height + spacing + 1, 0, 'Song Name:');

		var songNameInput = new EditorInputText(songNameLabel.x + inputSpacing, songNameLabel.y - 1, 0, null, 8, true, camSubState);

		var difficultyNameLabel = new EditorText(songNameLabel.x, songNameLabel.y + songNameLabel.height + spacing, 0, 'Difficulty Name:');

		var difficultyNameInput = new EditorInputText(difficultyNameLabel.x + inputSpacing, difficultyNameLabel.y - 1, 0, null, 8, true, camSubState);

		var modLabel = new EditorText(difficultyNameLabel.x, difficultyNameLabel.y + difficultyNameLabel.height + spacing, 0, 'Mod:');

		var modInput = new EditorInputText(modLabel.x + inputSpacing, modLabel.y - 1, 0, Mods.currentMod, 8, true, camSubState);

		var createButton = new FlxUIButton(0, modLabel.y + modLabel.height + spacing, 'Create', function()
		{
			if (instFile.length < 1)
			{
				FlxTween.cancelTweensOf(instButton);
				FlxTween.color(instButton, 0.2, FlxColor.RED, FlxColor.WHITE, {startDelay: 0.2});
				return;
			}
			if (songNameInput.text.length < 1)
			{
				FlxTween.cancelTweensOf(songNameInput);
				FlxTween.color(songNameInput, 0.2, FlxColor.RED, FlxColor.WHITE, {startDelay: 0.2});
				return;
			}
			if (difficultyNameInput.text.length < 1)
			{
				FlxTween.cancelTweensOf(difficultyNameInput);
				FlxTween.color(difficultyNameInput, 0.2, FlxColor.RED, FlxColor.WHITE, {startDelay: 0.2});
				return;
			}
			if (modInput.text.length < 1)
			{
				FlxTween.cancelTweensOf(modInput);
				FlxTween.color(modInput, 0.2, FlxColor.RED, FlxColor.WHITE, {startDelay: 0.2});
				return;
			}

			state.save(false);

			var path = Path.join([Mods.modsPath, modInput.text, 'songs', songNameInput.text]);
			trace(path);
			FileSystem.createDirectory(path);
			File.copy(instFile, Path.join([path, 'Inst.ogg']));
			if (vocalsFile.length > 0)
				File.copy(vocalsFile, Path.join([path, 'Voices.ogg']));

			var song = new Song({title: songNameInput.text, timingPoints: [{}]});
			song.directory = path;
			song.name = songNameInput.text;
			song.difficultyName = difficultyNameInput.text;
			song.mod = modInput.text;
			song.sort();

			song.save(Path.join([path, song.difficultyName + '.json']));
			FlxG.switchState(new SongEditorState(song));
		});
		createButton.x += (tabMenu.width - createButton.width) / 2;

		tab.add(instButton);
		tab.add(vocalsButton);
		tab.add(songNameLabel);
		tab.add(songNameInput);
		tab.add(difficultyNameLabel);
		tab.add(difficultyNameInput);
		tab.add(modLabel);
		tab.add(modInput);
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
}