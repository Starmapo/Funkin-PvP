package states.editors;

import backend.MusicTiming;
import backend.bindable.Bindable;
import backend.bindable.BindableArray;
import backend.bindable.BindableInt;
import backend.editors.song.SongEditorActionManager;
import backend.editors.song.SongEditorMetronome;
import backend.structures.song.CameraFocus;
import backend.structures.song.EventObject;
import backend.structures.song.ITimingObject;
import backend.structures.song.LyricStep;
import backend.structures.song.NoteInfo;
import backend.structures.song.ScrollVelocity;
import backend.structures.song.Song;
import backend.structures.song.TimingPoint;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSort;
import haxe.io.Path;
import lime.app.Application;
import objects.editors.Tooltip;
import objects.editors.song.SongEditorCamFocusDisplay;
import objects.editors.song.SongEditorCompositionPanel;
import objects.editors.song.SongEditorDetailsPanel;
import objects.editors.song.SongEditorEditPanel;
import objects.editors.song.SongEditorLyricsDisplay;
import objects.editors.song.SongEditorPlayfield;
import objects.editors.song.SongEditorPlayfieldTabs;
import objects.editors.song.SongEditorSeekBar;
import objects.editors.song.SongEditorSelector;
import objects.game.LyricsDisplay;
import subStates.editors.song.SongEditorSavePrompt;
import sys.io.File;

class SongEditorState extends FNFState
{
	public static var toPlayState:Bool = false;
	
	static var globalSong:Song;
	
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
	public var lyrics:String;
	public var lyricsDisplay:SongEditorLyricsDisplay;
	
	var timeSinceLastPlayfieldZoom:Float = 0;
	var beatSnapIndex(get, never):Int;
	var hitsoundNoteIndex:Int = 0;
	var camHUD:FlxCamera;
	var savePrompt:SongEditorSavePrompt;
	var camFocusDisplay:SongEditorCamFocusDisplay;
	var metronome:SongEditorMetronome;
	var time:Float = 0;
	var lastLyrics:String;
	
	public function new(?song:Song, time:Float = 0, ?toPlayState:Bool)
	{
		super();
		if (globalSong == null)
			globalSong = Song.loadSong('Tutorial/Hard', 'fnf');
			
		if (song == null)
			song = globalSong;
		else
			globalSong = song;
		this.song = song;
		this.time = time;
		if (toPlayState != null)
			SongEditorState.toPlayState = toPlayState;
	}
	
	override function destroy()
	{
		super.destroy();
		playfieldNotes = null;
		playfieldOther = null;
		beatSnap = FlxDestroyUtil.destroy(beatSnap);
		song = null;
		inst = FlxDestroyUtil.destroy(inst);
		vocals = FlxDestroyUtil.destroy(vocals);
		availableBeatSnaps = null;
		FlxDestroyUtil.destroy(songSeeked);
		FlxDestroyUtil.destroy(rateChanged);
		FlxDestroyUtil.destroy(currentTool);
		tooltip = null;
		selectedObjects = FlxDestroyUtil.destroy(selectedObjects);
		seekBar = null;
		zoomInButton = null;
		zoomOutButton = null;
		detailsPanel = null;
		compositionPanel = null;
		editPanel = null;
		actionManager = FlxDestroyUtil.destroy(actionManager);
		copiedObjects = null;
		playfieldTabs = null;
		selector = null;
		lyricsDisplay = null;
		camHUD = null;
		savePrompt = FlxDestroyUtil.destroy(savePrompt);
		camFocusDisplay = null;
		metronome = FlxDestroyUtil.destroy(metronome);
		Application.current.onExit.remove(onExit);
		Mods.currentMod = '';
	}
	
	override function create()
	{
		updatePresence();
		
		persistentUpdate = true;
		destroySubStates = false;
		checkObjects = true;
		Mods.currentMod = 'fnf';
		
		actionManager = new SongEditorActionManager(this);
		
		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);
		
		inst = FlxG.sound.load(Paths.getSongInst(song), Settings.editorInstVolume.value, false, FlxG.sound.defaultMusicGroup);
		if (inst == null)
			inst = new FlxSound();
		inst.onComplete = onSongComplete;
		
		var vocalsSound = Paths.getSongVocals(song);
		if (vocalsSound != null)
			vocals = FlxG.sound.load(vocalsSound, Settings.editorVocalsVolume.value, false, FlxG.sound.defaultMusicGroup);
		else
			vocals = new FlxSound();
			
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
		
		lastLyrics = lyrics = Song.getSongLyrics(song);
		
		lyricsDisplay = new SongEditorLyricsDisplay(this);
		
		metronome = new SongEditorMetronome(this);
		
		detailsPanel = new SongEditorDetailsPanel(this);
		
		compositionPanel = new SongEditorCompositionPanel(this);
		
		editPanel = new SongEditorEditPanel(this);
		
		savePrompt = new SongEditorSavePrompt(onSavePrompt);
		
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
		add(lyricsDisplay);
		add(tooltip);
		
		setSongTime(time);
		
		Application.current.onExit.add(onExit);
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		handleInput(elapsed);
		
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
		lyricsDisplay.updateLyrics(inst.time);
		tooltip.update(elapsed);
		
		FlxG.camera.scroll.y = -trackPositionY;
		
		resyncVocals();
		
