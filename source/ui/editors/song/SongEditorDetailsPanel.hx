package ui.editors.song;

import flixel.util.FlxStringUtil;
import states.editors.SongEditorState;
import ui.editors.EditorPanel;
import ui.editors.EditorText;
import util.editors.actions.song.SongEditorActionManager;

class SongEditorDetailsPanel extends EditorPanel
{
	var state:SongEditorState;
	var noteCountText:EditorText;
	var bpmText:EditorText;
	var scrollVelocityText:EditorText;
	var timeText:EditorText;
	var stepText:EditorText;
	var beatText:EditorText;

	public function new(state:SongEditorState)
	{
		super([
			{
				name: 'Details',
				label: 'Details'
			}
		]);
		resize(250, 140);
		x = 10;
		screenCenter(Y);
		y -= 132;
		this.state = state;

		var tab = createTab('Details');

		var spacing = 4;
		var fieldWidth = width - 8;

		noteCountText = new EditorText(2, 4, fieldWidth);
		updateNoteCount();
		tab.add(noteCountText);

		bpmText = new EditorText(noteCountText.x, noteCountText.y + noteCountText.height + spacing, fieldWidth);
		tab.add(bpmText);

		scrollVelocityText = new EditorText(bpmText.x, bpmText.y + bpmText.height + spacing, fieldWidth);
		tab.add(scrollVelocityText);

		timeText = new EditorText(scrollVelocityText.x, scrollVelocityText.y + scrollVelocityText.height + spacing, fieldWidth);
		tab.add(timeText);

		stepText = new EditorText(timeText.x, timeText.y + timeText.height + spacing, fieldWidth);
		tab.add(stepText);

		beatText = new EditorText(stepText.x, stepText.y + stepText.height + spacing, fieldWidth);
		tab.add(beatText);

		updateSongStuff();

		addGroup(tab);

		state.songSeeked.add(onSongSeeked);
		state.actionManager.onEvent.add(onEvent);
	}

	override function update(elapsed:Float)
	{
		updateSongStuff();

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
	}

	function onSongSeeked(_, _)
	{
		updateSongStuff();
	}

	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.ADD_NOTE, SongEditorActionManager.REMOVE_NOTE, SongEditorActionManager.ADD_NOTE_BATCH,
				SongEditorActionManager.REMOVE_NOTE_BATCH:
				updateNoteCount();
		}
	}

	function updateNoteCount()
	{
		var normalNotes = 0;
		var longNotes = 0;
		for (note in state.song.notes)
		{
			if (note.isLongNote)
				longNotes++;
			else
				normalNotes++;
		}
		noteCountText.text = 'Note Count: ${state.song.notes.length} ($normalNotes Normal, $longNotes Long)';
	}

	function updateSongStuff()
	{
		var point = state.song.getTimingPointAt(state.inst.time);
		var sv = state.song.getScrollVelocityAt(state.inst.time);

		bpmText.text = 'BPM: ${point != null ? point.bpm : 0}';

		scrollVelocityText.text = 'Scroll Velocity: ${sv != null ? sv.multiplier : state.song.initialScrollVelocity}';

		var time = FlxStringUtil.formatTime(state.inst.time / 1000, true);
		var length = FlxStringUtil.formatTime(state.inst.length / 1000, true);
		timeText.text = 'Song Time: $time / $length';

		var step = 0;
		var beat = 0;
		if (point != null)
		{
			step = Math.floor((state.inst.time - point.startTime) / point.stepLength);
			beat = Math.floor((state.inst.time - point.startTime) / point.beatLength);
		}
		stepText.text = 'Timing Point Step: $step';
		beatText.text = 'Timing Point Beat: $beat';
	}
}
