package states.editors.song;

import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;
import ui.editors.EditorInputText;
import ui.editors.EditorNumericStepper;

class SongEditorEditPanel extends EditorPanel
{
	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		super([
			{
				name: 'Song',
				label: 'Song'
			}
		]);
		resize(390, 250);
		x = FlxG.width - width - 10;
		screenCenter(Y);
		y -= 132;
		this.state = state;

		createSongTab();
	}

	function createSongTab()
	{
		var songTab = createTab('Song');

		var spacing = 4;
		var inputSpacing = 125;

		var titleLabel = new FlxUIText(4, 5, 0, 'Title:');
		titleLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(titleLabel);

		var titleInput = new EditorInputText(titleLabel.x + inputSpacing, 4, 120, state.song.title);
		titleInput.focusLost.add(function(text)
		{
			state.song.title = text;
		});
		songTab.add(titleInput);

		var artistLabel = new FlxUIText(titleLabel.x, titleLabel.y + titleLabel.height + spacing, 0, 'Artist:');
		artistLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(artistLabel);

		var artistInput = new EditorInputText(artistLabel.x + inputSpacing, artistLabel.y, 120, state.song.artist);
		artistInput.focusLost.add(function(text)
		{
			state.song.artist = text;
		});
		songTab.add(artistInput);

		var sourceLabel = new FlxUIText(artistLabel.x, artistLabel.y + artistLabel.height + spacing, 0, 'Source:');
		sourceLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(sourceLabel);

		var sourceInput = new EditorInputText(sourceLabel.x + inputSpacing, sourceLabel.y, 120, state.song.source);
		sourceInput.focusLost.add(function(text)
		{
			state.song.source = text;
		});
		songTab.add(sourceInput);

		var difficultyLabel = new FlxUIText(sourceLabel.x, sourceLabel.y + sourceLabel.height + spacing, 0, 'Difficulty Name:');
		difficultyLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(difficultyLabel);

		var difficultyInput = new EditorInputText(difficultyLabel.x + inputSpacing, difficultyLabel.y, 120, state.song.difficultyName);
		difficultyInput.focusLost.add(function(text)
		{
			state.song.difficultyName = text;
		});
		songTab.add(difficultyInput);

		var instLabel = new FlxUIText(difficultyLabel.x, difficultyLabel.y + difficultyLabel.height + spacing, 0, 'Instrumental File:');
		instLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(instLabel);

		var instInput = new EditorInputText(instLabel.x + inputSpacing, instLabel.y, 120, state.song.instFile);
		instInput.focusLost.add(function(text)
		{
			state.song.instFile = text;
		});
		songTab.add(instInput);

		var vocalsLabel = new FlxUIText(instLabel.x, instLabel.y + instLabel.height + spacing, 0, 'Vocals File:');
		vocalsLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(vocalsLabel);

		var vocalsInput = new EditorInputText(vocalsLabel.x + inputSpacing, vocalsLabel.y, 120, state.song.vocalsFile);
		vocalsInput.focusLost.add(function(text)
		{
			state.song.vocalsFile = text;
		});
		songTab.add(vocalsInput);

		var opponentLabel = new FlxUIText(vocalsLabel.x, vocalsLabel.y + vocalsLabel.height + spacing, 0, 'P1/Opponent Character:');
		opponentLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(opponentLabel);

		var opponentInput = new EditorInputText(opponentLabel.x + inputSpacing, opponentLabel.y, 120, state.song.opponent);
		opponentInput.focusLost.add(function(text)
		{
			state.song.opponent = text;
		});
		songTab.add(opponentInput);

		var bfLabel = new FlxUIText(opponentLabel.x, opponentLabel.y + opponentLabel.height + spacing, 0, 'P2/Boyfriend Character:');
		bfLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(bfLabel);

		var bfInput = new EditorInputText(bfLabel.x + inputSpacing, bfLabel.y, 120, state.song.bf);
		bfInput.focusLost.add(function(text)
		{
			state.song.bf = text;
		});
		songTab.add(bfInput);

		var gfLabel = new FlxUIText(bfLabel.x, bfLabel.y + bfLabel.height + spacing, 0, 'Girlfriend Character:');
		gfLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(gfLabel);

		var gfInput = new EditorInputText(gfLabel.x + inputSpacing, gfLabel.y, 120, state.song.gf);
		gfInput.focusLost.add(function(text)
		{
			state.song.gf = text;
		});
		songTab.add(gfInput);

		var velocityLabel = new FlxUIText(gfLabel.x, gfLabel.y + gfLabel.height + spacing, 0, 'Initial Scroll Velocity:');
		velocityLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(velocityLabel);

		var velocityStepper = new EditorNumericStepper(velocityLabel.x + inputSpacing, velocityLabel.y, 0.1, state.song.initialScrollVelocity, 0, 10, 2);
		velocityStepper.valueChanged.add(function(value, _)
		{
			state.song.initialScrollVelocity = value;
		});
		songTab.add(velocityStepper);

		var saveButton = new FlxUIButton(0, velocityStepper.y + velocityStepper.height + 20, 'Save', function()
		{
			state.save();
		});
		saveButton.x = (width - saveButton.width) / 2;
		songTab.add(saveButton);

		addGroup(songTab);
	}
}
