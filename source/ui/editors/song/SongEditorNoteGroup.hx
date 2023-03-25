package ui.editors.song;

import data.Settings;
import data.song.NoteInfo;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSort;
import sprites.AnimatedSprite;
import states.editors.SongEditorState;
import util.editors.actions.song.SongEditorActionManager;

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

		state.rateChanged.add(onRateChanged);
		state.actionManager.onEvent.add(onEvent);
		state.selectedNotes.itemAdded.add(onSelectedNote);
		state.selectedNotes.itemRemoved.add(onDeselectedNote);
		state.selectedNotes.multipleItemsAdded.add(onMultipleNotesSelected);
		state.selectedNotes.arrayCleared.add(onAllNotesDeselected);
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
		state.selectedNotes.itemAdded.remove(onSelectedNote);
		state.selectedNotes.itemRemoved.remove(onDeselectedNote);
		state.selectedNotes.multipleItemsAdded.remove(onMultipleNotesSelected);
		state.selectedNotes.arrayCleared.remove(onAllNotesDeselected);
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
		note.refresh();
	}

	function refreshPositionsAndSizes()
	{
		for (note in notes)
			note.refreshPositionAndSize();
	}

	function onRateChanged(_, _)
	{
		if (Settings.editorScaleSpeedWithRate.value)
			refreshPositionsAndSizes();
	}

	function onScrollSpeedChanged(_, _)
	{
		refreshPositionsAndSizes();
	}

	function onScaleSpeedWithRateChanged(_, _)
	{
		if (state.inst.pitch != 1)
			refreshPositionsAndSizes();
	}

	function onLongNoteAlphaChanged(_, _)
	{
		for (note in notes)
			note.updateLongNoteAlpha();
	}

	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.PLACE_NOTE:
				createNote(params.note, true);
			case SongEditorActionManager.REMOVE_NOTE:
				var daNote:SongEditorNote = null;
				for (note in notes)
				{
					if (note.info == params.note)
					{
						daNote = note;
					}
				}
				if (daNote == null)
					return;
				daNote.destroy();
				notes.remove(daNote);
		}
	}

	function onSelectedNote(info:NoteInfo)
	{
		for (note in notes)
		{
			if (note.info == info)
			{
				note.selectionSprite.visible = true;
				break;
			}
		}
	}

	function onDeselectedNote(info:NoteInfo)
	{
		for (note in notes)
		{
			if (note.info == info)
			{
				note.selectionSprite.visible = false;
				break;
			}
		}
	}

	function onMultipleNotesSelected(array:Array<NoteInfo>)
	{
		for (note in notes)
		{
			if (array.contains(note.info))
			{
				note.selectionSprite.visible = true;
				break;
			}
		}
	}

	function onAllNotesDeselected()
	{
		for (note in notes)
		{
			note.selectionSprite.visible = false;
		}
	}
}

class SongEditorNote extends FlxSpriteGroup
{
	public var info:NoteInfo;
	public var head:AnimatedSprite;
	public var body:AnimatedSprite;
	public var tail:AnimatedSprite;
	public var selectionSprite:FlxSprite;

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

		selectionSprite = new FlxSprite().makeGraphic(1, 1);
		selectionSprite.alpha = 0.5;
		selectionSprite.visible = false;
		add(selectionSprite);

		refresh();
	}

	override function draw()
	{
		if (info.isLongNote)
		{
			body.draw();
			tail.draw();
		}
		head.draw();
		if (selectionSprite.visible)
			selectionSprite.draw();
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
		head.setGraphicSize(Std.int(state.columnSize - state.borderLeft.width));
		head.updateHitbox();
	}

	public function updateLongNote()
	{
		if (!info.isLongNote)
			return;

		tail.scale.copyFrom(head.scale);
		tail.updateHitbox();
		body.setGraphicSize(Std.int(body.frameWidth * head.scale.x), getLongNoteHeight());
		body.updateHitbox();
		body.x = head.x + (head.width / 2) - (body.width / 2);
		body.y = head.y + (head.height / 2) - body.height;
		tail.x = head.x + (head.width / 2) - (tail.width / 2);
		tail.y = body.y - tail.height;
	}

	public function updateLongNoteAlpha()
	{
		if (!info.isLongNote)
			return;

		body.alpha = tail.alpha = Settings.editorLongNoteAlpha.value;
	}

	public function updateSelectionSprite()
	{
		if (info.isLongNote)
		{
			remove(selectionSprite); // get the group height excluding the selection sprite
			selectionSprite.setGraphicSize(Std.int(head.width), Std.int(height + 20));
			selectionSprite.updateHitbox();
			add(selectionSprite);
		}
		else
		{
			selectionSprite.setGraphicSize(Std.int(head.width), Std.int(head.height + 20));
			selectionSprite.updateHitbox();
		}

		selectionSprite.setPosition(head.x, head.y + head.height - selectionSprite.height + 10);
	}

	public function refresh()
	{
		updateAnims();
		refreshPositionAndSize();
		updateLongNoteAlpha();
	}

	public function refreshPositionAndSize()
	{
		updateSize();
		updatePosition();
		updateLongNote();
		updateSelectionSprite();
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

		return Std.int(Math.abs(state.hitPositionY - info.endTime * state.trackSpeed - tail.height / 2 - head.height / 2 - y));
	}

	function onDeselectedNote(note:NoteInfo)
	{
		if (info != note)
			return;

		selectionSprite.visible = false;
	}

	function onAllNotesDeselected()
	{
		selectionSprite.visible = false;
	}
}
