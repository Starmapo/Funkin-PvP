package states.editors;

import data.Settings;
import data.song.CameraFocus;
import data.song.ITimingObject;
import data.song.NoteInfo;
import data.song.ScrollVelocity;
import data.song.Song;
import data.song.TimingPoint;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSort;
import haxe.io.Path;
import lime.app.Application;
import lime.system.Clipboard;
import subStates.editors.song.SongEditorApplyOffsetPrompt;
import subStates.editors.song.SongEditorSavePrompt;
import ui.editors.NotificationManager;
import ui.editors.Tooltip;
import ui.editors.song.SongEditorCamFocusDisplay;
import ui.editors.song.SongEditorCompositionPanel;
import ui.editors.song.SongEditorDetailsPanel;
import ui.editors.song.SongEditorEditPanel;
import ui.editors.song.SongEditorPlayfield;
import ui.editors.song.SongEditorPlayfieldTabs;
import ui.editors.song.SongEditorSeekBar;
import ui.editors.song.SongEditorSelector;
import util.MusicTiming;
import util.bindable.Bindable;
import util.bindable.BindableArray;
import util.bindable.BindableInt;
import util.editors.song.SongEditorActionManager;
import util.editors.song.SongEditorMetronome;

class SongEditorState extends FNFState
{
	public var hitPositionY:Int = 545;
	public var playfieldNotes:SongEditorPlayfield;
	public var playfieldOther:SongEditorPlayfield;
	public var beatSnap:BindableInt = new BindableInt(4, 1, 48);
	public var trackSpeed(get, never):Float;
	public var trackPositionY(get, never):Float;
	public var song:Song;
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var availableBeatSnaps:Array<Int> = [1, 2, 3, 4, 6, 8, 12, 16];
	public var songSeeked:FlxTypedSignal<Float->Float->Void> = new FlxTypedSignal();
	public var rateChanged:FlxTypedSignal<Float->Float->Void> = new FlxTypedSignal();
	public var currentTool:Bindable<CompositionTool> = new Bindable(SELECT);
	public var notificationManager:NotificationManager;
	public var tooltip:Tooltip;
	public var selectedObjects:BindableArray<ITimingObject> = new BindableArray([]);
	public var seekBar:SongEditorSeekBar;
	public var zoomInButton:FlxUIButton;
	public var zoomOutButton:FlxUIButton;
	public var detailsPanel:SongEditorDetailsPanel;
	public var compositionPanel:SongEditorCompositionPanel;
	public var editPanel:SongEditorEditPanel;
	public var actionManager:SongEditorActionManager;
	public var copiedObjects:Array<ITimingObject> = [];
	public var playfield(get, never):SongEditorPlayfield;
	public var playfieldTabs:SongEditorPlayfieldTabs;
	public var selector:SongEditorSelector;

	var timeSinceLastPlayfieldZoom:Float = 0;
	var beatSnapIndex(get, never):Int;
	var hitsoundNoteIndex:Int = 0;
	var camHUD:FlxCamera;
	var savePrompt:SongEditorSavePrompt;
	var applyOffsetPrompt:SongEditorApplyOffsetPrompt;
	var camFocusDisplay:SongEditorCamFocusDisplay;
	var metronome:SongEditorMetronome;

	override function create()
	{
		persistentUpdate = true;
		destroySubStates = false;

		actionManager = new SongEditorActionManager(this);

		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);

		song = Song.loadSong('mods/fnf/songs/Reminisce/Hard.json');
		inst = FlxG.sound.load(Paths.getSongInst(song), Settings.editorInstVolume.value, false, FlxG.sound.defaultMusicGroup);
		inst.onComplete = onSongComplete;
		vocals = FlxG.sound.load(Paths.getSongVocals(song), Settings.editorVocalsVolume.value, false, FlxG.sound.defaultMusicGroup);
		if (vocals == null)
			vocals = FlxG.sound.list.add(new FlxSound());

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;

		playfieldTabs = new SongEditorPlayfieldTabs(this);
		playfieldTabs.screenCenter(X);

		playfieldNotes = new SongEditorPlayfield(this, NOTES, 8);

