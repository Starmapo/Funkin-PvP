package states.editors.song;

import data.Settings;
import data.song.NoteInfo;
import data.song.Song;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.io.Path;
import states.editors.song.SongEditorWaveform.WaveformType;
import ui.editors.NotificationManager;
import ui.editors.Tooltip;
import util.MusicTiming;
import util.bindable.BindableArray;
import util.bindable.BindableInt;

class SongEditorState extends FNFState
{
	public var columns:Int = 11;
	public var columnSize:Int = 40;
	public var hitPositionY:Int = 545;
	public var beatSnap:BindableInt = new BindableInt(4, 1, 48);
	public var trackSpeed(get, never):Float;
	public var playfieldBG:FlxSprite;
	public var trackPositionY(get, never):Float;
	public var song:Song;
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var availableBeatSnaps:Array<Int> = [1, 2, 3, 4, 6, 8, 12, 16];
	public var songSeeked:FlxTypedSignal<Float->Float->Void> = new FlxTypedSignal();
	public var rateChanged:FlxTypedSignal<Float->Float->Void> = new FlxTypedSignal();
	public var borderLeft:FlxSprite;
	public var borderRight:FlxSprite;
	public var currentTool:CompositionTool = SELECT;
	public var notificationManager:NotificationManager;
	public var tooltip:Tooltip;
	public var waveform:SongEditorWaveform;
	public var noteGroup:SongEditorNoteGroup;
	public var selectedNotes:BindableArray<NoteInfo> = new BindableArray([]);
	public var seekBar:SongEditorSeekBar;
	public var zoomInButton:FlxUIButton;
	public var zoomOutButton:FlxUIButton;

	var actionManager:SongEditorActionManager;
	var dividerLines:FlxTypedGroup<FlxSprite>;
	var hitPositionLine:FlxSprite;
	var timeline:SongEditorTimeline;
	var timeSinceLastPlayfieldZoom:Float = 0;
	var beatSnapIndex(get, never):Int;
	var lineGroup:SongEditorLineGroup;
	var detailsPanel:SongEditorDetailsPanel;
	var compositionPanel:SongEditorCompositionPanel;
	var editPanel:SongEditorEditPanel;
	var hitsoundNoteIndex:Int = 0;
	var camHUD:FlxCamera;
	var selector:SongEditorSelector;

	override function create()
	{
		persistentUpdate = true;

		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);

		song = Song.loadSong('mods/fnf/songs/Bopeebo/Hard.json');
		inst = FlxG.sound.load(Paths.getSongInst(song), 1, false, FlxG.sound.defaultMusicGroup);
		inst.onComplete = onSongComplete;
		vocals = FlxG.sound.load(Paths.getSongVocals(song), 1, false, FlxG.sound.defaultMusicGroup);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;

		playfieldBG = new FlxSprite().makeGraphic(columnSize * columns, FlxG.height, FlxColor.fromRGB(24, 24, 24));
		playfieldBG.screenCenter(X);
		playfieldBG.scrollFactor.set();

		borderLeft = new FlxSprite(playfieldBG.x).makeGraphic(2, Std.int(playfieldBG.height), 0xFF808080);
		borderLeft.scrollFactor.set();

		borderRight = new FlxSprite(playfieldBG.x + playfieldBG.width).makeGraphic(2, Std.int(playfieldBG.height), 0xFF808080);
		borderRight.x -= borderRight.width;
		borderRight.scrollFactor.set();

		dividerLines = new FlxTypedGroup();
		for (i in 1...columns)
		{
			var thickDivider = i == 4 || i == 8;
			var dividerLine = new FlxSprite(playfieldBG.x + (columnSize * i)).makeGraphic(2, Std.int(playfieldBG.height), FlxColor.WHITE);
			dividerLine.alpha = thickDivider ? 0.7 : 0.35;
			dividerLine.scrollFactor.set();
			dividerLines.add(dividerLine);
		}

		hitPositionLine = new FlxSprite(0, hitPositionY).makeGraphic(Std.int(playfieldBG.width - borderLeft.width * 2), 6, FlxColor.fromRGB(9, 165, 200));
		hitPositionLine.screenCenter(X);
		hitPositionLine.scrollFactor.set();

		timeline = new SongEditorTimeline(this);

		waveform = new SongEditorWaveform(this);

		lineGroup = new SongEditorLineGroup(this);

		noteGroup = new SongEditorNoteGroup(this);

		seekBar = new SongEditorSeekBar(this);

		selector = new SongEditorSelector(this);

		tooltip = new Tooltip();
		tooltip.cameras = [camHUD];

