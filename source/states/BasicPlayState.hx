package states;

import data.skin.NoteSkin;
import data.song.Song;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import ui.Playfield;
import util.AudioTiming;

/**
	A basic PlayState, includes just the playfields.
**/
class BasicPlayState extends FNFState
{
	/**
		The current song file.
	**/
	public var song:Song;

	/**
		Whether the game is currently paused.
	**/
	public var isPaused:Bool = false;

	/**
		Whether the song has started playing.
	**/
	public var hasStarted:Bool = false;

	var camHUD:FlxCamera;
	var playfields:FlxTypedGroup<Playfield>;
	var timing:AudioTiming;
	var songInst:FlxSound;
	var songVocals:FlxSound;

	public function new(song:Song)
	{
		super();
		this.song = song;
	}

	override public function create()
	{
		songInst = FlxG.sound.load(Paths.getSongInst(song));
		songInst.onComplete = endSong;
		songVocals = FlxG.sound.load(Paths.getSongVocals(song));
		timing = new AudioTiming(this, songInst, [songVocals], Std.int(song.timingPoints[0].beatLength * 5));

		initCameras();

		initPlayfields();

		super.create();
	}

	override public function update(elapsed:Float)
	{
		timing.update(elapsed);

		super.update(elapsed);

		FlxG.watch.addQuick('Song Time', timing.time);
	}

	/**
		Called by the timing object once the music has started playing.
	**/
	public function startSong()
	{
		hasStarted = true;
	}

	function initCameras()
	{
		FlxG.camera.bgColor = FlxColor.GRAY;

		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);
	}

	function initPlayfields()
	{
		var skin = new NoteSkin({
			receptors: [
				{
					staticAnim: 'arrow static instance 1',
					pressedAnim: 'left press',
					confirmAnim: 'left confirm'
				},
				{
					staticAnim: 'arrow static instance 2',
					pressedAnim: 'down press',
					confirmAnim: 'down confirm'
				},
				{
					staticAnim: 'arrow static instance 4',
					pressedAnim: 'up press',
					confirmAnim: 'up confirm'
				},
				{
					staticAnim: 'arrow static instance 3',
					pressedAnim: 'right press',
					confirmAnim: 'right confirm'
				}
			],
			receptorsCenterAnimation: true,
			receptorsImage: 'NOTE_assets',
			receptorsOffset: [0, 5],
			receptorsPadding: 0,
			receptorsScale: 0.5,
			antialiasing: true
		});

		playfields = new FlxTypedGroup();
		playfields.cameras = [camHUD];
		add(playfields);

		createPlayfield(0, skin);
		createPlayfield(1, skin);
	}

	function createPlayfield(player:Int = 0, ?skin:NoteSkin)
	{
		var playfield = new Playfield(player, skin);
		playfields.add(playfield);
		return playfield;
	}

	function endSong()
	{
		timing.stopMusic();
	}
}