		playfieldOther = new SongEditorPlayfield(this, OTHER, 5);
		playfieldOther.exists = false;

		seekBar = new SongEditorSeekBar(this);

		selector = new SongEditorSelector(this);

		camFocusDisplay = new SongEditorCamFocusDisplay(10, 0, this);
		camFocusDisplay.screenCenter(Y);

		tooltip = new Tooltip();
		tooltip.cameras = [camHUD];

		zoomInButton = new FlxUIButton(playfieldNotes.bg.x + playfieldNotes.bg.width + 10, 10, '+', function()
		{
			Settings.editorScrollSpeed.value += 0.05;
			editPanel.updateSpeedStepper();
		});
		zoomInButton.resize(26, 26);
		zoomInButton.label.size = 16;
		for (point in zoomInButton.labelOffsets)
			point.add(1, 1);
		zoomInButton.autoCenterLabel();
		tooltip.addTooltip(zoomInButton, 'Zoom In (Hotkey: Page Up)');

		zoomOutButton = new FlxUIButton(zoomInButton.x, zoomInButton.y + zoomInButton.height + 4, '-', function()
		{
			Settings.editorScrollSpeed.value -= 0.05;
			editPanel.updateSpeedStepper();
		});
		zoomOutButton.resize(26, 26);
		zoomOutButton.label.size = 16;
		for (point in zoomOutButton.labelOffsets)
			point.add(1, 1);
		zoomOutButton.autoCenterLabel();
		tooltip.addTooltip(zoomOutButton, 'Zoom Out (Hotkey: Page Down)');

		metronome = new SongEditorMetronome(this);

		detailsPanel = new SongEditorDetailsPanel(this);

		compositionPanel = new SongEditorCompositionPanel(this);

		editPanel = new SongEditorEditPanel(this);

		savePrompt = new SongEditorSavePrompt(onSavePrompt);
		applyOffsetPrompt = new SongEditorApplyOffsetPrompt(onApplyOffsetPrompt);

		notificationManager = new NotificationManager();

		add(bg);
		add(playfieldNotes);
		add(playfieldOther);
		add(playfieldTabs);
		add(seekBar);
		add(selector);
		add(camFocusDisplay);
		add(zoomInButton);
		add(zoomOutButton);
		add(detailsPanel);
		add(compositionPanel);
		add(editPanel);
		add(notificationManager);
		add(tooltip);

		setHitsoundNoteIndex();

		Application.current.onExit.add(onExit);

