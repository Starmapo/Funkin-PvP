package states.editors.song;

import data.Settings;
import data.song.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import util.MusicTiming;
import util.bindable.BindableInt;

class SongEditorState extends FNFState
{
	public var columnSize:Int = 80;
	public var hitPositionY:Int = 545;
	public var beatSnap:BindableInt = new BindableInt(4, 1, 48);
	public var trackSpeed(get, never):Float;
	public var playfieldBG:FlxSprite;
	public var trackPositionY(get, never):Float;
	public var song:Song;
	public var inst:FlxSound;
	public var vocals:FlxSound;

	var actionManager:SongEditorActionManager;
	var borderLeft:FlxSprite;
	var borderRight:FlxSprite;
	var dividerLines:FlxTypedGroup<FlxSprite>;
	var hitPositionLine:FlxSprite;
	var timeline:SongEditorTimeline;
	var timeSinceLastPlayfieldZoom:Float = 0;

	override function create()
	{
		song = Song.loadSong('mods/fnf/songs/Bopeebo/Hard.json');
		inst = FlxG.sound.load(Paths.getSongInst(song), 1, false, FlxG.sound.defaultMusicGroup);
		vocals = FlxG.sound.load(Paths.getSongVocals(song), 1, false, FlxG.sound.defaultMusicGroup);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;
		add(bg);

		playfieldBG = new FlxSprite().makeGraphic(columnSize * 4, FlxG.height, FlxColor.fromRGB(24, 24, 24));
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
		for (i in 0...3)
		{
			var dividerLine = new FlxSprite(playfieldBG.x + (columnSize * (i + 1))).makeGraphic(2, Std.int(playfieldBG.height), FlxColor.WHITE);
			dividerLine.alpha = 0.35;
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

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
		actionManager = FlxDestroyUtil.destroy(actionManager);
		beatSnap = FlxDestroyUtil.destroy(beatSnap);
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
				inst.resume();
				vocals.resume();
			}
		}

		timeSinceLastPlayfieldZoom += FlxG.elapsed;
		var canZoom = timeSinceLastPlayfieldZoom >= 0.1;

		if (FlxG.keys.justPressed.PAGEUP)
		{
			Settings.editorScrollSpeed.value++;
		}
		else if (FlxG.keys.justPressed.PAGEDOWN)
		{
			Settings.editorScrollSpeed.value--;
		}
		else if (FlxG.keys.pressed.PAGEUP && canZoom)
		{
			Settings.editorScrollSpeed.value++;
			timeSinceLastPlayfieldZoom = 0;
		}
		else if (FlxG.keys.pressed.PAGEDOWN && canZoom)
		{
			Settings.editorScrollSpeed.value--;
			timeSinceLastPlayfieldZoom = 0;
		}

		if (FlxG.keys.justPressed.HOME)
		{
			var time:Float = song.notes.length == 0 ? 0 : song.notes[0].startTime;
			setSongTime(time);
		}
		if (FlxG.keys.justPressed.END)
		{
			var time:Float = song.notes.length == 0 ? inst.length - 1 : song.notes[song.notes.length - 1].startTime;
			setSongTime(time);
		}

		if (FlxG.keys.justPressed.LEFT || FlxG.mouse.wheel < 0)
		{
			handleSeeking(false);
		}
		if (FlxG.keys.justPressed.RIGHT || FlxG.mouse.wheel > 0)
		{
			handleSeeking(true);
		}
	}

	function resyncVocals()
	{
		var timeOutOfThreshold = Math.abs(vocals.time - inst.time) >= MusicTiming.SYNC_THRESHOLD * inst.pitch;
		if (timeOutOfThreshold)
		{
			FlxG.log.notice('Resynced vocals with difference of ' + Math.abs(inst.time - inst.time));
			vocals.time = inst.time;
		}
	}

	function setSongTime(time:Float)
	{
		vocals.time = inst.time = time;
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

	function get_trackSpeed()
	{
		return Settings.editorScrollSpeed.value / (Settings.editorScaleSpeedWithRate.value ? 20 * inst.pitch : 20);
	}

	function get_trackPositionY()
	{
		return inst.time * trackSpeed;
	}
}