		zoomInButton = new FlxUIButton(playfieldBG.x + playfieldBG.width + 10, 10, '+', function()
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

		detailsPanel = new SongEditorDetailsPanel(this);

		compositionPanel = new SongEditorCompositionPanel(this);

		editPanel = new SongEditorEditPanel(this);

		notificationManager = new NotificationManager();

		actionManager = new SongEditorActionManager(this);

		add(bg);
		add(playfieldBG);
		add(borderLeft);
		add(borderRight);
		add(dividerLines);
		add(hitPositionLine);
		add(timeline);
		add(waveform);
		add(lineGroup);
		add(noteGroup);
		add(seekBar);
		add(selector);
		add(zoomInButton);
		add(zoomOutButton);
		add(detailsPanel);
		add(compositionPanel);
		add(editPanel);
		add(notificationManager);
		add(tooltip);

		inst.play();
		vocals.play();

		setHitsoundNoteIndex();

		super.create();
	}

	override function update(elapsed:Float)
	{
		handleInput();

		selector.update(elapsed);
		seekBar.update(elapsed);
		zoomInButton.update(elapsed);
		zoomOutButton.update(elapsed);
		compositionPanel.update(elapsed);
		editPanel.update(elapsed);
		detailsPanel.update(elapsed);
		notificationManager.update(elapsed);
		tooltip.update(elapsed);

		FlxG.camera.scroll.y = -trackPositionY;

		resyncVocals();

		if (inst.playing && Settings.editorHitsoundVolume.value > 0)
		{
			for (i in hitsoundNoteIndex...song.notes.length)
			{
				var note = song.notes[i];
				if (inst.time >= note.startTime)
				{
					FlxG.sound.play(Paths.getSound('editor/hitsound'), Settings.editorHitsoundVolume.value);
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
		selectedNotes = FlxDestroyUtil.destroy(selectedNotes);
		FlxDestroyUtil.destroy(songSeeked);
		FlxDestroyUtil.destroy(rateChanged);
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
		currentTool = tool;
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

	public function save()
	{
		song.save(Path.join([song.directory, song.difficultyName + '.json']));
		notificationManager.showNotification('Song succesfully saved!');
	}

	public function getLaneFromX(x:Float)
	{
		var percentage = (x - playfieldBG.x) / playfieldBG.width;
		return FlxMath.boundInt(Std.int(columns * percentage), 0, columns);
	}

	public function getTimeFromY(y:Float)
	{
		return trackPositionY + (hitPositionY - y);
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
				{
					songSeeked.dispatch(inst.time, lastTime);
				}
				if (wasStopped)
				{
					setHitsoundNoteIndex();
				}
			}
		}

		timeSinceLastPlayfieldZoom += FlxG.elapsed;
		var canZoom = timeSinceLastPlayfieldZoom >= 0.1;

		if (FlxG.keys.justPressed.PAGEUP)
		{
			changeSpeed(0.05);
		}
		else if (FlxG.keys.justPressed.PAGEDOWN)
		{
			changeSpeed(-0.05);
		}
		else if (FlxG.keys.pressed.PAGEUP && canZoom)
		{
			changeSpeed(0.05);
		}
		else if (FlxG.keys.pressed.PAGEDOWN && canZoom)
		{
			changeSpeed(-0.05);
		}

		if (FlxG.keys.justPressed.HOME)
		{
			setSongTime(song.notes.length == 0 ? 0 : song.notes[0].startTime);
		}
		if (FlxG.keys.justPressed.END)
		{
			setSongTime(song.notes.length == 0 ? inst.length - 1 : song.notes[song.notes.length - 1].startTime);
		}

		if (!FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.LEFT || FlxG.mouse.wheel < 0)
			{
				handleSeeking(false);
			}
			if (FlxG.keys.justPressed.RIGHT || FlxG.mouse.wheel > 0)
			{
				handleSeeking(true);
			}
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.mouse.wheel > 0 || FlxG.keys.justPressed.DOWN)
			{
				changeBeatSnap(true);
			}
			if (FlxG.mouse.wheel < 0 || FlxG.keys.justPressed.UP)
			{
				changeBeatSnap(false);
			}
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
	}

	function resyncVocals()
	{
		if (Math.abs(vocals.time - inst.time) >= MusicTiming.SYNC_THRESHOLD * inst.pitch)
		{
			vocals.time = inst.time;
		}
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
}

enum abstract CompositionTool(String) from String to String
{
	var SELECT = 'Select';
	var NOTE = 'Note';
	var LONG_NOTE = 'Long Note';
}