		super.create();
	}

	override function update(elapsed:Float)
	{
		handleInput();

		playfieldTabs.update(elapsed);
		selector.update(elapsed);
		seekBar.update(elapsed);
		camFocusDisplay.update(elapsed);
		zoomInButton.update(elapsed);
		zoomOutButton.update(elapsed);
		compositionPanel.update(elapsed);
		editPanel.update(elapsed);
		if (playfieldNotes.exists)
			playfieldNotes.update(elapsed);
		if (playfieldOther.exists)
			playfieldOther.update(elapsed);
		metronome.update();
		detailsPanel.update(elapsed);
		notificationManager.update(elapsed);
		tooltip.update(elapsed);

		FlxG.camera.scroll.y = -trackPositionY;

		resyncVocals();

		var playedHitsound = false;
		if (inst.playing)
		{
			for (i in hitsoundNoteIndex...song.notes.length)
			{
				var note = song.notes[i];
				if (inst.time >= note.startTime)
				{
					if (Settings.editorHitsoundVolume.value > 0
						&& !playedHitsound
						&& ((note.player == 0 && Settings.editorOpponentHitsounds.value)
							|| (note.player == 1 && Settings.editorBFHitsounds.value)))
					{
						var hitsound = FlxG.sound.play(Paths.getSound('editor/hitsound'), Settings.editorHitsoundVolume.value);
						hitsound.pan = (note.player == 0 ? -0.5 : 0.5);
						playedHitsound = true;
					}
					hitsoundNoteIndex = i + 1;
				}
				else
					break;
			}
		}

		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}

	override function destroy()
	{
		super.destroy();
		actionManager = FlxDestroyUtil.destroy(actionManager);
		beatSnap = FlxDestroyUtil.destroy(beatSnap);
		selectedObjects = FlxDestroyUtil.destroy(selectedObjects);
		Application.current.onExit.remove(onExit);
		FlxDestroyUtil.destroy(songSeeked);
		FlxDestroyUtil.destroy(rateChanged);
	}

	override function openSubState(subState)
	{
		inst.pause();
		vocals.pause();
		persistentUpdate = false;
		super.openSubState(subState);
	}

	public function setSongTime(time:Float = 0)
	{
		var oldTime = inst.time;
		vocals.time = inst.time = time;
		setHitsoundNoteIndex();
		songSeeked.dispatch(inst.time, oldTime);
	}

	public function setCurrentTool(tool:CompositionTool)
	{
		currentTool.value = tool;
		compositionPanel.tools.selectedId = tool;
	}

	public function setPlaybackRate(targetRate:Float)
	{
		if (targetRate <= 0 || targetRate > 2)
			return;

		var oldPitch = inst.pitch;
		inst.pitch = vocals.pitch = targetRate;
		rateChanged.dispatch(inst.pitch, oldPitch);
	}

	public function save(notif:Bool = true, forceSave:Bool = false)
	{
		if (!actionManager.hasUnsavedChanges && !forceSave)
			return;

		song.save(Path.join([song.directory, song.difficultyName + '.json']));

		if (actionManager.undoStack.length > 0)
			actionManager.lastSaveAction = actionManager.undoStack[0];

		if (notif)
			notificationManager.showNotification('Song succesfully saved!', SUCCESS);
	}

	public function getTimeFromY(y:Float)
	{
		return trackPositionY + (hitPositionY - y);
	}

	public function clearSelection()
	{
		selectedObjects.clear();
	}

	public function handleMouseSeek()
	{
		var seekTime:Float = 0;
		var startScrollY = (FlxG.height - 30);
		if (FlxG.mouse.globalY >= startScrollY && !inst.playing)
		{
			if (FlxG.mouse.globalY - startScrollY <= 10)
				seekTime = inst.time - 2;
			else if (FlxG.mouse.globalY - startScrollY <= 20)
				seekTime = inst.time - 6;
			else
				seekTime = inst.time - 50;

			if (seekTime < 0 || seekTime > inst.length)
				return;

			setSongTime(seekTime);
		}

		if (FlxG.mouse.globalY > 30 || inst.playing)
			return;

		if (30 - FlxG.mouse.globalY <= 10)
			seekTime = inst.time + 2;
		else if (30 - FlxG.mouse.globalY <= 20)
			seekTime = inst.time + 6;
		else
			seekTime = inst.time + 50;

		if (seekTime < 0 || seekTime > inst.length)
			return;

		setSongTime(seekTime);
	}

	public function openApplyOffsetPrompt()
	{
		openSubState(applyOffsetPrompt);
	}

	function handleInput()
	{
		if (!checkAllowInput())
			return;

		if (FlxG.keys.justPressed.SPACE)
		{
			if (inst.playing)
			{
				inst.pause();
				vocals.pause();
			}
			else
			{
				var wasStopped = !inst.playing;
				var lastTime = inst.time;
				inst.play();
				vocals.play();
				if (inst.time != lastTime)
					songSeeked.dispatch(inst.time, lastTime);
				if (wasStopped)
					setHitsoundNoteIndex();
			}
		}

		timeSinceLastPlayfieldZoom += FlxG.elapsed;
		var canZoom = timeSinceLastPlayfieldZoom >= 0.1;

		if (FlxG.keys.justPressed.PAGEUP)
			changeSpeed(0.05);
		else if (FlxG.keys.justPressed.PAGEDOWN)
			changeSpeed(-0.05);
		else if (FlxG.keys.pressed.PAGEUP && canZoom)
			changeSpeed(0.05);
		else if (FlxG.keys.pressed.PAGEDOWN && canZoom)
			changeSpeed(-0.05);

		if (FlxG.keys.justPressed.HOME)
			setSongTime(song.notes.length == 0 ? 0 : song.notes[0].startTime);
		if (FlxG.keys.justPressed.END)
			setSongTime(song.notes.length == 0 ? inst.length - 1 : song.notes[song.notes.length - 1].startTime);

		if (!FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.LEFT || FlxG.mouse.wheel < 0)
				handleSeeking(false);
			if (FlxG.keys.justPressed.RIGHT || FlxG.mouse.wheel > 0)
				handleSeeking(true);

			if (FlxG.keys.justPressed.UP)
				changeTool(false);
			if (FlxG.keys.justPressed.DOWN)
				changeTool(true);
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.mouse.wheel > 0 || FlxG.keys.justPressed.DOWN)
				changeBeatSnap(true);
			if (FlxG.mouse.wheel < 0 || FlxG.keys.justPressed.UP)
				changeBeatSnap(false);
		}

		if (!Settings.editorLiveMapping.value)
		{
			for (i in 0...3)
			{
				if (FlxG.keys.checkStatus(ONE + i, JUST_PRESSED))
					setCurrentTool(CompositionTool.fromIndex(i));
			}
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.MINUS)
			{
				setPlaybackRate(inst.pitch - 0.25);
				editPanel.updateRateStepper();
			}
			if (FlxG.keys.justPressed.PLUS)
			{
				setPlaybackRate(inst.pitch + 0.25);
				editPanel.updateRateStepper();
			}
		}

		if (Settings.editorLiveMapping.value && playfieldNotes.exists)
		{
			var time = inst.time;
			for (i in 0...8)
			{
				if (!FlxG.keys.checkStatus(ONE + i, JUST_PRESSED))
					continue;

				var notesAtTime:Array<NoteInfo> = [];
				for (note in song.notes)
				{
					if (note.lane == i && Std.int(note.startTime) == Std.int(time))
						notesAtTime.push(note);
				}

				if (notesAtTime.length > 0)
				{
					for (note in notesAtTime)
						actionManager.perform(new ActionRemoveObject(this, note));
				}
				else
					actionManager.addNote(i, time);
			}
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.Z)
				actionManager.undo();
			if (FlxG.keys.justPressed.Y)
				actionManager.redo();
			if (FlxG.keys.justPressed.A)
				selectAllObjects();
			if (FlxG.keys.justPressed.C)
				copySelectedObjects();
			if (FlxG.keys.justPressed.X)
				cutSelectedObjects();
			if (FlxG.keys.justPressed.V)
				pasteCopiedObjects(FlxG.keys.released.SHIFT, FlxG.keys.pressed.ALT);
			if (FlxG.keys.justPressed.H)
				flipSelectedNotes(FlxG.keys.pressed.SHIFT);
			if (FlxG.keys.justPressed.I)
				placeTimingPointOrScrollVelocity();
			if (FlxG.keys.justPressed.S)
				save();
		}

		if (FlxG.keys.justPressed.DELETE)
			deleteSelectedObjects();
		if (FlxG.keys.justPressed.ESCAPE)
			leaveEditor();
	}

	function resyncVocals()
	{
		if (Math.abs(vocals.time - inst.time) >= MusicTiming.SYNC_THRESHOLD * inst.pitch)
			vocals.time = inst.time;
	}

	function handleSeeking(forward:Bool)
	{
		var time = Song.getNearestSnapTimeFromTime(song, forward, beatSnap.value, inst.time);

		if (inst.playing)
		{
			for (i in 0...3)
				time = Song.getNearestSnapTimeFromTime(song, forward, beatSnap.value, time);
		}

		if (time < 0)
			time = 0;
		if (time > inst.length)
			time = inst.length - 100;

		trace(inst.time, time, forward);

		setSongTime(time);
	}

	function changeBeatSnap(forward:Bool)
	{
		var index = beatSnapIndex;

		if (forward)
		{
			beatSnap.value = index + 1 < availableBeatSnaps.length ? availableBeatSnaps[index + 1] : availableBeatSnaps[0];
		}
		else
		{
			beatSnap.value = index - 1 >= 0 ? availableBeatSnaps[index - 1] : availableBeatSnaps[availableBeatSnaps.length - 1];
		}

		editPanel.updateBeatSnapDropdown();
	}

	function onSongComplete()
	{
		inst.stop();
		vocals.stop();
		setSongTime();
	}

	function setHitsoundNoteIndex()
	{
		hitsoundNoteIndex = song.notes.length - 1;
		while (hitsoundNoteIndex >= 0)
		{
			if (song.notes[hitsoundNoteIndex].startTime <= inst.time)
				break;

			hitsoundNoteIndex--;
		}
		hitsoundNoteIndex++;
	}

	function changeSpeed(amount:Float)
	{
		Settings.editorScrollSpeed.value += amount;
		timeSinceLastPlayfieldZoom = 0;
		editPanel.updateSpeedStepper();
	}

	function changeTool(forward:Bool)
	{
		var index = currentTool.value.getIndex();
		if (forward)
			index++;
		else
			index--;
		if (index >= 0 && index < 3)
			setCurrentTool(CompositionTool.fromIndex(index));
	}

	function copySelectedObjects()
	{
		if (selectedObjects.value.length == 0)
			return;

		copiedObjects.resize(0);

		var orderedObjects = selectedObjects.value.copy();
		orderedObjects.sort(function(a, b) return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime));
		for (obj in orderedObjects)
			copiedObjects.push(obj);
	}

	function pasteCopiedObjects(resnapNotes:Bool, swapLanes:Bool)
	{
		if (copiedObjects.length == 0)
			return;

		var clonedObjects:Array<ITimingObject> = [];

		var lowestTime = FlxMath.MAX_VALUE_FLOAT;
		for (obj in copiedObjects)
		{
			if (obj.startTime < lowestTime)
				lowestTime = obj.startTime;
		}
		if (lowestTime == FlxMath.MAX_VALUE_FLOAT)
			lowestTime = inst.time;
		var difference = inst.time - lowestTime;

		for (obj in copiedObjects)
		{
			if (Std.isOfType(obj, NoteInfo))
			{
				var obj:NoteInfo = cast obj;
				var info = new NoteInfo({
					startTime: obj.startTime + difference,
					lane: obj.lane,
					type: obj.type,
					params: obj.params.join(',')
				});
				if (swapLanes)
				{
					if (info.lane >= 4)
						info.lane -= 4;
					else
						info.lane += 4;
				}
				if (obj.isLongNote)
					info.endTime = obj.endTime + difference;
				if (info.startTime > inst.length || info.endTime > inst.length)
					continue;
				clonedObjects.push(info);
			}
			else if (Std.isOfType(obj, CameraFocus))
			{
				var obj:CameraFocus = cast obj;
				var info = new CameraFocus({
					startTime: obj.startTime + difference,
					char: obj.char
				});
				if (info.startTime > inst.length)
					continue;
				clonedObjects.push(info);
			}
		}

		if (resnapNotes)
			new ActionResnapObjects(this, [16, 12], clonedObjects).perform();

		actionManager.perform(new ActionAddObjectBatch(this, clonedObjects));

		clearSelection();
		selectedObjects.pushMultiple(clonedObjects);
	}

	function cutSelectedObjects()
	{
		if (selectedObjects.value.length == 0)
			return;

		copySelectedObjects();
		deleteSelectedObjects();
	}

	public function deleteSelectedObjects()
	{
		if (selectedObjects.value.length == 0)
			return;

		var tpCount = 0;
		for (i in 0...selectedObjects.value.length)
		{
			if (Std.isOfType(selectedObjects.value[i], TimingPoint))
				tpCount++;
		}
		if (tpCount >= song.timingPoints.length)
		{
			notificationManager.showNotification('You must have at least 1 timing point in your map!', WARNING);
			return;
		}

		actionManager.perform(new ActionRemoveObjectBatch(this, selectedObjects.value.copy()));
	}

	function selectAllObjects()
	{
		clearSelection();
		if (playfield.type == NOTES)
			selectedObjects.pushMultiple(cast song.notes);
		else
		{
			selectedObjects.pushMultiple(cast song.timingPoints);
			selectedObjects.pushMultiple(cast song.scrollVelocities);
			selectedObjects.pushMultiple(cast song.cameraFocuses);
			selectedObjects.pushMultiple(cast song.events);
			selectedObjects.pushMultiple(cast song.lyricSteps);
		}
	}

	function flipSelectedNotes(fullFlip:Bool)
	{
		if (selectedObjects.value.length == 0)
			return;

		var notes:Array<NoteInfo> = [];
		for (obj in selectedObjects.value)
		{
			if (Std.isOfType(obj, NoteInfo))
				notes.push(cast obj);
		}
		if (notes.length == 0)
			return;

		actionManager.perform(new ActionFlipNotes(this, notes, fullFlip));
	}

	function placeTimingPointOrScrollVelocity()
	{
		if (FlxG.keys.released.SHIFT)
		{
			var place = true;
			for (sv in song.scrollVelocities)
			{
				if (sv.startTime == inst.time)
				{
					actionManager.perform(new ActionRemoveObject(this, sv));
					place = false;
				}
			}
			if (place)
			{
				var curSV = song.getScrollVelocityAt(inst.time);
				actionManager.addScrollVelocity(inst.time, curSV != null ? curSV.multipliers.copy() : [1.0, 1.0], curSV != null ? curSV.linked : true);
			}
		}
		else if (song.timingPoints.length != 0)
		{
			var place = true;
			for (point in song.timingPoints)
			{
				if (point.startTime == inst.time)
				{
					if (song.timingPoints.length > 1)
						actionManager.perform(new ActionRemoveObject(this, point));
					place = false;
				}
			}
			if (place)
			{
				var curPoint = song.getTimingPointAt(inst.time);
				actionManager.addTimingPoint(inst.time, curPoint != null ? curPoint.bpm : song.timingPoints[0].bpm,
					curPoint != null ? curPoint.meter : song.timingPoints[0].meter);
			}
		}
	}

	function leaveEditor()
	{
		inst.pause();
		vocals.pause();
		if (actionManager.hasUnsavedChanges)
			openSubState(savePrompt);
		else
			onSavePrompt('No');
	}

	function onExit(_)
	{
		if (Settings.editorSaveOnExit.value)
			save(false);
	}

	function onSavePrompt(option:String)
	{
		if (option != 'Cancel')
		{
			if (option == 'Yes')
				save();
			FlxG.switchState(new ToolboxState());
		}
	}

	function onApplyOffsetPrompt(text:String)
	{
		trace(text);
		if (text != null && text.length > 0)
		{
			var offset = Std.parseFloat(text);
			if (offset != 0 && Math.isFinite(offset))
			{
				var objects:Array<ITimingObject> = [];
				for (obj in song.notes)
					objects.push(obj);
				for (obj in song.timingPoints)
					objects.push(obj);
				for (obj in song.scrollVelocities)
					objects.push(obj);
				for (obj in song.cameraFocuses)
					objects.push(obj);
				for (obj in song.events)
					objects.push(obj);
				for (obj in song.lyricSteps)
					objects.push(obj);
				actionManager.perform(new ActionMoveObjects(this, objects, 0, offset));
			}
		}
	}

	function get_trackSpeed()
	{
		return Settings.editorScrollSpeed.value / (Settings.editorScaleSpeedWithRate.value ? inst.pitch : 1);
	}

	function get_trackPositionY()
	{
		return inst.time * trackSpeed;
	}

	function get_beatSnapIndex()
	{
		return availableBeatSnaps.indexOf(beatSnap.value);
	}

	function get_playfield()
	{
		return playfieldOther.exists ? playfieldOther : playfieldNotes;
	}
}

enum abstract CompositionTool(String) from String to String
{
	var SELECT = 'Select';
	var OBJECT = 'Add Object';
	var LONG_NOTE = 'Add Long Note';

	public function getIndex()
	{
		return switch (this)
		{
			case OBJECT: 1;
			case LONG_NOTE: 2;
			default: 0;
		}
	}

	public static function fromIndex(index:Int)
	{
		return switch (index)
		{
			case 1: OBJECT;
			case 2: LONG_NOTE;
			default: SELECT;
		}
	}
}
