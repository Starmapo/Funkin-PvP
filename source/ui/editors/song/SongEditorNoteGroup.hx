package ui.editors.song;

import data.Settings;
import data.song.ITimingObject;
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
	var playfield:SongEditorPlayfield;

	public function new(state:SongEditorState, playfield:SongEditorPlayfield)
	{
		super();
		this.state = state;
		this.playfield = playfield;

		for (note in state.song.notes)
			createNote(note);

		state.rateChanged.add(onRateChanged);
		state.actionManager.onEvent.add(onEvent);
		state.selectedObjects.itemAdded.add(onSelectedNote);
		state.selectedObjects.itemRemoved.add(onDeselectedNote);
		state.selectedObjects.multipleItemsAdded.add(onMultipleNotesSelected);
		state.selectedObjects.arrayCleared.add(onAllNotesDeselected);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
		Settings.editorLongNoteAlpha.valueChanged.add(onLongNoteAlphaChanged);
	}

	override function draw()
	{
		for (i in 0...notes.length)
		{
			var note = notes[i];
			if (note.isOnScreen())
				note.draw();
		}
	}

	override function destroy()
	{
		for (note in notes)
			note.destroy();
		Settings.editorScrollSpeed.valueChanged.remove(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.remove(onScaleSpeedWithRateChanged);
		Settings.editorLongNoteAlpha.valueChanged.remove(onLongNoteAlphaChanged);
		super.destroy();
	}

	public function getHoveredNote()
	{
		if (FlxG.mouse.overlaps(state.playfieldTabs))
			return null;

		for (note in notes)
		{
			if (note.isHovered())
				return note;
		}

		return null;
	}

	function createNote(info:NoteInfo, insertAtIndex:Bool = false)
	{
		var note = new SongEditorNote(state, playfield, info);
		notes.push(note);
		if (insertAtIndex)
			notes.sort(sortNotes);
	}

	function sortNotes(a:SongEditorNote, b:SongEditorNote)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.info.startTime, b.info.startTime);
	}

	function sortInfos(a:NoteInfo, b:NoteInfo)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime);
	}

	function refreshPositions()
	{
		for (note in notes)
			note.updatePosition();
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
			case SongEditorActionManager.ADD_OBJECT:
				if (Std.isOfType(params.object, NoteInfo))
					createNote(params.object, true);
			case SongEditorActionManager.REMOVE_OBJECT:
				if (Std.isOfType(params.object, NoteInfo))
				{
					for (note in notes)
					{
						if (note.info == params.object)
						{
							note.destroy();
							notes.remove(note);
							break;
						}
					}
				}
			case SongEditorActionManager.ADD_OBJECT_BATCH:
				var batch:Array<ITimingObject> = params.objects;
				var added = false;
				for (obj in batch)
				{
					if (Std.isOfType(obj, NoteInfo))
					{
						createNote(cast obj);
						added = true;
					}
				}
				if (added)
					notes.sort(sortNotes);
			case SongEditorActionManager.REMOVE_OBJECT_BATCH:
				var batch:Array<ITimingObject> = params.objects;
				var i = notes.length - 1;
				while (i >= 0)
				{
					var note = notes[i];
					if (batch.contains(note.info))
					{
						notes.remove(note);
						note.destroy();
					}
					i--;
				}
			case SongEditorActionManager.RESIZE_LONG_NOTE:
				for (note in notes)
				{
					if (note.info == params.note)
					{
						note.refreshPositionAndSize();
						break;
					}
				}
			case SongEditorActionManager.MOVE_OBJECTS:
				var batch:Array<ITimingObject> = params.objects;
				var hasNote = false;
				for (note in notes)
				{
					if (batch.contains(note.info))
					{
						note.updateAnims();
						note.refreshPositionAndSize();
						hasNote = true;
					}
				}
				if (hasNote)
					notes.sort(sortNotes);
			case SongEditorActionManager.RESNAP_OBJECTS:
				var batch:Array<ITimingObject> = params.objects;
				var hasNote = false;
				for (note in notes)
				{
					if (batch.contains(note.info))
					{
						note.refreshPositionAndSize();
						hasNote = true;
					}
				}
				if (hasNote)
					notes.sort(sortNotes);
			case SongEditorActionManager.FLIP_NOTES:
				var batch:Array<NoteInfo> = params.notes;
				for (note in notes)
				{
					if (batch.contains(note.noteInfo))
					{
						note.updateAnims();
						note.updatePosition();
					}
				}
		}
	}

	function onSelectedNote(info:ITimingObject)
	{
		if (Std.isOfType(info, NoteInfo))
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
	}

	function onDeselectedNote(info:ITimingObject)
	{
		if (Std.isOfType(info, NoteInfo))
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
	}

	function onMultipleNotesSelected(array:Array<ITimingObject>)
	{
		for (note in notes)
		{
			if (array.contains(note.info))
				note.selectionSprite.visible = true;
		}
	}

	function onAllNotesDeselected()
	{
		for (note in notes)
			note.selectionSprite.visible = false;
	}
}

class SongEditorNote extends FlxSpriteGroup implements ISongEditorTimingObject
{
	public var info:ITimingObject;
	public var noteInfo:NoteInfo;
	public var head:AnimatedSprite;
	public var body:AnimatedSprite;
	public var tail:AnimatedSprite;
	public var selectionSprite:FlxSprite;

	var state:SongEditorState;
	var playfield:SongEditorPlayfield;

	public function new(state:SongEditorState, playfield:SongEditorPlayfield, info:NoteInfo)
	{
		super();
		this.state = state;
		this.playfield = playfield;
		this.info = info;
		noteInfo = info;

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
		if (noteInfo.isLongNote)
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
		var anim = Std.string(noteInfo.playerLane);
		head.playAnim(anim);
		body.playAnim(anim);
		tail.playAnim(anim);
	}

	public function updatePosition()
	{
		x = playfield.bg.x + playfield.columnSize * noteInfo.lane + 2;
		y = state.hitPositionY - info.startTime * state.trackSpeed - head.height;
	}

	public function updateSize()
	{
		head.setGraphicSize(playfield.columnSize - 2);
		head.updateHitbox();
	}

	public function updateLongNote()
	{
		if (!noteInfo.isLongNote)
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
		if (!noteInfo.isLongNote)
			return;

		body.alpha = tail.alpha = Settings.editorLongNoteAlpha.value;
	}

	public function updateSelectionSprite()
	{
		if (noteInfo.isLongNote)
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
		if (!noteInfo.isLongNote)
			return headHovered;

		return headHovered || FlxG.mouse.overlaps(body) || FlxG.mouse.overlaps(tail);
	}

	function getLongNoteHeight()
	{
		if (!noteInfo.isLongNote)
			return 0;

		return Math.round(Math.abs(state.hitPositionY - noteInfo.endTime * state.trackSpeed - head.height / 2 - y));
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
