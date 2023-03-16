package states.editors.song;

import data.Settings;
import data.song.NoteInfo;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import sprites.AnimatedSprite;

class SongEditorNoteGroup extends FlxBasic
{
	var state:SongEditorState;
	var notes:Array<SongEditorNote> = [];
	var notePool:Array<SongEditorNote> = [];
	var lastPooledNoteIndex:Int = -1;

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;

		for (note in state.song.notes)
			createNote(note);
		initializeNotePool();
		state.songSeeked.add(onSongSeeked);
		state.rateChanged.add(onRateChanged);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
	}

	override function update(elapsed:Float)
	{
		var i = notePool.length - 1;
		while (i >= 0)
		{
			var note = notePool[i];
			if (!note.noteOnScreen())
				notePool.remove(note);
			i--;
		}

		i = lastPooledNoteIndex + 1;
		while (i < notes.length)
		{
			var note = notes[i];
			if (note.noteOnScreen())
			{
				notePool.push(note);
				lastPooledNoteIndex = i;
			}
			i++;
		}
	}

	override function draw()
	{
		for (i in 0...notePool.length)
		{
			var note = notePool[i];
			note.updatePosition();
			note.updateLongNote();
			note.cameras = cameras;
			note.draw();
		}
	}

	override function destroy()
	{
		for (note in notes)
			note.destroy();
		super.destroy();
		state.songSeeked.remove(onSongSeeked);
		state.rateChanged.remove(onRateChanged);
		Settings.editorScrollSpeed.valueChanged.remove(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.remove(onScaleSpeedWithRateChanged);
	}

	function createNote(info:NoteInfo, insertAtIndex:Bool = false)
	{
		var note = new SongEditorNote(state, info);
		notes.push(note);
	}

	function initializeNotePool()
	{
		notePool = [];
		lastPooledNoteIndex = -1;

		for (i in 0...notes.length)
		{
			var note = notes[i];
			if (!note.noteOnScreen())
				continue;
			notePool.push(note);
			lastPooledNoteIndex = i;
		}

		if (lastPooledNoteIndex == -1)
		{
			lastPooledNoteIndex = notes.length - 1;
			while (lastPooledNoteIndex >= 0)
			{
				if (notes[lastPooledNoteIndex].info.startTime < state.inst.time)
					break;

				lastPooledNoteIndex--;
			}
		}
	}

	function refreshNotes()
	{
		resetNotePositions();
		initializeNotePool();
	}

	function resetNotePositions()
	{
		for (note in notes)
			note.refresh();
	}

	function onSongSeeked(_, _)
	{
		initializeNotePool();
	}

	function onRateChanged(_, _)
	{
		refreshNotes();
	}

	function onScrollSpeedChanged(_, _)
	{
		refreshNotes();
	}

	function onScaleSpeedWithRateChanged(_, _)
	{
		refreshNotes();
	}
}

class SongEditorNote extends FlxSpriteGroup
{
	public var info:NoteInfo;
	public var note:AnimatedSprite;
	public var body:AnimatedSprite;
	public var tail:AnimatedSprite;

	var state:SongEditorState;

	public function new(state:SongEditorState, info:NoteInfo)
	{
		super();
		this.state = state;
		this.info = info;

		var noteGraphic = Paths.getSpritesheet('notes/NOTE_assets');

		body = new AnimatedSprite(0, 0, noteGraphic);
		body.addAnim({
			name: '0',
			atlasName: 'purple hold piece instance 1',
			fps: 0
		});
		body.addAnim({
			name: '1',
			atlasName: 'blue hold piece instance 1',
			fps: 0
		});
		body.addAnim({
			name: '2',
			atlasName: 'green hold piece instance 1',
			fps: 0
		});
		body.addAnim({
			name: '3',
			atlasName: 'red hold piece instance 1',
			fps: 0
		});
		body.flipY = true;
		body.antialiasing = false;
		add(body);

		tail = new AnimatedSprite(0, 0, noteGraphic);
		tail.addAnim({
			name: '0',
			atlasName: 'pruple end hold instance 1',
			fps: 0
		});
		tail.addAnim({
			name: '1',
			atlasName: 'blue hold end instance 1',
			fps: 0
		});
		tail.addAnim({
			name: '2',
			atlasName: 'green hold end instance 1',
			fps: 0
		});
		tail.addAnim({
			name: '3',
			atlasName: 'red hold end instance 1',
			fps: 0
		});
		tail.flipY = true;
		add(tail);

		note = new AnimatedSprite(0, 0, noteGraphic);
		note.addAnim({
			name: '0',
			atlasName: 'purple instance 1',
			fps: 0
		});
		note.addAnim({
			name: '1',
			atlasName: 'blue instance 1',
			fps: 0
		});
		note.addAnim({
			name: '2',
			atlasName: 'green instance 1',
			fps: 0
		});
		note.addAnim({
			name: '3',
			atlasName: 'red instance 1',
			fps: 0
		});
		add(note);

		refresh();
	}

	override function draw()
	{
		if (info.isLongNote)
		{
			body.draw();
			tail.draw();
		}
		note.draw();
	}

	public function updateAnims()
	{
		var anim = Std.string(info.playerLane);
		note.playAnim(anim);

		if (!info.isLongNote)
			return;

		body.playAnim(anim);
		tail.playAnim(anim);
	}

	public function updatePosition()
	{
		var x = state.playfieldBG.x + state.columnSize * info.lane + state.borderLeft.width;
		var y = state.hitPositionY - info.startTime * state.trackSpeed - note.height;

		if (this.x != x || this.y != y)
			setPosition(x, y);
	}

	public function updateSize()
	{
		note.setGraphicSize(Std.int(state.columnSize - state.borderLeft.width * 2));
		note.updateHitbox();
	}

	public function updateLongNote()
	{
		if (!info.isLongNote)
			return;

		body.setGraphicSize(Std.int(body.frameWidth * note.scale.x), getLongNoteHeight());
		body.updateHitbox();
		body.x = note.x + (note.width / 2) - (body.width / 2);
		body.y = note.y + (-body.height + note.height / 2);
		tail.scale.copyFrom(note.scale);
		tail.updateHitbox();
		tail.x = note.x + (note.width / 2) - (tail.width / 2);
		tail.y = body.y - tail.height;
	}

	public function refresh()
	{
		updateAnims();
		updatePosition();
		updateSize();
		updateLongNote();
	}

	public function noteOnScreen()
	{
		if (info.startTime * state.trackSpeed >= state.trackPositionY - state.playfieldBG.height
			&& info.startTime * state.trackSpeed <= state.trackPositionY + state.playfieldBG.height)
			return true;

		if (state.inst.time >= info.startTime && state.inst.time <= info.endTime + 1000)
			return true;

		return false;
	}

	function getLongNoteHeight()
	{
		if (!info.isLongNote)
			return 0;

		return Std.int(Math.abs(state.hitPositionY
			- info.endTime * state.trackSpeed
			- ((state.columnSize * tail.frameHeight) / tail.frameWidth) / 2
			- note.height / 2
			- y));
	}
}
