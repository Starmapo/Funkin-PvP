package ui.editors.song;

import data.Settings;
import data.song.CameraFocus;
import data.song.EventObject;
import data.song.ITimingObject;
import data.song.LyricStep;
import data.song.NoteInfo;
import data.song.ScrollVelocity;
import data.song.Song;
import data.song.TimingPoint;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.StrNameLabel;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.io.Path;
import states.editors.SongEditorState;
import subStates.PromptInputSubState;
import subStates.PromptSubState.YesNoPrompt;
import subStates.editors.song.SongEditorApplyOffsetPrompt;
import subStates.editors.song.SongEditorNewChartPrompt;
import subStates.editors.song.SongEditorNewSongPrompt;
import subStates.editors.song.SongEditorSelectNoteTypePrompt;
import systools.Dialogs;
import ui.editors.EditorCheckbox;
import ui.editors.EditorDropdownMenu;
import ui.editors.EditorInputText;
import ui.editors.EditorNumericStepper;
import ui.editors.EditorPanel;
import ui.editors.EditorText;
import ui.editors.song.SongEditorWaveform.WaveformType;
import util.editors.song.SongEditorActionManager;

using StringTools;

class SongEditorEditPanel extends EditorPanel
{
	public var eventInput:EditorInputText;
	public var eventParamsInput:EditorInputText;
	
	var state:SongEditorState;
	var spacing:Int = 4;
	var titleInput:EditorInputText;
	var artistInput:EditorInputText;
	var sourceInput:EditorInputText;
	var difficultyInput:EditorInputText;
	var opponentInput:EditorInputText;
	var bfInput:EditorInputText;
	var gfInput:EditorInputText;
	var stageInput:EditorInputText;
	var velocityStepper:EditorNumericStepper;
	var speedStepper:EditorNumericStepper;
	var rateStepper:EditorNumericStepper;
	var beatSnapDropdown:EditorDropdownMenu;
	var waveformDropdown:EditorDropdownMenu;
	var instVolumeStepper:EditorNumericStepper;
	var vocalsVolumeStepper:EditorNumericStepper;
	var typeInput:EditorInputText;
	var noteParamsInput:EditorInputText;
	var selectedNotes:Array<NoteInfo> = [];
	var notePropertiesGroup:Array<FlxSprite> = [];
	var timingPointTimeStepper:EditorNumericStepper;
	var bpmStepper:EditorNumericStepper;
	var meterStepper:EditorNumericStepper;
	var selectedTimingPoints:Array<TimingPoint> = [];
	var timingPointPropertiesGroup:Array<FlxSprite> = [];
	var multiplierStepper1:EditorNumericStepper;
	var multiplierStepper2:EditorNumericStepper;
	var linkedCheckbox:EditorCheckbox;
	var selectedScrollVelocities:Array<ScrollVelocity> = [];
	var scrollVelocitiesPropertiesGroup:Array<FlxSprite> = [];
	var charDropdown:EditorDropdownMenu;
	var selectedCameraFocuses:Array<CameraFocus> = [];
	var cameraFocusesPropertiesGroup:Array<FlxSprite> = [];
	var eventIndexLabel:EditorText;
	var selectedEvents:Array<EventObject> = [];
	var eventsPropertiesGroup:Array<FlxSprite> = [];
	var eventIndex:Int = 0;
	var lastEvent:EventObject = null;
	var lyricsInput:EditorInputText;
	var selectAllNoteTypePrompt:SongEditorSelectNoteTypePrompt;
	var selectP1NoteTypePrompt:SongEditorSelectNoteTypePrompt;
	var selectP2NoteTypePrompt:SongEditorSelectNoteTypePrompt;
	var applyOffsetPrompt:SongEditorApplyOffsetPrompt;
	var pasteMetadataPrompt:YesNoPrompt;
	var pasteCharactersPrompt:YesNoPrompt;
	var pasteTimingPointsPrompt:YesNoPrompt;
	var pasteScrollVelocitiesPrompt:YesNoPrompt;
	var pasteCameraFocusesPrompt:YesNoPrompt;
	var pasteEventsPrompt:YesNoPrompt;
	var pasteLyricStepsPrompt:YesNoPrompt;
	var newChartPrompt:SongEditorNewChartPrompt;
	var newSongPrompt:SongEditorNewSongPrompt;
	var selectEventPrompt:PromptInputSubState;
	
	public function new(state:SongEditorState)
	{
		super([
			{
				name: 'Camera Focuses',
				label: 'Camera Focuses'
			},
			{
				name: 'Editor',
				label: 'Editor'
			},
			{
				name: 'Events',
				label: 'Events'
			},
			/*
				{
					name: 'Extra',
					label: 'Extra'
				},
			 */
			{
				name: 'Lyrics',
				label: 'Lyrics'
			},
			{
				name: 'Notes',
				label: 'Notes'
			},
			{
				name: 'Scroll Velocities',
				label: 'Scroll Velocities'
			},
			{
				name: 'Song',
				label: 'Song'
			},
			{
				name: 'Timing Points',
				label: 'Timing Points'
			}
		], 3);
		resize(390, 530);
		x = FlxG.width - width - 10;
		screenCenter(Y);
		this.state = state;
		
		createCameraFocusesTab();
		createEditorTab();
		createEventsTab();
		createExtraTab();
		createLyricsTab();
		createNotesTab();
		createScrollVelocitiesTab();
		createSongTab();
		createTimingPointsTab();
		
		selected_tab_id = 'Song';
		updateSelectedCameraFocuses();
		updateSelectedEvents();
		updateSelectedNotes();
		updateSelectedScrollVelocities();
		updateSelectedTimingPoints();
		onClick = onClickTab;
		
		state.actionManager.onEvent.add(onEvent);
		state.selectedObjects.itemAdded.add(onSelectedObject);
		state.selectedObjects.itemRemoved.add(onDeselectedObject);
		state.selectedObjects.multipleItemsAdded.add(onMultipleObjectsSelected);
		state.selectedObjects.arrayCleared.add(onAllObjectsDeselected);
	}
	
	public function updateSpeedStepper()
	{
		speedStepper.value = Settings.editorScrollSpeed.value;
	}
	
	public function updateRateStepper()
	{
		rateStepper.value = state.inst.pitch;
	}
	
	public function updateBeatSnapDropdown()
	{
		beatSnapDropdown.selectedId = Std.string(state.beatSnap.value);
	}
	
