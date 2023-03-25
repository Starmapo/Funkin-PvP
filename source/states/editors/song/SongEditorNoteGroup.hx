package states.editors.song;

import data.Settings;
import data.song.NoteInfo;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSort;
import sprites.AnimatedSprite;

class SongEditorNoteGroup extends FlxBasic
{
	public var notes:Array<SongEditorNote> = [];

	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;

		for (note in state.song.notes)
			createNote(note);
		refreshNotes(); // idk why i need to do this but if i dont then the positions are wrong

		state.rateChanged.add(onRateChanged);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
		Settings.editorLongNoteAlpha.valueChanged.add(onLongNoteAlphaChanged);
	}

	override function draw()
	{
		var drewNote = false;
		for (i in 0...notes.length)
		{
			var note = notes[i];
			if (note.isOnScreen())
			{
				note.draw();
				drewNote = true;
			}
			else if (drewNote)
				break;
		}
	}

	override function destroy()
	{
		for (note in notes)
			note.destroy();
		super.destroy();

		state.rateChanged.remove(onRateChanged);
		Settings.editorScrollSpeed.valueChanged.remove(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.remove(onScaleSpeedWithRateChanged);
		Settings.editorLongNoteAlpha.valueChanged.remove(onLongNoteAlphaChanged);
	}

	public function getHoveredNote()
	{
		for (note in notes)
		{
			if (note.isHovered())
				return note;
		}

		return null;
	}

	function createNote(info:NoteInfo, insertAtIndex:Bool = false)
	{
		var note = new SongEditorNote(state, info);
		notes.push(note);
		if (insertAtIndex)
			notes.sort(function(a, b) return FlxSort.byValues(FlxSort.ASCENDING, a.info.startTime, b.info.startTime));
	}

	function refreshNotes()
	{
		for (note in notes)
			note.refresh();
	}

	function onRateChanged(_, _)
	{
		if (Settings.editorScaleSpeedWithRate.value)
			refreshNotes();
	}

	function onScrollSpeedChanged(_, _)
	{
		refreshNotes();
	}

	function onScaleSpeedWithRateChanged(_, _)
	{
		if (state.inst.pitch != 1)
			refreshNotes();
	}

	function onLongNoteAlphaChanged(_, _)
	{
		for (note in notes)
			note.updateLongNoteAlpha();
	}
}

class SongEditorNote extends FlxSpriteGroup
{
	public var info:NoteInfo;
	public var head:AnimatedSprite;
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
		tail.antialiasing = true;
		add(tail);

		head = new AnimatedSprite(0, 0, noteGraphic);
		head.addAnim({
			name: '0',
			atlasName: 'purple instance 1',
			fps: 0
		});
		head.addAnim({
			name: '1',
			atlasName: 'blue instance 1',
			fps: 0
		});
		head.addAnim({
			name: '2',
			atlasName: 'green instance 1',
			fps: 0
		});
		head.addAnim({
			name: '3',
			atlasName: 'red instance 1',
			fps: 0
		});
		head.antialiasing = true;
		add(head);

		refresh();
		updateLongNoteAlpha();
	}

	override function draw()
	{
		if (info.isLongNote)
		{
			body.draw();
			tail.draw();
		}
		head.draw();
	}

	public function updateAnims()
	{
		var anim = Std.string(info.playerLane);
		head.playAnim(anim);

		if (!info.isLongNote)
			return;

		body.playAnim(anim);
		tail.playAnim(anim);
	}

	public function updatePosition()
	{
		x = state.playfieldBG.x + state.columnSize * info.lane + state.borderLeft.width;
		y = state.hitPositionY - info.startTime * state.trackSpeed - head.height;
	}

	public function updateSize()
	{
		head.setGraphicSize(Std.int(state.columnSize - state.borderLeft.width * 2));
		head.updateHitbox();
	}

	public function updateLongNote()
	{
		if (!info.isLongNote)
			return;

		body.setGraphicSize(Std.int(body.frameWidth * head.scale.x), getLongNoteHeight());
		body.updateHitbox();
		body.x = head.x + (head.width / 2) - (body.width / 2);
		body.y = head.y + (-body.height + head.height / 2);
		tail.scale.copyFrom(head.scale);
		tail.updateHitbox();
		tail.x = head.x + (head.width / 2) - (tail.width / 2);
		tail.y = body.y - tail.height;
	}

	public function updateLongNoteAlpha()
	{
		if (!info.isLongNote)
			return;

		body.alpha = tail.alpha = Settings.editorLongNoteAlpha.value;
	}

	public function refresh()
	{
		updateAnims();
		updatePosition();
		updateSize();
		updateLongNote();
	}

	public function isHovered()
	{
		var headHovered = FlxG.mouse.overlaps(head);
		if (!info.isLongNote)
			return headHovered;

		return headHovered || FlxG.mouse.overlaps(body) || FlxG.mouse.overlaps(tail);
	}

	function getLongNoteHeight()
	{
		if (!info.isLongNote)
			return 0;

		return Std.int(Math.abs(state.hitPositionY
			- info.endTime * state.trackSpeed
			- ((state.columnSize * tail.frameHeight) / tail.frameWidth) / 2
			- head.height / 2
			- y));
	}
}
