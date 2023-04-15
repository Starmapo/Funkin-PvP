package ui.editors.song;

import data.Settings;
import data.song.ITimingObject;
import data.song.NoteInfo;
import flixel.FlxG;
import flixel.FlxSprite;
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
import util.editors.actions.song.SongEditorActionManager;

class SongEditorEditPanel extends EditorPanel
{
	var state:SongEditorState;
	var titleInput:EditorInputText;
	var artistInput:EditorInputText;
	var sourceInput:EditorInputText;
	var difficultyInput:EditorInputText;
	var opponentInput:EditorInputText;
	var bfInput:EditorInputText;
	var gfInput:EditorInputText;
	var velocityStepper:EditorNumericStepper;
	var speedStepper:EditorNumericStepper;
	var rateStepper:EditorNumericStepper;
	var beatSnapDropdown:EditorDropdownMenu;
	var waveformDropdown:EditorDropdownMenu;
	var instVolumeStepper:EditorNumericStepper;
	var vocalsVolumeStepper:EditorNumericStepper;
	var typeInput:EditorInputText;
	var paramsInput:EditorInputText;
	var selectedNotes:Array<NoteInfo> = [];
	var notePropertiesGroup:Array<FlxSprite> = [];

	public function new(state:SongEditorState)
	{
		super([
			{
				name: 'Editor',
				label: 'Editor'
			},
			{
				name: 'Notes',
				label: 'Notes'
			},
			{
				name: 'Song',
				label: 'Song'
			}
		]);
		resize(390, 500);
		x = FlxG.width - width - 10;
		screenCenter(Y);
		this.state = state;

		createEditorTab();
		createNotesTab();
		createSongTab();

		selected_tab_id = 'Song';
		updateSelectedNotes();
		onClick = onClickTab;

		state.actionManager.onEvent.add(onEvent);
		state.selectedObjects.itemAdded.add(onSelectedObject);
		state.selectedObjects.itemRemoved.add(onDeselectedObject);
		state.selectedObjects.multipleItemsAdded.add(onMultipleObjectsSelected);
		state.selectedObjects.arrayCleared.add(onAllObjectsDeselected);
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

		opponentInput = new EditorInputText(opponentLabel.x + inputSpacing, opponentLabel.y - 1, inputWidth, state.song.opponent);
		opponentInput.textChanged.add(function(text, lastText)
		{
			if (text.length == 0)
			{
				state.notificationManager.showNotification("You can't have an empty character name!", WARNING);
				opponentInput.text = lastText;
				return;
			}

			state.actionManager.perform(new ActionChangeOpponent(state, text, lastText));
		});
		tab.add(opponentInput);

		var bfLabel = new EditorText(opponentLabel.x, opponentLabel.y + opponentLabel.height + spacing, 0, 'P2/Boyfriend Character:');
		tab.add(bfLabel);

		bfInput = new EditorInputText(bfLabel.x + inputSpacing, bfLabel.y - 1, inputWidth, state.song.bf);
		bfInput.textChanged.add(function(text, lastText)
		{
			if (text.length == 0)
			{
				state.notificationManager.showNotification("You can't have an empty character name!", WARNING);
				bfInput.text = lastText;
				return;
			}

			state.actionManager.perform(new ActionChangeBF(state, text, lastText));
		});
		tab.add(bfInput);

		var gfLabel = new EditorText(bfLabel.x, bfLabel.y + bfLabel.height + spacing, 0, 'Girlfriend Character:');
		tab.add(gfLabel);

		gfInput = new EditorInputText(gfLabel.x + inputSpacing, gfLabel.y - 1, inputWidth, state.song.gf);
		gfInput.textChanged.add(function(text, lastText)
		{
			if (text.length == 0)
			{
				state.notificationManager.showNotification("You can't have an empty character name!", WARNING);
				gfInput.text = lastText;
				return;
			}

			state.actionManager.perform(new ActionChangeGF(state, text, lastText));
		});
		tab.add(gfInput);

		var velocityLabel = new EditorText(gfLabel.x, gfLabel.y + gfLabel.height + spacing, 0, 'Initial Scroll Velocity:');
		tab.add(velocityLabel);

		velocityStepper = new EditorNumericStepper(velocityLabel.x + inputSpacing, velocityLabel.y - 1, 0.1, 1, 0, 10, 2);
		velocityStepper.value = state.song.initialScrollVelocity;
		velocityStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeInitialSV(state, value, lastValue));
		});
		tab.add(velocityStepper);

		var saveButton = new FlxUIButton(0, velocityStepper.y + velocityStepper.height + spacing, 'Save', function()
		{
			state.save();
		});
		saveButton.x = (width - saveButton.width) / 2;
		tab.add(saveButton);
		state.tooltip.addTooltip(saveButton, 'Hotkey: CTRL + S');

		var applyOffsetButton = new FlxUIButton(0, saveButton.y + saveButton.height + spacing, 'Apply Offset to Song', function()
		{
			state.openApplyOffsetPrompt();
		});
		applyOffsetButton.resize(120, applyOffsetButton.height);
		applyOffsetButton.x = (width - applyOffsetButton.width) / 2;
		tab.add(applyOffsetButton);

		addGroup(tab);
	}

	function createEditorTab()
	{
		var tab = createTab('Editor');

		var spacing = 4;
		var inputSpacing = 125;

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

		var opponentHitsoundsCheckbox = new EditorCheckbox(hitsoundStepper.x + hitsoundStepper.width + spacing, hitsoundStepper.y - 10, 'Opponent Hitsounds');
		// opponentHitsoundsCheckbox.button.setAllLabelOffsets(0, -2);
		opponentHitsoundsCheckbox.checked = Settings.editorOpponentHitsounds.value;
		opponentHitsoundsCheckbox.callback = function()
		{
			Settings.editorOpponentHitsounds.value = opponentHitsoundsCheckbox.checked;
		};
		tab.add(opponentHitsoundsCheckbox);

		var bfHitsoundsCheckbox = new EditorCheckbox(opponentHitsoundsCheckbox.x + 80 + spacing, opponentHitsoundsCheckbox.y, 'BF Hitsounds');
		bfHitsoundsCheckbox.button.setAllLabelOffsets(0, -2);
		bfHitsoundsCheckbox.checked = Settings.editorBFHitsounds.value;
		bfHitsoundsCheckbox.callback = function()
		{
			Settings.editorBFHitsounds.value = bfHitsoundsCheckbox.checked;
		};
		tab.add(bfHitsoundsCheckbox);

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
		liveMappingCheckbox.button.setAllLabelOffsets(0, -2);
		liveMappingCheckbox.checked = Settings.editorLiveMapping.value;
		liveMappingCheckbox.callback = function()
		{
			Settings.editorLiveMapping.value = liveMappingCheckbox.checked;
		};
		tab.add(liveMappingCheckbox);

		var waveformLabel = new EditorText(liveMappingCheckbox.x, liveMappingCheckbox.y + liveMappingCheckbox.height + spacing + 2, 0, 'Waveform:');
		tab.add(waveformLabel);

		var waveformTypes = [WaveformType.NONE, WaveformType.INST, WaveformType.VOCALS];
		waveformDropdown = new EditorDropdownMenu(waveformLabel.x + inputSpacing, waveformLabel.y - 4, EditorDropdownMenu.makeStrIdLabelArray(waveformTypes),
			function(id)
			{
				if (state.playfieldNotes.waveform.type != id)
				{
					state.inst.pause();
					state.vocals.pause();
					state.playfieldNotes.waveform.type = id;
					state.playfieldNotes.waveform.reloadWaveform();
				}
			}, this);
		waveformDropdown.selectedId = state.playfieldNotes.waveform.type;
		state.dropdowns.push(waveformDropdown);

		var placeOnNearestTickCheckbox = new EditorCheckbox(waveformLabel.x, waveformLabel.y + waveformLabel.height + spacing, 'Place on Nearest Tick', 0);
		placeOnNearestTickCheckbox.button.setAllLabelOffsets(0, 4);
		placeOnNearestTickCheckbox.checked = Settings.editorPlaceOnNearestTick.value;
		placeOnNearestTickCheckbox.callback = function()
		{
			Settings.editorPlaceOnNearestTick.value = placeOnNearestTickCheckbox.checked;
		};
		tab.add(placeOnNearestTickCheckbox);

		var instVolumeLabel = new EditorText(placeOnNearestTickCheckbox.x, placeOnNearestTickCheckbox.y + placeOnNearestTickCheckbox.height + spacing, 0,
			'Instrumental Volume:');
		tab.add(instVolumeLabel);

		instVolumeStepper = new EditorNumericStepper(instVolumeLabel.x + inputSpacing, instVolumeLabel.y - 1, 10,
			Settings.editorInstVolume.defaultValue * 100, Settings.editorInstVolume.minValue * 100, Settings.editorInstVolume.maxValue * 100);
		instVolumeStepper.value = Settings.editorInstVolume.value * 100;
		instVolumeStepper.valueChanged.add(function(value, _)
		{
			state.inst.volume = value / 100;
		});
		tab.add(instVolumeStepper);

		var vocalsVolumeLabel = new EditorText(instVolumeLabel.x, instVolumeLabel.y + instVolumeLabel.height + spacing, 0, 'Vocals Volume:');
		tab.add(vocalsVolumeLabel);

		vocalsVolumeStepper = new EditorNumericStepper(vocalsVolumeLabel.x + inputSpacing, vocalsVolumeLabel.y - 1, 10,
			Settings.editorVocalsVolume.defaultValue * 100, Settings.editorVocalsVolume.minValue * 100, Settings.editorVocalsVolume.maxValue * 100);
		vocalsVolumeStepper.value = Settings.editorVocalsVolume.value * 100;
		vocalsVolumeStepper.valueChanged.add(function(value, _)
		{
			state.vocals.volume = value / 100;
		});
		tab.add(vocalsVolumeStepper);

		var saveOnExitCheckbox = new EditorCheckbox(vocalsVolumeLabel.x, vocalsVolumeLabel.y + vocalsVolumeLabel.height + spacing, 'Save on Exit', 0);
		saveOnExitCheckbox.checked = Settings.editorSaveOnExit.value;
		saveOnExitCheckbox.callback = function()
		{
			Settings.editorSaveOnExit.value = saveOnExitCheckbox.checked;
		};
		tab.add(saveOnExitCheckbox);

		tab.add(waveformDropdown);
		tab.add(beatSnapDropdown);

		addGroup(tab);
	}

	function createNotesTab()
	{
		var tab = createTab('Notes');

		var spacing = 4;
		var inputWidth = width - 10;

		var typeLabel = new EditorText(4, 4, 0, 'Type:');
		tab.add(typeLabel);
		notePropertiesGroup.push(typeLabel);

		typeInput = new EditorInputText(typeLabel.x, typeLabel.y + typeLabel.height + spacing, inputWidth);
		typeInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeNoteType(state, selectedNotes.copy(), text));
		});
		tab.add(typeInput);
		notePropertiesGroup.push(typeInput);

		var paramsLabel = new EditorText(typeInput.x, typeInput.y + typeInput.height + spacing, 0, 'Extra parameters:');
		tab.add(paramsLabel);
		notePropertiesGroup.push(paramsLabel);

		paramsInput = new EditorInputText(paramsLabel.x, paramsLabel.y + paramsLabel.height + spacing, inputWidth);
		paramsInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeNoteParams(state, selectedNotes.copy(), text));
		});
		tab.add(paramsInput);
		notePropertiesGroup.push(paramsInput);

		var resnapAllToCurrentButton = new FlxUIButton(0, paramsInput.y + paramsInput.height + spacing, 'Resnap all notes to currently selected snap',
			function()
			{
				if (state.song.notes.length > 0)
					state.actionManager.perform(new ActionResnapObjects(state, [state.beatSnap.value], cast state.song.notes.copy()));
			});
		resnapAllToCurrentButton.resize(230, resnapAllToCurrentButton.height);
		resnapAllToCurrentButton.x = (width - resnapAllToCurrentButton.width) / 2;
		tab.add(resnapAllToCurrentButton);

		var resnapAllToDefaultButton = new FlxUIButton(0, resnapAllToCurrentButton.y + resnapAllToCurrentButton.height + spacing,
			'Resnap all notes to 1/16 and 1/12 snaps', function()
		{
			if (state.song.notes.length > 0)
				state.actionManager.perform(new ActionResnapObjects(state, [16, 12], cast state.song.notes.copy()));
		});
		resnapAllToDefaultButton.resize(200, resnapAllToDefaultButton.height);
		resnapAllToDefaultButton.x = (width - resnapAllToDefaultButton.width) / 2;
		tab.add(resnapAllToDefaultButton);

		var resnapSelectedToCurrentButton = new FlxUIButton(0, resnapAllToDefaultButton.y + resnapAllToDefaultButton.height + spacing,
			'Resnap selected notes to currently selected snap', function()
		{
			var selectedNotes:Array<ITimingObject> = [];
			for (obj in state.selectedObjects.value)
			{
				if (Std.isOfType(obj, NoteInfo))
					selectedNotes.push(obj);
			}
			if (selectedNotes.length > 0)
				state.actionManager.perform(new ActionResnapObjects(state, [state.beatSnap.value], selectedNotes));
		});
		resnapSelectedToCurrentButton.resize(250, resnapSelectedToCurrentButton.height);
		resnapSelectedToCurrentButton.x = (width - resnapSelectedToCurrentButton.width) / 2;
		tab.add(resnapSelectedToCurrentButton);

		var resnapSelectedToDefaultButton = new FlxUIButton(0, resnapSelectedToCurrentButton.y + resnapSelectedToCurrentButton.height + spacing,
			'Resnap selected notes to 1/16 and 1/12 snaps', function()
		{
			var selectedNotes:Array<ITimingObject> = [];
			for (obj in state.selectedObjects.value)
			{
				if (Std.isOfType(obj, NoteInfo))
					selectedNotes.push(obj);
			}
			if (selectedNotes.length > 0)
				state.actionManager.perform(new ActionResnapObjects(state, [16, 12], selectedNotes));
		});
		resnapSelectedToDefaultButton.resize(230, resnapSelectedToDefaultButton.height);
		resnapSelectedToDefaultButton.x = (width - resnapSelectedToDefaultButton.width) / 2;
		tab.add(resnapSelectedToDefaultButton);

		addGroup(tab);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var hideSteppers = beatSnapDropdown.dropPanel.visible || waveformDropdown.dropPanel.visible;
		vocalsVolumeStepper.alpha = instVolumeStepper.alpha = hideSteppers ? 0 : 1;
	}

	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.CHANGE_NOTE_TYPE, SongEditorActionManager.CHANGE_NOTE_PARAMS:
				updateSelectedNotes();
			case SongEditorActionManager.CHANGE_TITLE:
				titleInput.text = params.title;
			case SongEditorActionManager.CHANGE_ARTIST:
				artistInput.text = params.artist;
			case SongEditorActionManager.CHANGE_SOURCE:
				sourceInput.text = params.source;
			case SongEditorActionManager.CHANGE_DIFFICULTY_NAME:
				difficultyInput.text = params.difficultyName;
			case SongEditorActionManager.CHANGE_OPPONENT:
				opponentInput.text = params.opponent;
			case SongEditorActionManager.CHANGE_BF:
				bfInput.text = params.bf;
			case SongEditorActionManager.CHANGE_GF:
				gfInput.text = params.gf;
			case SongEditorActionManager.CHANGE_INITIAL_SV:
				velocityStepper.changeWithoutTrigger(params.initialScrollVelocity);
		}
	}

	function onSelectedObject(obj:ITimingObject)
	{
		if (Std.isOfType(obj, NoteInfo))
		{
			selectedNotes.push(cast obj);
			updateSelectedNotes();
		}
	}

	function onDeselectedObject(obj:ITimingObject)
	{
		if (Std.isOfType(obj, NoteInfo))
		{
			selectedNotes.remove(cast obj);
			updateSelectedNotes();
		}
	}

	function onMultipleObjectsSelected(objects:Array<ITimingObject>)
	{
		var foundNote = false;
		for (obj in objects)
		{
			if (Std.isOfType(obj, NoteInfo))
			{
				selectedNotes.push(cast obj);
				foundNote = true;
			}
		}
		if (foundNote)
			updateSelectedNotes();
	}

	function onAllObjectsDeselected()
	{
		selectedNotes.resize(0);
		updateSelectedNotes();
	}

	function updateSelectedNotes()
	{
		if (selectedNotes.length > 0)
		{
			var type = selectedNotes[0].type;
			var params = selectedNotes[0].params.join(',');
			for (i in 1...selectedNotes.length)
			{
				if (selectedNotes[i].type != type)
					type = '...';

				if (selectedNotes[i].params.join(',') != params)
					params = '...';

				if (type == '...' && params == '...')
					break;
			}
			typeInput.text = type;
			paramsInput.text = params;
			for (obj in notePropertiesGroup)
			{
				if (selected_tab_id == 'Notes')
					obj.active = true;
				obj.alpha = 1;
			}
		}
		else
		{
			paramsInput.text = typeInput.text = '';
			for (obj in notePropertiesGroup)
			{
				obj.active = false;
				obj.alpha = 0.5;
			}
		}
	}

	function onClickTab(name:String)
	{
		if (selectedNotes.length == 0)
			updateSelectedNotes();
	}
}