		if (inst.playing)
		{
			var playedNote = [false, false];
			for (i in hitsoundNoteIndex...song.notes.length)
			{
				var note = song.notes[i];
				if (inst.time >= note.startTime)
				{
					if (Settings.editorHitsoundVolume.value > 0
						&& !playedNote[note.player]
						&& ((note.player == 0 && Settings.editorOpponentHitsounds.value)
							|| (note.player == 1 && Settings.editorBFHitsounds.value)))
					{
						FlxG.sound.play(Paths.getSound('editor/hitsound'), Settings.editorHitsoundVolume.value).pan = (note.player == 0 ? -1 : 1);
						playedNote[note.player] = true;
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
		if (lyrics != lastLyrics)
		{
			File.saveContent(Song.getSongLyricsPath(song), lyrics);
			lastLyrics = lyrics;
		}
		
		actionManager.lastSaveAction = actionManager.undoStack[0];
		
		if (notif)
			Main.showNotification('Song successfully saved!', SUCCESS);
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
		if (FlxG.mouse.screenY >= startScrollY && !inst.playing)
		{
			if (FlxG.mouse.screenY - startScrollY <= 10)
				seekTime = inst.time - 2;
			else if (FlxG.mouse.screenY - startScrollY <= 20)
				seekTime = inst.time - 6;
			else
				seekTime = inst.time - 50;
				
			if (seekTime < 0 || seekTime > inst.length)
				return;
				
			setSongTime(seekTime);
		}
		
		if (FlxG.mouse.screenY > 30 || inst.playing)
			return;
			
		if (30 - FlxG.mouse.screenY <= 10)
			seekTime = inst.time + 2;
		else if (30 - FlxG.mouse.screenY <= 20)
			seekTime = inst.time + 6;
		else
			seekTime = inst.time + 50;
			
		if (seekTime < 0 || seekTime > inst.length)
			return;
			
		setSongTime(seekTime);
	}
	
	public function exitToTestPlay(player:Int, fromStart:Bool = false)
	{
		inst.pause();
		vocals.pause();
		
		var time = fromStart ? 0 : inst.time;
		
		var hasNote = false;
		for (note in song.notes)
		{
			if (note.startTime >= time)
			{
				hasNote = true;
				break;
			}
		}
		if (!hasNote)
		{
			Main.showNotification("There aren't any notes to play past this point!", ERROR);
			return;
		}
		
		if (song.timingPoints.length == 0)
		{
			Main.showNotification("A timing point must be added to your map before test playing!", ERROR);
			return;
		}
		
		save();
		persistentUpdate = false;
		FlxG.switchState(new SongEditorPlayState(song, player, time, inst.time));
	}
	
	public function updatePresence()
	{
		DiscordClient.changePresence(song.name + " [" + song.difficultyName + "]", "Song Editor");
	}
	
	function handleInput(elapsed:Float)
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
				inst.play(false, inst.time);
				vocals.play(false, inst.time);
				if (inst.time != lastTime)
					songSeeked.dispatch(inst.time, lastTime);
				if (wasStopped)
					setHitsoundNoteIndex();
			}
		}
		
		timeSinceLastPlayfieldZoom += elapsed;
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
			setSongTime((song.notes.length == 0 || FlxG.keys.pressed.SHIFT) ? 0 : song.notes[0].startTime);
		if (FlxG.keys.justPressed.END)
			setSongTime((song.notes.length == 0 || FlxG.keys.pressed.SHIFT) ? inst.length - 1 : song.notes[song.notes.length - 1].startTime);
			
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
		if (FlxG.keys.justPressed.TAB)
			playfieldTabs.onTabEvent(playfieldNotes.exists ? 'Other' : 'Notes');
			
		if (FlxG.keys.justPressed.F1)
			exitToTestPlay(0);
		else if (FlxG.keys.justPressed.F2)
			exitToTestPlay(1);
		else if (FlxG.keys.justPressed.ESCAPE)
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
			
		setSongTime(time);
	}
	
	function changeBeatSnap(forward:Bool)
	{
		var index = beatSnapIndex;
		
		if (forward)
			beatSnap.value = index + 1 < availableBeatSnaps.length ? availableBeatSnaps[index + 1] : availableBeatSnaps[0];
		else
			beatSnap.value = index - 1 >= 0 ? availableBeatSnaps[index - 1] : availableBeatSnaps[availableBeatSnaps.length - 1];
			
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
			else if (Std.isOfType(obj, TimingPoint))
			{
				var obj:TimingPoint = cast obj;
				var info = new TimingPoint({
					startTime: obj.startTime + difference,
					bpm: obj.bpm,
					meter: obj.meter
				});
				if (info.startTime > inst.length)
					continue;
				clonedObjects.push(info);
			}
			else if (Std.isOfType(obj, ScrollVelocity))
			{
				var obj:ScrollVelocity = cast obj;
				var info = new ScrollVelocity({
					startTime: obj.startTime + difference,
					multipliers: obj.multipliers.copy(),
					linked: obj.linked
				});
				if (info.startTime > inst.length)
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
			else if (Std.isOfType(obj, EventObject))
			{
				var obj:EventObject = cast obj;
				var subEvents:Array<Event> = [];
				for (event in obj.events)
					subEvents.push(new Event({event: event.event, params: event.params.join(',')}));
				var info = new EventObject({
					startTime: obj.startTime + difference,
					events: subEvents
				});
				if (info.startTime > inst.length)
					continue;
				clonedObjects.push(info);
			}
			else if (Std.isOfType(obj, LyricStep))
			{
				var obj:LyricStep = cast obj;
				var info = new LyricStep({
					startTime: obj.startTime + difference
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
			Main.showNotification('You must have at least 1 timing point in your map!', ERROR);
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
			persistentUpdate = false;
			Paths.clearCache = true;
			if (toPlayState)
				FlxG.switchState(new PlayState(song));
			else
				FlxG.switchState(new ToolboxState());
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
