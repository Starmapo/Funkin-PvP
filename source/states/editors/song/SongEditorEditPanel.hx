package states.editors.song;

import flixel.FlxG;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;
import util.editors.EditorInputText;

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
		resize(350, 250);
		x = FlxG.width - width;
		screenCenter(Y);
		y -= 132;
		this.state = state;

		var songTab = createTab('Song');

		var spacing = 4;
		var inputSpacing = 100;

		var titleLabel = new FlxUIText(4, 5, 0, 'Title:');
		titleLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(titleLabel);

		var titleInput = new EditorInputText(titleLabel.x + inputSpacing, 4, 120, state.song.title);
		songTab.add(titleInput);

		var artistLabel = new FlxUIText(titleLabel.x, titleLabel.y + titleLabel.height + spacing, 0, 'Artist:');
		artistLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(artistLabel);

		var artistInput = new EditorInputText(artistLabel.x + inputSpacing, artistLabel.y, 120, state.song.artist);
		songTab.add(artistInput);

		var sourceLabel = new FlxUIText(artistLabel.x, artistLabel.y + artistLabel.height + spacing, 0, 'Source:');
		sourceLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(sourceLabel);

		var sourceInput = new EditorInputText(sourceLabel.x + inputSpacing, sourceLabel.y, 120, state.song.source);
		songTab.add(sourceInput);

		var instLabel = new FlxUIText(sourceLabel.x, sourceLabel.y + sourceLabel.height + spacing, 0, 'Instrumental File:');
		instLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(instLabel);

		var instInput = new EditorInputText(instLabel.x + inputSpacing, instLabel.y, 120, state.song.instFile);
		songTab.add(instInput);

		var vocalsLabel = new FlxUIText(instLabel.x, instLabel.y + instLabel.height + spacing, 0, 'Vocals File:');
		vocalsLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		songTab.add(vocalsLabel);

		var vocalsInput = new EditorInputText(vocalsLabel.x + inputSpacing, vocalsLabel.y, 120, state.song.vocalsFile);
		songTab.add(vocalsInput);

		addGroup(songTab);
	}
}