	override function destroy()
	{
		super.destroy();
		state = null;
		titleInput = null;
		artistInput = null;
		sourceInput = null;
		difficultyInput = null;
		opponentInput = null;
		bfInput = null;
		gfInput = null;
		stageInput = null;
		velocityStepper = null;
		speedStepper = null;
		rateStepper = null;
		beatSnapDropdown = null;
		waveformDropdown = null;
		instVolumeStepper = null;
		vocalsVolumeStepper = null;
		typeInput = null;
		noteParamsInput = null;
		selectedNotes = null;
		notePropertiesGroup = null;
		timingPointTimeStepper = null;
		bpmStepper = null;
		meterStepper = null;
		selectedTimingPoints = null;
		timingPointPropertiesGroup = null;
		multiplierStepper1 = null;
		multiplierStepper2 = null;
		linkedCheckbox = null;
		selectedScrollVelocities = null;
		scrollVelocitiesPropertiesGroup = null;
		charDropdown = null;
		selectedCameraFocuses = null;
		cameraFocusesPropertiesGroup = null;
		eventIndexLabel = null;
		eventInput = null;
		eventParamsInput = null;
		selectedEvents = null;
		eventsPropertiesGroup = null;
		lastEvent = null;
		selectAllNoteTypePrompt = FlxDestroyUtil.destroy(selectAllNoteTypePrompt);
		selectP1NoteTypePrompt = FlxDestroyUtil.destroy(selectP1NoteTypePrompt);
		selectP2NoteTypePrompt = FlxDestroyUtil.destroy(selectP2NoteTypePrompt);
		applyOffsetPrompt = FlxDestroyUtil.destroy(applyOffsetPrompt);
		pasteMetadataPrompt = FlxDestroyUtil.destroy(pasteMetadataPrompt);
		pasteCharactersPrompt = FlxDestroyUtil.destroy(pasteCharactersPrompt);
		pasteTimingPointsPrompt = FlxDestroyUtil.destroy(pasteTimingPointsPrompt);
		pasteScrollVelocitiesPrompt = FlxDestroyUtil.destroy(pasteScrollVelocitiesPrompt);
		pasteCameraFocusesPrompt = FlxDestroyUtil.destroy(pasteCameraFocusesPrompt);
		pasteEventsPrompt = FlxDestroyUtil.destroy(pasteEventsPrompt);
		pasteLyricStepsPrompt = FlxDestroyUtil.destroy(pasteLyricStepsPrompt);
		newChartPrompt = FlxDestroyUtil.destroy(newChartPrompt);
		newSongPrompt = FlxDestroyUtil.destroy(newSongPrompt);
		selectEventPrompt = FlxDestroyUtil.destroy(selectEventPrompt);
	}
	
