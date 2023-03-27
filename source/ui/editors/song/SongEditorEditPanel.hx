package ui.editors.song;

import data.Settings;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.StrNameLabel;
import states.editors.SongEditorState;
import ui.editors.EditorCheckbox;
import ui.editors.EditorDropdownMenu;
import ui.editors.EditorInputText;
import ui.editors.EditorNumericStepper;
import ui.editors.EditorPanel;
import ui.editors.EditorText;
import ui.editors.song.SongEditorWaveform.WaveformType;
import util.editors.actions.song.ActionChangeArtist;
import util.editors.actions.song.ActionChangeDifficultyName;
import util.editors.actions.song.ActionChangeSource;
import util.editors.actions.song.ActionChangeTitle;
import util.editors.actions.song.SongEditorActionManager;

class SongEditorEditPanel extends EditorPanel
{
	var state:SongEditorState;
	var titleInput:EditorInputText;
	var artistInput:EditorInputText;
	var sourceInput:EditorInputText;
	var difficultyInput:EditorInputText;
	var speedStepper:EditorNumericStepper;
	var rateStepper:EditorNumericStepper;
	var beatSnapDropdown:EditorDropdownMenu;

	public function new(state:SongEditorState)
	{
		super([
			{
				name: 'Editor',
				label: 'Editor'
			},
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

		createEditorTab();
		createSongTab();

		selected_tab_id = 'Song';

		state.actionManager.onEvent.add(onEvent);
	}

	public function updateSpeedStepper()
	{
		speedStepper.changeWithoutTrigger(Settings.editorScrollSpeed.value);
	}

	public function updateRateStepper()
	{
		rateStepper.changeWithoutTrigger(state.inst.pitch);
	}

	public function updateBeatSnapDropdown()
	{
		beatSnapDropdown.selectedId = Std.string(state.beatSnap.value);
	}

	function createSongTab()
	{
		var tab = createTab('Song');

		var spacing = 4;
		var inputSpacing = 125;
		var inputWidth = 250;

		var titleLabel = new EditorText(4, 5, 0, 'Title:');
		tab.add(titleLabel);

		titleInput = new EditorInputText(titleLabel.x + inputSpacing, 4, inputWidth, state.song.title);
		titleInput.textChanged.add(function(text, lastText)
		{
			if (text.length == 0)
				titleInput.text = text = 'Untitled Song';

			state.actionManager.perform(new ActionChangeTitle(state, text, lastText));
		});
		tab.add(titleInput);

		var artistLabel = new EditorText(titleLabel.x, titleLabel.y + titleLabel.height + spacing, 0, 'Artist:');
		tab.add(artistLabel);

		artistInput = new EditorInputText(artistLabel.x + inputSpacing, artistLabel.y - 1, inputWidth, state.song.artist);
		artistInput.textChanged.add(function(text, lastText)
		{
			if (text.length == 0)
				artistInput.text = text = 'Unknown Artist';

			state.actionManager.perform(new ActionChangeArtist(state, text, lastText));
		});
		tab.add(artistInput);

		var sourceLabel = new EditorText(artistLabel.x, artistLabel.y + artistLabel.height + spacing, 0, 'Source:');
		tab.add(sourceLabel);

		sourceInput = new EditorInputText(sourceLabel.x + inputSpacing, sourceLabel.y - 1, inputWidth, state.song.source);
		sourceInput.textChanged.add(function(text, lastText)
		{
			if (text.length == 0)
				sourceInput.text = text = 'Unknown Source';

			state.actionManager.perform(new ActionChangeSource(state, text, lastText));
		});
		tab.add(sourceInput);

		var difficultyLabel = new EditorText(sourceLabel.x, sourceLabel.y + sourceLabel.height + spacing, 0, 'Difficulty Name:');
		tab.add(difficultyLabel);

		difficultyInput = new EditorInputText(difficultyLabel.x + inputSpacing, difficultyLabel.y - 1, inputWidth, state.song.difficultyName);
		difficultyInput.textChanged.add(function(text, lastText)
		{
			if (text.length == 0)
			{
				state.notificationManager.showNotification("You can't have an empty difficulty name!", WARNING);
				difficultyInput.text = lastText;
				return;
			}

			state.actionManager.perform(new ActionChangeDifficultyName(state, text, lastText));
		});
		tab.add(difficultyInput);

		var opponentLabel = new EditorText(difficultyLabel.x, difficultyLabel.y + difficultyLabel.height + spacing, 0, 'P1/Opponent Character:');
		tab.add(opponentLabel);

		var opponentInput = new EditorInputText(opponentLabel.x + inputSpacing, opponentLabel.y - 1, inputWidth, state.song.opponent);
		opponentInput.focusLost.add(function(text)
		{
			state.song.opponent = text;
		});
		tab.add(opponentInput);

		var bfLabel = new EditorText(opponentLabel.x, opponentLabel.y + opponentLabel.height + spacing, 0, 'P2/Boyfriend Character:');
		tab.add(bfLabel);

		var bfInput = new EditorInputText(bfLabel.x + inputSpacing, bfLabel.y - 1, inputWidth, state.song.bf);
		bfInput.focusLost.add(function(text)
		{
			state.song.bf = text;
		});
		tab.add(bfInput);

		var gfLabel = new EditorText(bfLabel.x, bfLabel.y + bfLabel.height + spacing, 0, 'Girlfriend Character:');
		tab.add(gfLabel);

		var gfInput = new EditorInputText(gfLabel.x + inputSpacing, gfLabel.y - 1, inputWidth, state.song.gf);
		gfInput.focusLost.add(function(text)
		{
			state.song.gf = text;
		});
		tab.add(gfInput);

		var velocityLabel = new EditorText(gfLabel.x, gfLabel.y + gfLabel.height + spacing, 0, 'Initial Scroll Velocity:');
		tab.add(velocityLabel);

		var velocityStepper = new EditorNumericStepper(velocityLabel.x + inputSpacing, velocityLabel.y - 1, 0.1, 1, 0, 10, 2);
		velocityStepper.value = state.song.initialScrollVelocity;
		velocityStepper.valueChanged.add(function(value, _)
		{
			state.song.initialScrollVelocity = value;
		});
		tab.add(velocityStepper);

		var saveButton = new FlxUIButton(0, velocityStepper.y + velocityStepper.height + 20, 'Save', function()
		{
			state.save();
		});
		saveButton.x = (width - saveButton.width) / 2;
		tab.add(saveButton);

		addGroup(tab);
	}

	function createEditorTab()
	{
		var tab = createTab('Editor');

		var spacing = 4;
		var inputSpacing = 100;

		var speedLabel = new EditorText(4, 5, 0, 'Scroll Speed:');
		tab.add(speedLabel);

		speedStepper = new EditorNumericStepper(speedLabel.x + inputSpacing, speedLabel.y - 1, 0.05, Settings.editorScrollSpeed.defaultValue,
			Settings.editorScrollSpeed.minValue, Settings.editorScrollSpeed.maxValue, 2);
		speedStepper.value = Settings.editorScrollSpeed.value;
		speedStepper.valueChanged.add(function(value, _)
		{
			Settings.editorScrollSpeed.value = value;
		});
		tab.add(speedStepper);

		var rateLabel = new EditorText(speedLabel.x, speedLabel.y + speedLabel.height + spacing, 0, 'Playback Rate:');
		tab.add(rateLabel);

		rateStepper = new EditorNumericStepper(rateLabel.x + inputSpacing, rateLabel.y - 1, 0.25, 1, 0.25, 2, 2);
		rateStepper.value = state.inst.pitch;
		rateStepper.valueChanged.add(function(value, _)
		{
			state.setPlaybackRate(value);
		});
		tab.add(rateStepper);
		state.tooltip.addTooltip(rateStepper, 'Hotkeys: CTRL + -/+');

		var scaleSpeedCheckbox = new EditorCheckbox(rateLabel.x, rateLabel.y + rateLabel.height + spacing, 'Scale Speed with Playback Rate', 0);
		scaleSpeedCheckbox.button.setAllLabelOffsets(0, 8);
		scaleSpeedCheckbox.checked = Settings.editorScaleSpeedWithRate.value;
		scaleSpeedCheckbox.callback = function()
		{
			Settings.editorScaleSpeedWithRate.value = scaleSpeedCheckbox.checked;
		};
		tab.add(scaleSpeedCheckbox);

		var longNoteAlphaLabel = new EditorText(scaleSpeedCheckbox.x, scaleSpeedCheckbox.y + scaleSpeedCheckbox.height + spacing, 0, 'Long Note Opacity:');
		tab.add(longNoteAlphaLabel);

		var longNoteAlphaStepper = new EditorNumericStepper(longNoteAlphaLabel.x + inputSpacing, longNoteAlphaLabel.y - 1, 10,
			Settings.editorLongNoteAlpha.defaultValue * 100, Settings.editorLongNoteAlpha.minValue * 100, Settings.editorLongNoteAlpha.maxValue * 100);
		longNoteAlphaStepper.value = Settings.editorLongNoteAlpha.value * 100;
		longNoteAlphaStepper.valueChanged.add(function(value, _)
		{
			Settings.editorLongNoteAlpha.value = value / 100;
		});
		tab.add(longNoteAlphaStepper);

		var hitsoundLabel = new EditorText(longNoteAlphaLabel.x, longNoteAlphaLabel.y + longNoteAlphaLabel.height + spacing, 0, 'Hitsound Volume:');
		tab.add(hitsoundLabel);

		var hitsoundStepper = new EditorNumericStepper(hitsoundLabel.x + inputSpacing, hitsoundLabel.y - 1, 10,
			Settings.editorHitsoundVolume.defaultValue * 100, Settings.editorHitsoundVolume.minValue * 100, Settings.editorHitsoundVolume.maxValue * 100);
		hitsoundStepper.value = Settings.editorHitsoundVolume.value * 100;
		hitsoundStepper.valueChanged.add(function(value, _)
		{
			Settings.editorHitsoundVolume.value = value / 100;
		});
		tab.add(hitsoundStepper);

		var beatSnapLabel = new EditorText(hitsoundLabel.x, hitsoundLabel.y + hitsoundLabel.height + spacing + 3, 0, 'Beat Snap:');
		tab.add(beatSnapLabel);

		var beatSnaps = [
			for (snap in state.availableBeatSnaps)
				new StrNameLabel(Std.string(snap), '1/${CoolUtil.formatOrdinal(snap)}')
		];
		beatSnapDropdown = new EditorDropdownMenu(beatSnapLabel.x + inputSpacing, beatSnapLabel.y - 4, beatSnaps, function(id)
		{
			state.beatSnap.value = Std.parseInt(id);
		}, this);
		beatSnapDropdown.selectedId = Std.string(state.beatSnap.value);
		state.tooltip.addTooltip(beatSnapDropdown, 'Hotkeys: CTRL + Up/Down/Mouse Wheel');
		state.dropdowns.push(beatSnapDropdown);

		var liveMappingCheckbox = new EditorCheckbox(beatSnapLabel.x, beatSnapLabel.y + beatSnapLabel.height + spacing, 'Live Mapping', 200);
		liveMappingCheckbox.checked = Settings.editorLiveMapping.value;
		liveMappingCheckbox.callback = function()
		{
			Settings.editorLiveMapping.value = liveMappingCheckbox.checked;
		};
		tab.add(liveMappingCheckbox);

		var waveformLabel = new EditorText(liveMappingCheckbox.x, liveMappingCheckbox.y + liveMappingCheckbox.height + spacing + 2, 0, 'Waveform:');
		tab.add(waveformLabel);

		var waveformTypes = [WaveformType.NONE, WaveformType.INST, WaveformType.VOCALS];
		var waveformDropdown = new EditorDropdownMenu(waveformLabel.x + inputSpacing, waveformLabel.y - 4,
			EditorDropdownMenu.makeStrIdLabelArray(waveformTypes), function(id)
		{
			state.waveform.type = id;
			state.waveform.reloadWaveform();
		}, this);
		waveformDropdown.selectedId = state.waveform.type;
		state.dropdowns.push(waveformDropdown);

		tab.add(waveformDropdown);
		tab.add(beatSnapDropdown);

		addGroup(tab);
	}

	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.CHANGE_TITLE:
				titleInput.text = params.title;
			case SongEditorActionManager.CHANGE_ARTIST:
				artistInput.text = params.artist;
			case SongEditorActionManager.CHANGE_SOURCE:
				sourceInput.text = params.source;
			case SongEditorActionManager.CHANGE_DIFFICULTY_NAME:
				difficultyInput.text = params.difficultyName;
		}
	}
}
