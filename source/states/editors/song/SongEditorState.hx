package states.editors.song;

import data.Settings;
import data.song.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import util.MusicTiming;
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

	var actionManager:SongEditorActionManager;
	var dividerLines:FlxTypedGroup<FlxSprite>;
	var hitPositionLine:FlxSprite;
	var timeline:SongEditorTimeline;
	var timeSinceLastPlayfieldZoom:Float = 0;
	var beatSnapIndex(get, never):Int;
	var waveform:SongEditorWaveform;
	var lineGroup:SongEditorLineGroup;
	var noteGroup:SongEditorNoteGroup;
	var seekBar:SongEditorSeekBar;
	var zoomInButton:FlxUIButton;
	var zoomOutButton:FlxUIButton;
	var detailsPanel:SongEditorDetailsPanel;

	override function create()
	{
		persistentUpdate = true;

		song = Song.loadSong('mods/fnf/songs/Bopeebo/Hard.json');
		inst = FlxG.sound.load(Paths.getSongInst(song), 1, false, FlxG.sound.defaultMusicGroup);
		inst.onComplete = onSongComplete;
		vocals = FlxG.sound.load(Paths.getSongVocals(song), 1, false, FlxG.sound.defaultMusicGroup);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;
		add(bg);

		playfieldBG = new FlxSprite().makeGraphic(columnSize * columns, FlxG.height, FlxColor.fromRGB(24, 24, 24));
		playfieldBG.screenCenter(X);
		playfieldBG.scrollFactor.set();
		add(playfieldBG);

		borderLeft = new FlxSprite(playfieldBG.x).makeGraphic(2, Std.int(playfieldBG.height), 0xFF808080);
		borderLeft.scrollFactor.set();
		add(borderLeft);

		borderRight = new FlxSprite(playfieldBG.x + playfieldBG.width).makeGraphic(2, Std.int(playfieldBG.height), 0xFF808080);
		borderRight.x -= borderRight.width;
		borderRight.scrollFactor.set();
		add(borderRight);

		dividerLines = new FlxTypedGroup();
		for (i in 1...columns)
		{
			var thickDivider = i == 4 || i == 8;
			var dividerLine = new FlxSprite(playfieldBG.x + (columnSize * i)).makeGraphic(2, Std.int(playfieldBG.height), FlxColor.WHITE);
			dividerLine.alpha = thickDivider ? 0.7 : 0.35;
			dividerLine.scrollFactor.set();
			dividerLines.add(dividerLine);
		}
		add(dividerLines);

		hitPositionLine = new FlxSprite(0, hitPositionY).makeGraphic(Std.int(playfieldBG.width - borderLeft.width * 2), 6, FlxColor.fromRGB(9, 165, 200));
		hitPositionLine.screenCenter(X);
		hitPositionLine.scrollFactor.set();
		add(hitPositionLine);

		timeline = new SongEditorTimeline(this);
		add(timeline);

		waveform = new SongEditorWaveform(this);
		add(waveform);

		lineGroup = new SongEditorLineGroup(this);
		add(lineGroup);

		noteGroup = new SongEditorNoteGroup(this);
		add(noteGroup);

		seekBar = new SongEditorSeekBar(this);
		add(seekBar);

		zoomInButton = new FlxUIButton(playfieldBG.x + playfieldBG.width + 10, 10, '+', function()
		{
			Settings.editorScrollSpeed.value += 0.05;
		});
		zoomInButton.resize(26, 26);
		zoomInButton.label.size = 16;
		for (point in zoomInButton.labelOffsets)
			point.add(1, 1);
		zoomInButton.autoCenterLabel();
		add(zoomInButton);

		zoomOutButton = new FlxUIButton(zoomInButton.x, zoomInButton.y + zoomInButton.height + 4, '-', function()
		{
			Settings.editorScrollSpeed.value -= 0.05;
		});
		zoomOutButton.resize(26, 26);
		zoomOutButton.label.size = 16;
		for (point in zoomOutButton.labelOffsets)
			point.add(1, 1);
		zoomOutButton.autoCenterLabel();
		add(zoomOutButton);

		detailsPanel = new SongEditorDetailsPanel(this);
		add(detailsPanel);

		actionManager = new SongEditorActionManager(this);

		inst.play();
		vocals.play();

		super.create();
	}

	override function update(elapsed:Float)
	{
		handleInput();

		resyncVocals();

		FlxG.camera.scroll.y = -trackPositionY;

		// first update things that might cause a song position change, scroll speed change, etc.
		seekBar.update(elapsed);
		zoomInButton.update(elapsed);
		zoomOutButton.update(elapsed);
		detailsPanel.update(elapsed);
		// now the rest of the stuff
		timeline.update(elapsed);
		waveform.update(elapsed);
		lineGroup.update(elapsed);
		noteGroup.update(elapsed);

		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}

	override function destroy()
	{
		super.destroy();
		actionManager = FlxDestroyUtil.destroy(actionManager);
		beatSnap = FlxDestroyUtil.destroy(beatSnap);
		FlxDestroyUtil.destroy(songSeeked);
	}

	public function setSongTime(time:Float = 0)
	{
		var oldTime = inst.time;
		vocals.time = inst.time = time;
		songSeeked.dispatch(inst.time, oldTime);
	}

	function handleInput()
	{
		if (FlxG.keys.justPressed.SPACE)
		{
			if (inst.playing)
			{
				inst.pause();
				vocals.pause();
			}
			else
			{
				var lastTime = inst.time;
				inst.play();
				vocals.play();
				if (inst.time != lastTime)
				{
					songSeeked.dispatch(inst.time, lastTime);
				}
			}
		}

		timeSinceLastPlayfieldZoom += FlxG.elapsed;
		var canZoom = timeSinceLastPlayfieldZoom >= 0.1;

		if (FlxG.keys.justPressed.PAGEUP)
		{
			Settings.editorScrollSpeed.value += 0.05;
			timeSinceLastPlayfieldZoom = 0;
		}
		else if (FlxG.keys.justPressed.PAGEDOWN)
		{
			Settings.editorScrollSpeed.value -= 0.05;
			timeSinceLastPlayfieldZoom = 0;
		}
		else if (FlxG.keys.pressed.PAGEUP && canZoom)
		{
			Settings.editorScrollSpeed.value += 0.05;
			timeSinceLastPlayfieldZoom = 0;
		}
		else if (FlxG.keys.pressed.PAGEDOWN && canZoom)
		{
			Settings.editorScrollSpeed.value -= 0.05;
			timeSinceLastPlayfieldZoom = 0;
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
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.MINUS)
			{
				changePlaybackRate(false);
			}
			if (FlxG.keys.justPressed.PLUS)
			{
				changePlaybackRate(true);
			}
		}
	}

	function resyncVocals()
	{
		var timeOutOfThreshold = Math.abs(vocals.time - inst.time) >= MusicTiming.SYNC_THRESHOLD * inst.pitch;
		if (timeOutOfThreshold)
		{
			FlxG.log.notice('Resynced vocals with difference of ' + Math.abs(vocals.time - inst.time));
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
	}

	function changePlaybackRate(forward:Bool)
	{
		var targetRate:Float = inst.pitch + (forward ? 0.25 : -0.25);
		if (targetRate <= 0 || targetRate > 2)
			return;

		var oldPitch = inst.pitch;
		inst.pitch = vocals.pitch = targetRate;
		rateChanged.dispatch(inst.pitch, oldPitch);
	}

	function onSongComplete()
	{
		inst.stop();
		vocals.stop();
		setSongTime();
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