	function createSongTab()
	{
		applyOffsetPrompt = new SongEditorApplyOffsetPrompt(function(text)
		{
			if (text != null && text.length > 0)
			{
				var offset = Std.parseFloat(text);
				if (offset != 0 && Math.isFinite(offset))
				{
					var objects:Array<ITimingObject> = [];
					for (obj in state.song.notes)
						objects.push(obj);
					for (obj in state.song.timingPoints)
						objects.push(obj);
					for (obj in state.song.scrollVelocities)
						objects.push(obj);
					for (obj in state.song.cameraFocuses)
						objects.push(obj);
					for (obj in state.song.events)
						objects.push(obj);
					for (obj in state.song.lyricSteps)
						objects.push(obj);
					state.actionManager.perform(new ActionMoveObjects(state, objects, 0, offset));
				}
			}
		});
		pasteMetadataPrompt = new YesNoPrompt("Are you sure you want to paste this map's artist and source into all other difficulties? This action is irreversible.",
			function()
		{
			var difficulties = getDifficulties();
			for (difficulty in difficulties)
			{
				var path = Path.join([state.song.directory, difficulty + '.json']);
				var song = Song.loadSong(path);
				song.title = state.song.title;
				song.artist = state.song.artist;
				song.source = state.song.source;
				song.save(path);
			}
		});
		pasteCharactersPrompt = new YesNoPrompt("Are you sure you want to paste this map's characters and stage into all other difficulties? This action is irreversible.",
			function()
		{
			var difficulties = getDifficulties();
			for (difficulty in difficulties)
			{
				var path = Path.join([state.song.directory, difficulty + '.json']);
				var song = Song.loadSong(path);
				song.opponent = state.song.opponent;
				song.bf = state.song.bf;
				song.gf = state.song.gf;
				song.stage = state.song.stage;
				song.save(path);
			}
		});
		pasteTimingPointsPrompt = new YesNoPrompt("Are you sure you want to paste this map's timing points into all other difficulties? This action is irreversible.",
			function()
		{
			var difficulties = getDifficulties();
			for (difficulty in difficulties)
			{
				var path = Path.join([state.song.directory, difficulty + '.json']);
				var song = Song.loadSong(path);
				song.timingPoints.resize(0);
				for (obj in state.song.timingPoints)
					song.timingPoints.push(new TimingPoint({
						startTime: obj.startTime,
						bpm: obj.bpm,
						meter: obj.meter
					}));
				song.save(path);
			}
		});
		pasteScrollVelocitiesPrompt = new YesNoPrompt("Are you sure you want to paste this map's scroll velocities into all other difficulties? This action is irreversible.",
			function()
		{
			var difficulties = getDifficulties();
			for (difficulty in difficulties)
			{
				var path = Path.join([state.song.directory, difficulty + '.json']);
				var song = Song.loadSong(path);
				song.initialScrollVelocity = state.song.initialScrollVelocity;
				song.scrollVelocities.resize(0);
				for (obj in state.song.scrollVelocities)
					song.scrollVelocities.push(new ScrollVelocity({
						startTime: obj.startTime,
						multipliers: obj.multipliers.copy(),
						linked: obj.linked
					}));
				song.save(path);
			}
		});
		pasteCameraFocusesPrompt = new YesNoPrompt("Are you sure you want to paste this map's camera focuses into all other difficulties? This action is irreversible.",
			function()
		{
			var difficulties = getDifficulties();
			for (difficulty in difficulties)
			{
				var path = Path.join([state.song.directory, difficulty + '.json']);
				var song = Song.loadSong(path);
				song.cameraFocuses.resize(0);
				for (obj in state.song.cameraFocuses)
					song.cameraFocuses.push(new CameraFocus({
						startTime: obj.startTime,
						char: obj.char
					}));
				song.save(path);
			}
		});
		pasteEventsPrompt = new YesNoPrompt("Are you sure you want to paste this map's events into all other difficulties? This action is irreversible.",
			function()
			{
				var difficulties = getDifficulties();
				for (difficulty in difficulties)
				{
					var path = Path.join([state.song.directory, difficulty + '.json']);
					var song = Song.loadSong(path);
					song.events.resize(0);
					for (obj in state.song.events)
					{
						var events = [];
						for (sub in obj.events)
							events.push({
								event: sub.event,
								params: sub.params.join(',')
							});
							
						song.events.push(new EventObject({
							startTime: obj.startTime,
							events: events
						}));
					}
					song.save(path);
				}
			});
		pasteLyricStepsPrompt = new YesNoPrompt("Are you sure you want to paste this map's lyric steps into all other difficulties? This action is irreversible.",
			function()
		{
			var difficulties = getDifficulties();
			for (difficulty in difficulties)
			{
				var path = Path.join([state.song.directory, difficulty + '.json']);
				var song = Song.loadSong(path);
				song.lyricSteps.resize(0);
				for (obj in state.song.lyricSteps)
					song.lyricSteps.push(new LyricStep({
						startTime: obj.startTime
					}));
				song.save(path);
			}
		});
		newChartPrompt = new SongEditorNewChartPrompt(state);
		newSongPrompt = new SongEditorNewSongPrompt(state);
		
		var tab = createTab('Song');
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
				Main.showNotification("You can't have an empty difficulty name!", ERROR);
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
			state.actionManager.perform(new ActionChangeOpponent(state, text, lastText));
		});
		tab.add(opponentInput);
		
		var bfLabel = new EditorText(opponentLabel.x, opponentLabel.y + opponentLabel.height + spacing, 0, 'P2/Boyfriend Character:');
		tab.add(bfLabel);
		
		bfInput = new EditorInputText(bfLabel.x + inputSpacing, bfLabel.y - 1, inputWidth, state.song.bf);
		bfInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeBF(state, text, lastText));
		});
		tab.add(bfInput);
		
		var gfLabel = new EditorText(bfLabel.x, bfLabel.y + bfLabel.height + spacing, 0, 'Girlfriend Character:');
		tab.add(gfLabel);
		
		gfInput = new EditorInputText(gfLabel.x + inputSpacing, gfLabel.y - 1, inputWidth, state.song.gf);
		gfInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeGF(state, text, lastText));
		});
		tab.add(gfInput);
		
		var stageLabel = new EditorText(gfLabel.x, gfLabel.y + gfLabel.height + spacing, 0, 'Stage:');
		tab.add(stageLabel);
		
		stageInput = new EditorInputText(stageLabel.x + inputSpacing, stageLabel.y - 1, inputWidth, state.song.stage);
		stageInput.textChanged.add(function(text, lastText)
		{
			if (text.length == 0)
			{
				Main.showNotification("You can't have an empty stage name!", ERROR);
				stageInput.text = lastText;
				return;
			}
			
			state.actionManager.perform(new ActionChangeStage(state, text, lastText));
		});
		tab.add(stageInput);
		
		var velocityLabel = new EditorText(stageLabel.x, stageLabel.y + stageLabel.height + spacing, 0, 'Initial Scroll Velocity:');
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
		state.tooltip.addTooltip(saveButton, 'Hotkey: CTRL + S');
		
		var loadButton = new FlxUIButton(saveButton.x + saveButton.width + spacing, saveButton.y, 'Load', function()
		{
			var result = Dialogs.openFile("Select chart inside the game's directory to load", '', {
				count: 1,
				descriptions: ['JSON files'],
				extensions: ['*.json']
			});
			if (result == null || result[0] == null)
				return;
				
			var path = Path.normalize(result[0]);
			var cwd = Path.normalize(Sys.getCwd());
			if (!path.startsWith(cwd))
			{
				Main.showNotification("You must select a map inside of the game's directory!", ERROR);
				return;
			}
			var song = Song.loadSong(path.substr(cwd.length + 1));
			if (song == null)
			{
				Main.showNotification("You must select a valid song file!", ERROR);
				return;
			}
			
			state.save(false);
			FlxG.switchState(new SongEditorState(song));
		});
		
		saveButton.x = (width - CoolUtil.getArrayWidth([saveButton, loadButton])) / 2;
		loadButton.x = saveButton.x + saveButton.width + spacing;
		tab.add(saveButton);
		tab.add(loadButton);
		
		var newChartButton = new FlxUIButton(0, loadButton.y + loadButton.height + spacing, 'New Chart', function()
		{
			state.openSubState(newChartPrompt);
		});
		
		var newSongButton = new FlxUIButton(newChartButton.x + newChartButton.width + spacing, newChartButton.y, 'New Song', function()
		{
			state.openSubState(newSongPrompt);
		});
		
		newChartButton.x = (width - CoolUtil.getArrayWidth([newChartButton, newSongButton])) / 2;
		newSongButton.x = newChartButton.x + newChartButton.width + spacing;
		tab.add(newChartButton);
		tab.add(newSongButton);
		
		var playtestP1Button = new FlxUIButton(0, newSongButton.y + newSongButton.height + spacing, 'Playtest P1', function()
		{
			state.exitToTestPlay(0, true);
		});
		
		var playtestP2Button = new FlxUIButton(playtestP1Button.x + playtestP1Button.width + spacing, playtestP1Button.y, 'Playtest P2', function()
		{
			state.exitToTestPlay(1, true);
		});
		
		playtestP1Button.x = (width - CoolUtil.getArrayWidth([playtestP1Button, playtestP2Button])) / 2;
		playtestP2Button.x = playtestP1Button.x + playtestP1Button.width + spacing;
		tab.add(playtestP1Button);
		tab.add(playtestP2Button);
		
		var applyOffsetButton = new FlxUIButton(0, playtestP2Button.y + playtestP2Button.height + spacing, 'Apply Offset to Song', function()
		{
			state.openSubState(applyOffsetPrompt);
		});
		applyOffsetButton.resize(120, applyOffsetButton.height);
		applyOffsetButton.x = (width - applyOffsetButton.width) / 2;
		tab.add(applyOffsetButton);
		
		var pasteMetadataButton = new FlxUIButton(0, applyOffsetButton.y + applyOffsetButton.height + spacing, 'Paste metadata into all difficulties',
			function()
			{
				state.openSubState(pasteMetadataPrompt);
			});
		pasteMetadataButton.resize(190, pasteMetadataButton.height);
		pasteMetadataButton.x = (width - pasteMetadataButton.width) / 2;
		tab.add(pasteMetadataButton);
		
		var pasteCharactersButton = new FlxUIButton(0, pasteMetadataButton.y + pasteMetadataButton.height + spacing,
			'Paste characters & stage into all difficulties', function()
		{
			state.openSubState(pasteCharactersPrompt);
		});
		pasteCharactersButton.resize(220, pasteCharactersButton.height);
		pasteCharactersButton.x = (width - pasteCharactersButton.width) / 2;
		tab.add(pasteCharactersButton);
		
		var pasteTimingPointsButton = new FlxUIButton(0, pasteCharactersButton.y + pasteCharactersButton.height + spacing,
			'Paste timing points into all difficulties', function()
		{
			state.openSubState(pasteTimingPointsPrompt);
		});
		pasteTimingPointsButton.resize(200, pasteTimingPointsButton.height);
		pasteTimingPointsButton.x = (width - pasteTimingPointsButton.width) / 2;
		tab.add(pasteTimingPointsButton);
		
		var pasteScrollVelocitiesButton = new FlxUIButton(0, pasteTimingPointsButton.y + pasteTimingPointsButton.height + spacing,
			'Paste scroll velocities into all difficulties', function()
		{
			state.openSubState(pasteScrollVelocitiesPrompt);
		});
		pasteScrollVelocitiesButton.resize(210, pasteScrollVelocitiesButton.height);
		pasteScrollVelocitiesButton.x = (width - pasteScrollVelocitiesButton.width) / 2;
		tab.add(pasteScrollVelocitiesButton);
		
		var pasteCameraFocusesButton = new FlxUIButton(0, pasteScrollVelocitiesButton.y + pasteScrollVelocitiesButton.height + spacing,
			'Paste camera focuses into all difficulties', function()
		{
			state.openSubState(pasteCameraFocusesPrompt);
		});
		pasteCameraFocusesButton.resize(210, pasteCameraFocusesButton.height);
		pasteCameraFocusesButton.x = (width - pasteCameraFocusesButton.width) / 2;
		tab.add(pasteCameraFocusesButton);
		
		var pasteEventsButton = new FlxUIButton(0, pasteCameraFocusesButton.y + pasteCameraFocusesButton.height + spacing,
			'Paste events into all difficulties', function()
		{
			state.openSubState(pasteEventsPrompt);
		});
		pasteEventsButton.resize(180, pasteEventsButton.height);
		pasteEventsButton.x = (width - pasteEventsButton.width) / 2;
		tab.add(pasteEventsButton);
		
		var pasteLyricStepsButton = new FlxUIButton(0, pasteEventsButton.y + pasteEventsButton.height + spacing, 'Paste lyric steps into all difficulties',
			function()
			{
				state.openSubState(pasteLyricStepsPrompt);
			});
		pasteLyricStepsButton.resize(190, pasteLyricStepsButton.height);
		pasteLyricStepsButton.x = (width - pasteLyricStepsButton.width) / 2;
		tab.add(pasteLyricStepsButton);
		
		addGroup(tab);
	}
	
	function createEditorTab()
	{
		var tab = createTab('Editor');
		
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
			Settings.editorLongNoteAlpha.defaultValue * 100, Settings.editorLongNoteAlpha.minValue * 100, Settings.editorLongNoteAlpha.maxValue * 100, 0);
		longNoteAlphaStepper.value = Settings.editorLongNoteAlpha.value * 100;
		longNoteAlphaStepper.valueChanged.add(function(value, _)
		{
			Settings.editorLongNoteAlpha.value = value / 100;
		});
		tab.add(longNoteAlphaStepper);
		
		var hitsoundLabel = new EditorText(longNoteAlphaLabel.x, longNoteAlphaLabel.y + longNoteAlphaLabel.height + spacing, 0, 'Hitsound Volume:');
		tab.add(hitsoundLabel);
		
		var hitsoundStepper = new EditorNumericStepper(hitsoundLabel.x + inputSpacing, hitsoundLabel.y - 1, 10,
			Settings.editorHitsoundVolume.defaultValue * 100, Settings.editorHitsoundVolume.minValue * 100, Settings.editorHitsoundVolume.maxValue * 100, 0);
		hitsoundStepper.value = Settings.editorHitsoundVolume.value * 100;
		hitsoundStepper.valueChanged.add(function(value, _)
		{
			Settings.editorHitsoundVolume.value = value / 100;
		});
		tab.add(hitsoundStepper);
		
		var opponentHitsoundsCheckbox = new EditorCheckbox(hitsoundStepper.x + hitsoundStepper.width + spacing, hitsoundStepper.y - 10, 'Opponent Hitsounds');
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
		
		var metronomeLabel = new EditorText(hitsoundLabel.x, hitsoundLabel.y + hitsoundLabel.height + spacing + 3, 0, 'Metronome:');
		tab.add(metronomeLabel);
		
		var metronomeTypes:Array<MetronomeType> = [NONE, EVERY_BEAT, EVERY_HALF_BEAT];
		var metronomeDropdown = new EditorDropdownMenu(metronomeLabel.x + inputSpacing, metronomeLabel.y - 4,
			EditorDropdownMenu.makeStrIdLabelArray(metronomeTypes), function(id)
		{
			Settings.editorMetronome.value = id;
		}, this);
		metronomeDropdown.selectedId = Settings.editorMetronome.value;
		
		var beatSnapLabel = new EditorText(metronomeLabel.x, metronomeLabel.y + metronomeLabel.height + spacing + 3, 0, 'Beat Snap:');
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
			Settings.editorInstVolume.defaultValue * 100, Settings.editorInstVolume.minValue * 100, Settings.editorInstVolume.maxValue * 100, 0);
		instVolumeStepper.value = Settings.editorInstVolume.value * 100;
		instVolumeStepper.valueChanged.add(function(value, _)
		{
			Settings.editorInstVolume.value = state.inst.volume = value / 100;
		});
		tab.add(instVolumeStepper);
		
		var vocalsVolumeLabel = new EditorText(instVolumeLabel.x, instVolumeLabel.y + instVolumeLabel.height + spacing, 0, 'Vocals Volume:');
		tab.add(vocalsVolumeLabel);
		
		vocalsVolumeStepper = new EditorNumericStepper(vocalsVolumeLabel.x + inputSpacing, vocalsVolumeLabel.y - 1, 10,
			Settings.editorVocalsVolume.defaultValue * 100, Settings.editorVocalsVolume.minValue * 100, Settings.editorVocalsVolume.maxValue * 100, 0);
		vocalsVolumeStepper.value = Settings.editorVocalsVolume.value * 100;
		vocalsVolumeStepper.valueChanged.add(function(value, _)
		{
			Settings.editorVocalsVolume.value = state.vocals.volume = value / 100;
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
		tab.add(metronomeDropdown);
		
		addGroup(tab);
	}
	
	function createNotesTab()
	{
		selectAllNoteTypePrompt = new SongEditorSelectNoteTypePrompt(function(text)
		{
			var notes:Array<NoteInfo> = [];
			for (note in state.song.notes)
			{
				if (note.type == text)
					notes.push(note);
			}
			state.selectedObjects.clear();
			state.selectedObjects.pushMultiple(cast notes);
		});
		selectP1NoteTypePrompt = new SongEditorSelectNoteTypePrompt(function(text)
		{
			var notes:Array<NoteInfo> = [];
			for (note in state.song.notes)
			{
				if (note.type == text && note.player == 0)
					notes.push(note);
			}
			state.selectedObjects.clear();
			state.selectedObjects.pushMultiple(cast notes);
		});
		selectP2NoteTypePrompt = new SongEditorSelectNoteTypePrompt(function(text)
		{
			var notes:Array<NoteInfo> = [];
			for (note in state.song.notes)
			{
				if (note.type == text && note.player == 1)
					notes.push(note);
			}
			state.selectedObjects.clear();
			state.selectedObjects.pushMultiple(cast notes);
		});
		
		var tab = createTab('Notes');
		
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
		
		noteParamsInput = new EditorInputText(paramsLabel.x, paramsLabel.y + paramsLabel.height + spacing, inputWidth);
		noteParamsInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeNoteParams(state, selectedNotes.copy(), text));
		});
		tab.add(noteParamsInput);
		notePropertiesGroup.push(noteParamsInput);
		
		var selectP1NotesButton = new FlxUIButton(0, noteParamsInput.y + noteParamsInput.height + spacing, 'Select P1 notes', function()
		{
			var notes:Array<NoteInfo> = [];
			for (note in state.song.notes)
			{
				if (note.player == 0 && !state.selectedObjects.value.contains(note))
					notes.push(note);
			}
			state.selectedObjects.pushMultiple(cast notes);
		});
		selectP1NotesButton.resize(90, selectP1NotesButton.height);
		selectP1NotesButton.x = (width - selectP1NotesButton.width) / 2;
		tab.add(selectP1NotesButton);
		
		var selectP2NotesButton = new FlxUIButton(0, selectP1NotesButton.y + selectP1NotesButton.height + spacing, 'Select P2 notes', function()
		{
			var notes:Array<NoteInfo> = [];
			for (note in state.song.notes)
			{
				if (note.player == 1 && !state.selectedObjects.value.contains(note))
					notes.push(note);
			}
			state.selectedObjects.pushMultiple(cast notes);
		});
		selectP2NotesButton.resize(90, selectP2NotesButton.height);
		selectP2NotesButton.x = (width - selectP2NotesButton.width) / 2;
		tab.add(selectP2NotesButton);
		
		var resnapAllToCurrentButton = new FlxUIButton(0, selectP2NotesButton.y + selectP2NotesButton.height + spacing,
			'Resnap all notes to currently selected snap', function()
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
		
		var mirrorNotesButton = new FlxUIButton(0, resnapSelectedToDefaultButton.y + resnapSelectedToDefaultButton.height + spacing, 'Mirror all notes',
			function()
			{
				if (state.song.notes.length > 0)
					state.actionManager.perform(new ActionApplyModifier(state, MIRROR));
			});
		mirrorNotesButton.resize(100, mirrorNotesButton.height);
		mirrorNotesButton.x = (width - mirrorNotesButton.width) / 2;
		tab.add(mirrorNotesButton);
		
		var noLongNotesButton = new FlxUIButton(0, mirrorNotesButton.y + mirrorNotesButton.height + spacing, 'No long notes', function()
		{
			if (state.song.notes.length > 0)
				state.actionManager.perform(new ActionApplyModifier(state, NO_LONG_NOTES));
		});
		noLongNotesButton.resize(100, noLongNotesButton.height);
		noLongNotesButton.x = (width - noLongNotesButton.width) / 2;
		tab.add(noLongNotesButton);
		
		var fullLongNotesButton = new FlxUIButton(0, noLongNotesButton.y + noLongNotesButton.height + spacing, 'Full long notes', function()
		{
			if (state.song.notes.length > 0)
				state.actionManager.perform(new ActionApplyModifier(state, FULL_LONG_NOTES));
		});
		fullLongNotesButton.resize(100, fullLongNotesButton.height);
		fullLongNotesButton.x = (width - fullLongNotesButton.width) / 2;
		tab.add(fullLongNotesButton);
		
		var inverseButton = new FlxUIButton(0, fullLongNotesButton.y + fullLongNotesButton.height + spacing, 'Invert notes', function()
		{
			if (state.song.notes.length > 0)
				state.actionManager.perform(new ActionApplyModifier(state, INVERSE));
		});
		inverseButton.resize(100, inverseButton.height);
		inverseButton.x = (width - inverseButton.width) / 2;
		tab.add(inverseButton);
		
		var duetButton = new FlxUIButton(0, inverseButton.y + inverseButton.height + spacing, 'Duet selected notes', function()
		{
			if (selectedNotes.length > 0)
			{
				var notes:Array<NoteInfo> = [];
				for (note in selectedNotes)
				{
					var info = new NoteInfo({
						startTime: note.startTime,
						lane: (note.lane + 4) % 8,
						endTime: note.endTime,
						type: note.type,
						params: note.params.join(',')
					});
					var accept = true;
					for (songNote in state.song.notes)
					{
						if (Std.int(songNote.startTime) == Std.int(info.startTime) && songNote.lane == info.lane)
						{
							accept = false;
							break;
						}
					}
					if (accept)
						notes.push(info);
				}
				if (notes.length > 0)
					state.actionManager.perform(new ActionAddObjectBatch(state, cast notes));
			}
		});
		duetButton.resize(120, duetButton.height);
		duetButton.x = (width - duetButton.width) / 2;
		tab.add(duetButton);
		
		var selectAllNoteTypeButton = new FlxUIButton(0, duetButton.y + duetButton.height + spacing, 'Select all notes of type', function()
		{
			state.openSubState(selectAllNoteTypePrompt);
		});
		selectAllNoteTypeButton.resize(130, selectAllNoteTypeButton.height);
		selectAllNoteTypeButton.x = (width - selectAllNoteTypeButton.width) / 2;
		tab.add(selectAllNoteTypeButton);
		
		var selectP1NoteTypeButton = new FlxUIButton(0, selectAllNoteTypeButton.y + selectAllNoteTypeButton.height + spacing, 'Select P1 notes of type',
			function()
			{
				state.openSubState(selectP1NoteTypePrompt);
			});
		selectP1NoteTypeButton.resize(130, selectP1NoteTypeButton.height);
		selectP1NoteTypeButton.x = (width - selectP1NoteTypeButton.width) / 2;
		tab.add(selectP1NoteTypeButton);
		
		var selectP2NoteTypeButton = new FlxUIButton(0, selectP1NoteTypeButton.y + selectP1NoteTypeButton.height + spacing, 'Select P2 notes of type',
			function()
			{
				state.openSubState(selectP2NoteTypePrompt);
			});
		selectP2NoteTypeButton.resize(130, selectP2NoteTypeButton.height);
		selectP2NoteTypeButton.x = (width - selectP2NoteTypeButton.width) / 2;
		tab.add(selectP2NoteTypeButton);
		
		var getTypeListButton = new FlxUIButton(0, selectP2NoteTypeButton.y + selectP2NoteTypeButton.height + spacing, 'Get Note Type List', function()
		{
			var types:Array<String> = [];
			for (note in state.song.notes)
			{
				if (note.type.length > 0 && !types.contains(note.type))
					types.push(note.type);
			}
			if (types.length > 0)
				Main.showNotification(types.join(', '));
			else
				Main.showNotification('No special note types found.');
		});
		getTypeListButton.resize(110, getTypeListButton.height);
		getTypeListButton.x = (width - getTypeListButton.width) / 2;
		tab.add(getTypeListButton);
		
		addGroup(tab);
	}
	
	function createTimingPointsTab()
	{
		var tab = createTab('Timing Points');
		
		var timingPointTimeLabel = new EditorText(4, 4, 0, 'Time:');
		tab.add(timingPointTimeLabel);
		timingPointPropertiesGroup.push(timingPointTimeLabel);
		
		timingPointTimeStepper = new EditorNumericStepper(timingPointTimeLabel.x, timingPointTimeLabel.y + timingPointTimeLabel.height + spacing, 1, 0, 0);
		timingPointTimeStepper.valueChanged.add(function(value, _)
		{
			state.actionManager.perform(new ActionChangeTimingPointTime(state, selectedTimingPoints.copy(), value));
		});
		tab.add(timingPointTimeStepper);
		timingPointPropertiesGroup.push(timingPointTimeStepper);
		
		var bpmLabel = new EditorText(timingPointTimeStepper.x + timingPointTimeStepper.width + spacing, timingPointTimeLabel.y, 0, 'BPM:');
		tab.add(bpmLabel);
		timingPointPropertiesGroup.push(bpmLabel);
		
		bpmStepper = new EditorNumericStepper(bpmLabel.x, bpmLabel.y + bpmLabel.height + spacing, 1, 120, 1, 1000, 3);
		bpmStepper.valueChanged.add(function(value, _)
		{
			state.actionManager.perform(new ActionChangeTimingPointBPM(state, selectedTimingPoints.copy(), value));
		});
		tab.add(bpmStepper);
		timingPointPropertiesGroup.push(bpmStepper);
		
		var meterLabel = new EditorText(bpmStepper.x + bpmStepper.width + spacing, bpmLabel.y, 0, 'Meter:');
		tab.add(meterLabel);
		timingPointPropertiesGroup.push(meterLabel);
		
		meterStepper = new EditorNumericStepper(meterLabel.x, meterLabel.y + meterLabel.height + spacing, 1, 4, 1, 16, 0);
		meterStepper.valueChanged.add(function(value, _)
		{
			state.actionManager.perform(new ActionChangeTimingPointMeter(state, selectedTimingPoints.copy(), Std.int(value)));
		});
		tab.add(meterStepper);
		timingPointPropertiesGroup.push(meterStepper);
		
		var selectCurrentButton = new FlxUIButton(0, meterStepper.y + meterStepper.height + spacing, 'Select current timing point', function()
		{
			var point = state.song.getTimingPointAt(state.inst.time);
			if (point != null)
			{
				for (obj in state.selectedObjects.value)
				{
					if (Std.isOfType(obj, TimingPoint))
						state.selectedObjects.remove(obj);
				}
				state.selectedObjects.push(point);
				if (!state.inst.playing && state.inst.time != point.startTime)
					state.setSongTime(point.startTime);
			}
		});
		selectCurrentButton.resize(150, selectCurrentButton.height);
		selectCurrentButton.x = (width - selectCurrentButton.width) / 2;
		tab.add(selectCurrentButton);
		
		addGroup(tab);
	}
	
	function createScrollVelocitiesTab()
	{
		var tab = createTab('Scroll Velocities');
		
		var multiplierLabel1 = new EditorText(4, 4, 0, 'P1 Multiplier:');
		tab.add(multiplierLabel1);
		scrollVelocitiesPropertiesGroup.push(multiplierLabel1);
		
		multiplierStepper1 = new EditorNumericStepper(multiplierLabel1.x, multiplierLabel1.y + multiplierLabel1.height + spacing, 0.1, 1, -100, 100, 2);
		multiplierStepper1.valueChanged.add(function(value, lastValue)
		{
			var linked = true;
			for (sv in selectedScrollVelocities)
			{
				if (!sv.linked)
				{
					linked = false;
					break;
				}
			}
			if (linked)
				state.actionManager.perform(new ActionChangeSVMultipliers(state, selectedScrollVelocities.copy(), [value, value]));
			else
				state.actionManager.perform(new ActionChangeSVMultiplier(state, selectedScrollVelocities.copy(), 0, value));
		});
		tab.add(multiplierStepper1);
		scrollVelocitiesPropertiesGroup.push(multiplierStepper1);
		
		var multiplierLabel2 = new EditorText(multiplierStepper1.x + multiplierStepper1.width + spacing, multiplierLabel1.y, 0, 'P2 Multiplier:');
		tab.add(multiplierLabel2);
		scrollVelocitiesPropertiesGroup.push(multiplierLabel2);
		
		multiplierStepper2 = new EditorNumericStepper(multiplierLabel2.x, multiplierLabel2.y + multiplierLabel2.height + spacing, 0.1, 1, -100, 100, 2);
		multiplierStepper2.valueChanged.add(function(value, _)
		{
			var linked = true;
			for (sv in selectedScrollVelocities)
			{
				if (!sv.linked)
				{
					linked = false;
					break;
				}
			}
			if (linked)
				state.actionManager.perform(new ActionChangeSVMultipliers(state, selectedScrollVelocities.copy(), [value, value]));
			else
				state.actionManager.perform(new ActionChangeSVMultiplier(state, selectedScrollVelocities.copy(), 1, value));
		});
		tab.add(multiplierStepper2);
		scrollVelocitiesPropertiesGroup.push(multiplierStepper2);
		
		linkedCheckbox = new EditorCheckbox(multiplierStepper2.x + multiplierStepper2.width + spacing, multiplierStepper2.y, 'Linked');
		linkedCheckbox.callback = function()
		{
			state.actionManager.perform(new ActionChangeSVLinked(state, selectedScrollVelocities.copy(), linkedCheckbox.checked));
		};
		tab.add(linkedCheckbox);
		scrollVelocitiesPropertiesGroup.push(linkedCheckbox);
		
		var selectCurrentButton = new FlxUIButton(0, linkedCheckbox.y + linkedCheckbox.height + spacing, 'Select current scroll velocity', function()
		{
			var sv = state.song.getScrollVelocityAt(state.inst.time);
			if (sv != null)
			{
				for (obj in state.selectedObjects.value)
				{
					if (Std.isOfType(obj, ScrollVelocity))
						state.selectedObjects.remove(obj);
				}
				state.selectedObjects.push(sv);
				if (!state.inst.playing && state.inst.time != sv.startTime)
					state.setSongTime(sv.startTime);
			}
		});
		selectCurrentButton.resize(150, selectCurrentButton.height);
		selectCurrentButton.x = (width - selectCurrentButton.width) / 2;
		tab.add(selectCurrentButton);
		
		addGroup(tab);
	}
	
	function createCameraFocusesTab()
	{
		var tab = createTab('Camera Focuses');
		
		var charLabel = new EditorText(4, 4, 0, 'Character:');
		tab.add(charLabel);
		cameraFocusesPropertiesGroup.push(charLabel);
		
		var chars = ['Opponent', 'Boyfriend', 'Girlfriend'];
		charDropdown = new EditorDropdownMenu(charLabel.x, charLabel.y + charLabel.height + spacing, EditorDropdownMenu.makeStrIdLabelArray(chars, true),
			function(id)
			{
				state.actionManager.perform(new ActionChangeCameraFocusChar(state, selectedCameraFocuses.copy(), Std.parseInt(id)));
			}, this);
		cameraFocusesPropertiesGroup.push(charDropdown);
		
		var selectCurrentButton = new FlxUIButton(0, charDropdown.y + charDropdown.height + spacing, 'Select current camera focus', function()
		{
			var focus = state.song.getCameraFocusAt(state.inst.time);
			if (focus != null)
			{
				for (obj in state.selectedObjects.value)
				{
					if (Std.isOfType(obj, CameraFocus))
						state.selectedObjects.remove(obj);
				}
				state.selectedObjects.push(focus);
				if (!state.inst.playing && state.inst.time != focus.startTime)
					state.setSongTime(focus.startTime);
			}
		});
		selectCurrentButton.resize(150, selectCurrentButton.height);
		selectCurrentButton.x = (width - selectCurrentButton.width) / 2;
		tab.add(selectCurrentButton);
		
		tab.add(charDropdown);
		
		addGroup(tab);
	}
	
	function createEventsTab()
	{
		selectEventPrompt = new PromptInputSubState("Enter an event to select.", function(text)
		{
			var events:Array<EventObject> = [];
			for (event in state.song.events)
			{
				for (e in event.events)
				{
					if (e.event == text)
					{
						events.push(event);
						break;
					}
				}
			}
			state.selectedObjects.clear();
			state.selectedObjects.pushMultiple(cast events);
		});
		
		var tab = createTab('Events');
		
		var inputWidth = width - 10;
		
		eventIndexLabel = new EditorText(4, 4, 0, 'Selected Event: 0 / 0');
		tab.add(eventIndexLabel);
		eventsPropertiesGroup.push(eventIndexLabel);
		
		var eventLabel = new EditorText(eventIndexLabel.x, eventIndexLabel.y + eventIndexLabel.height + spacing, 0, 'Event Name:');
		tab.add(eventLabel);
		eventsPropertiesGroup.push(eventLabel);
		
		eventInput = new EditorInputText(eventLabel.x, eventLabel.y + eventLabel.height + spacing, inputWidth);
		eventInput.textChanged.add(function(text, _)
		{
			if (selectedEvents[0] == null)
				return;
			state.actionManager.perform(new ActionChangeEvent(state, selectedEvents[0].events[eventIndex], text));
		});
		tab.add(eventInput);
		eventsPropertiesGroup.push(eventInput);
		
		var eventParamsLabel = new EditorText(eventInput.x, eventInput.y + eventInput.height + spacing, 0, 'Event Parameters:');
		tab.add(eventParamsLabel);
		eventsPropertiesGroup.push(eventParamsLabel);
		
		eventParamsInput = new EditorInputText(eventParamsLabel.x, eventParamsLabel.y + eventParamsLabel.height + spacing, inputWidth);
		eventParamsInput.textChanged.add(function(text, _)
		{
			if (selectedEvents[0] == null)
				return;
			state.actionManager.perform(new ActionChangeEventParams(state, selectedEvents[0].events[eventIndex], text));
		});
		tab.add(eventParamsInput);
		eventsPropertiesGroup.push(eventParamsInput);
		
		var removeButton = new FlxUIButton(0, 4, '-', function()
		{
			var eventObject = selectedEvents[0];
			if (eventObject == null)
				return;
			if (eventObject.events.length > 1)
				state.actionManager.perform(new ActionRemoveEvent(state, eventObject, eventObject.events[eventIndex], eventIndex));
			else
				state.actionManager.perform(new ActionRemoveObject(state, eventObject));
		});
		removeButton.resize(removeButton.height, removeButton.height);
		removeButton.label.size = 12;
		removeButton.autoCenterLabel();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		eventsPropertiesGroup.push(removeButton);
		
		var addButton = new FlxUIButton(0, 4, '+', function()
		{
			var eventObject = selectedEvents[0];
			if (eventObject == null)
				return;
			state.actionManager.perform(new ActionAddEvent(state, eventObject, new Event({}), eventIndex + 1));
			eventIndex++;
			updateEventDisplay();
		});
		addButton.resize(addButton.height, addButton.height);
		addButton.label.size = 12;
		addButton.autoCenterLabel();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		eventsPropertiesGroup.push(addButton);
		
		var moveLeftButton = new FlxUIButton(0, 4, '<', function()
		{
			eventIndex--;
			if (eventIndex < 0)
				eventIndex = selectedEvents[0].events.length - 1;
			updateEventDisplay();
		});
		moveLeftButton.resize(moveLeftButton.height, moveLeftButton.height);
		moveLeftButton.label.size = 12;
		moveLeftButton.autoCenterLabel();
		eventsPropertiesGroup.push(moveLeftButton);
		
		var moveRightButton = new FlxUIButton(0, 4, '>', function()
		{
			eventIndex++;
			if (eventIndex >= selectedEvents[0].events.length)
				eventIndex = 0;
			updateEventDisplay();
		});
		moveRightButton.resize(moveRightButton.height, moveRightButton.height);
		moveRightButton.label.size = 12;
		moveRightButton.autoCenterLabel();
		eventsPropertiesGroup.push(moveRightButton);
		
		moveRightButton.x = width - moveRightButton.width - 4;
		moveLeftButton.x = moveRightButton.x - moveLeftButton.width - 4;
		addButton.x = moveLeftButton.x - addButton.width - 4;
		removeButton.x = addButton.x - removeButton.width - 4;
		tab.add(removeButton);
		tab.add(addButton);
		tab.add(moveLeftButton);
		tab.add(moveRightButton);
		
		var selectAllEventButton = new FlxUIButton(0, eventParamsInput.y + eventParamsInput.height + spacing, "Select events with name", function()
		{
			state.openSubState(selectEventPrompt);
		});
		selectAllEventButton.resize(130, selectAllEventButton.height);
		selectAllEventButton.x = (width - selectAllEventButton.width) / 2;
		tab.add(selectAllEventButton);
		
		var getEventListButton = new FlxUIButton(0, selectAllEventButton.y + selectAllEventButton.height + spacing, 'Get Event List', function()
		{
			var types:Array<String> = [];
			for (event in state.song.events)
			{
				for (e in event.events)
				{
					if (e.event.length > 0 && !types.contains(e.event))
						types.push(e.event);
				}
			}
			if (types.length > 0)
				Main.showNotification(types.join(', '));
			else
				Main.showNotification('No events found.');
		});
		getEventListButton.resize(110, getEventListButton.height);
		getEventListButton.x = (width - getEventListButton.width) / 2;
		tab.add(getEventListButton);
		
		addGroup(tab);
	}
	
	function createLyricsTab()
	{
		var tab = createTab('Lyrics');
		
		lyricsInput = new EditorInputText(4, 4, width - 10, state.lyrics);
		lyricsInput.multiline = true;
		lyricsInput.resize(0, height - 64);
		lyricsInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeLyrics(state, lyricsInput.text, state.lyrics));
		});
		tab.add(lyricsInput);
		
		addGroup(tab);
	}
	
	function createExtraTab() {}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var hideSteppers = beatSnapDropdown.dropPanel.exists || waveformDropdown.dropPanel.exists;
		vocalsVolumeStepper.alpha = instVolumeStepper.alpha = hideSteppers ? 0 : 1;
		vocalsVolumeStepper.active = instVolumeStepper.active = (selected_tab_id == 'Editor' && !hideSteppers);
	}
	
	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.CHANGE_NOTE_TYPE, SongEditorActionManager.CHANGE_NOTE_PARAMS:
				updateSelectedNotes();
			case SongEditorActionManager.CHANGE_TIMING_POINT_BPM, SongEditorActionManager.CHANGE_TIMING_POINT_METER:
				updateSelectedTimingPoints();
			case SongEditorActionManager.CHANGE_SV_MULTIPLIER, SongEditorActionManager.CHANGE_SV_MULTIPLIERS, SongEditorActionManager.CHANGE_SV_LINKED:
				updateSelectedScrollVelocities();
			case SongEditorActionManager.CHANGE_CAMERA_FOCUS_CHAR:
				updateSelectedCameraFocuses();
			case SongEditorActionManager.CHANGE_EVENT, SongEditorActionManager.CHANGE_EVENT_PARAMS, SongEditorActionManager.ADD_EVENT,
				SongEditorActionManager.REMOVE_EVENT:
				updateEventDisplay();
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
			case SongEditorActionManager.CHANGE_STAGE:
				stageInput.text = params.stage;
			case SongEditorActionManager.CHANGE_INITIAL_SV:
				velocityStepper.value = params.initialScrollVelocity;
			case SongEditorActionManager.CHANGE_LYRICS:
				lyricsInput.text = params.lyrics;
		}
	}
	
	function onSelectedObject(obj:ITimingObject)
	{
		if (Std.isOfType(obj, NoteInfo))
		{
			selectedNotes.push(cast obj);
			updateSelectedNotes();
		}
		else if (Std.isOfType(obj, TimingPoint))
		{
			selectedTimingPoints.push(cast obj);
			updateSelectedTimingPoints();
		}
		else if (Std.isOfType(obj, ScrollVelocity))
		{
			selectedScrollVelocities.push(cast obj);
			updateSelectedScrollVelocities();
		}
		else if (Std.isOfType(obj, CameraFocus))
		{
			selectedCameraFocuses.push(cast obj);
			updateSelectedCameraFocuses();
		}
		else if (Std.isOfType(obj, EventObject))
		{
			selectedEvents.push(cast obj);
			updateSelectedEvents();
		}
	}
	
	function onDeselectedObject(obj:ITimingObject)
	{
		if (Std.isOfType(obj, NoteInfo))
		{
			selectedNotes.remove(cast obj);
			updateSelectedNotes();
		}
		else if (Std.isOfType(obj, TimingPoint))
		{
			selectedTimingPoints.remove(cast obj);
			updateSelectedTimingPoints();
		}
		else if (Std.isOfType(obj, ScrollVelocity))
		{
			selectedScrollVelocities.remove(cast obj);
			updateSelectedScrollVelocities();
		}
		else if (Std.isOfType(obj, CameraFocus))
		{
			selectedCameraFocuses.remove(cast obj);
			updateSelectedCameraFocuses();
		}
		else if (Std.isOfType(obj, EventObject))
		{
			selectedEvents.remove(cast obj);
			updateSelectedEvents();
		}
	}
	
	function onMultipleObjectsSelected(objects:Array<ITimingObject>)
	{
		var foundNote = false;
		var foundTP = false;
		var foundSV = false;
		var foundFocus = false;
		var foundEvent = false;
		for (obj in objects)
		{
			if (Std.isOfType(obj, NoteInfo))
			{
				selectedNotes.push(cast obj);
				foundNote = true;
			}
			else if (Std.isOfType(obj, TimingPoint))
			{
				selectedTimingPoints.push(cast obj);
				foundTP = true;
			}
			else if (Std.isOfType(obj, ScrollVelocity))
			{
				selectedScrollVelocities.push(cast obj);
				foundSV = true;
			}
			else if (Std.isOfType(obj, CameraFocus))
			{
				selectedCameraFocuses.push(cast obj);
				foundFocus = true;
			}
			else if (Std.isOfType(obj, EventObject))
			{
				selectedEvents.push(cast obj);
				foundEvent = true;
			}
		}
		if (foundNote)
			updateSelectedNotes();
		if (foundTP)
			updateSelectedTimingPoints();
		if (foundSV)
			updateSelectedScrollVelocities();
		if (foundFocus)
			updateSelectedCameraFocuses();
		if (foundEvent)
			updateSelectedEvents();
	}
	
	function onAllObjectsDeselected()
	{
		if (selectedNotes.length > 0)
		{
			selectedNotes.resize(0);
			updateSelectedNotes();
		}
		
		if (selectedTimingPoints.length > 0)
		{
			selectedTimingPoints.resize(0);
			updateSelectedTimingPoints();
		}
		
		if (selectedScrollVelocities.length > 0)
		{
			selectedScrollVelocities.resize(0);
			updateSelectedScrollVelocities();
		}
		
		if (selectedCameraFocuses.length > 0)
		{
			selectedCameraFocuses.resize(0);
			updateSelectedCameraFocuses();
		}
		
		if (selectedEvents.length > 0)
		{
			selectedEvents.resize(0);
			updateSelectedEvents();
		}
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
			
			if (type == '...')
				typeInput.displayText = type;
			else
				typeInput.text = type;
				
			if (params == '...')
				noteParamsInput.displayText = params;
			else
				noteParamsInput.text = params;
				
			for (obj in notePropertiesGroup)
			{
				if (selected_tab_id == 'Notes')
					obj.active = true;
				obj.alpha = 1;
			}
		}
		else
		{
			for (obj in notePropertiesGroup)
			{
				obj.active = false;
				obj.alpha = 0.5;
			}
		}
	}
	
	function updateSelectedTimingPoints()
	{
		if (selectedTimingPoints.length > 0)
		{
			var multipleTime = false;
			var multipleBPM = false;
			var multipleMeter = false;
			for (i in 1...selectedTimingPoints.length)
			{
				if (selectedTimingPoints[i].startTime != selectedTimingPoints[0].startTime)
					multipleTime = true;
					
				if (selectedTimingPoints[i].bpm != selectedTimingPoints[0].bpm)
					multipleBPM = true;
					
				if (selectedTimingPoints[i].meter != selectedTimingPoints[0].meter)
					multipleMeter = true;
					
				if (multipleTime && multipleBPM && multipleMeter)
					break;
			}
			
			if (multipleTime)
				timingPointTimeStepper.setDisplayText('...');
			else
				timingPointTimeStepper.value = selectedTimingPoints[0].startTime;
				
			if (multipleBPM)
				bpmStepper.setDisplayText('...');
			else
				bpmStepper.value = selectedTimingPoints[0].bpm;
				
			if (multipleMeter)
				meterStepper.setDisplayText('...');
			else
				meterStepper.value = selectedTimingPoints[0].meter;
				
			for (obj in timingPointPropertiesGroup)
			{
				if (selected_tab_id == 'Timing Points')
					obj.active = true;
				obj.alpha = 1;
			}
		}
		else
		{
			for (obj in timingPointPropertiesGroup)
			{
				obj.active = false;
				obj.alpha = 0.5;
			}
		}
	}
	
	function updateSelectedScrollVelocities()
	{
		if (selectedScrollVelocities.length > 0)
		{
			var multipleMult1 = false;
			var multipleMult2 = false;
			var multipleLinked = false;
			for (i in 1...selectedScrollVelocities.length)
			{
				if (selectedScrollVelocities[i].multipliers[0] != selectedScrollVelocities[0].multipliers[0])
					multipleMult1 = true;
					
				if (selectedScrollVelocities[i].multipliers[1] != selectedScrollVelocities[0].multipliers[1])
					multipleMult2 = true;
					
				if (selectedScrollVelocities[i].linked != selectedScrollVelocities[0].linked)
					multipleLinked = true;
			}
			
			if (multipleMult1)
				multiplierStepper1.setDisplayText('...');
			else
				multiplierStepper1.value = selectedScrollVelocities[0].multipliers[0];
				
			if (multipleMult2)
				multiplierStepper2.setDisplayText('...');
			else
				multiplierStepper2.value = selectedScrollVelocities[0].multipliers[1];
				
			if (multipleLinked)
				linkedCheckbox.checked = false;
			else
				linkedCheckbox.checked = selectedScrollVelocities[0].linked;
				
			for (obj in scrollVelocitiesPropertiesGroup)
			{
				if (selected_tab_id == 'Scroll Velocities')
					obj.active = true;
				obj.alpha = 1;
			}
		}
		else
		{
			for (obj in scrollVelocitiesPropertiesGroup)
			{
				obj.active = false;
				obj.alpha = 0.5;
			}
		}
	}
	
	function updateSelectedCameraFocuses()
	{
		if (selectedCameraFocuses.length > 0)
		{
			var multipleChars = false;
			for (i in 1...selectedCameraFocuses.length)
			{
				if (selectedCameraFocuses[i].char != selectedCameraFocuses[0].char)
				{
					multipleChars = true;
					break;
				}
			}
			
			if (!multipleChars)
				charDropdown.selectedId = Std.string(selectedCameraFocuses[0].char);
				
			for (obj in cameraFocusesPropertiesGroup)
			{
				if (selected_tab_id == 'Camera Focuses')
					obj.active = true;
				obj.alpha = 1;
			}
		}
		else
		{
			if (charDropdown.dropPanel.exists)
				charDropdown.header.button.onUp.callback();
			for (obj in cameraFocusesPropertiesGroup)
			{
				obj.active = false;
				obj.alpha = 0.5;
			}
		}
	}
	
	function updateSelectedEvents()
	{
		if (selectedEvents.length == 1)
		{
			for (obj in eventsPropertiesGroup)
			{
				if (selected_tab_id == 'Events')
					obj.active = true;
				obj.alpha = 1;
			}
		}
		else
		{
			for (obj in eventsPropertiesGroup)
			{
				obj.active = false;
				obj.alpha = 0.5;
			}
		}
		updateEventDisplay();
	}
	
	function updateEventDisplay()
	{
		if (selectedEvents.length == 1)
		{
			var eventObject = selectedEvents[0];
			if (lastEvent != eventObject)
				eventIndex = 0;
			else if (eventIndex >= eventObject.events.length)
				eventIndex = eventObject.events.length - 1;
				
			eventIndexLabel.text = 'Selected Event: ${eventIndex + 1} / ${eventObject.events.length}';
			
			var event = eventObject.events[eventIndex];
			eventInput.text = event.event;
			eventParamsInput.text = event.params.join(',');
			
			lastEvent = eventObject;
		}
		else
		{
			eventIndex = 0;
			eventIndexLabel.text = 'Selected Event: 0 / 0';
		}
	}
	
	function onClickTab(name:String)
	{
		if (selectedNotes.length == 0)
			updateSelectedNotes();
		if (selectedTimingPoints.length == 0)
			updateSelectedTimingPoints();
		if (selectedScrollVelocities.length == 0)
			updateSelectedScrollVelocities();
		if (selectedCameraFocuses.length == 0)
			updateSelectedCameraFocuses();
		if (selectedEvents.length == 0)
			updateSelectedEvents();
	}
	
	function getDifficulties()
	{
		return Song.getSongDifficulties(state.song.directory, state.song.difficultyName);
	}
}
