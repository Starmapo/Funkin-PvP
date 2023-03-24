package states.editors.song;

import flixel.util.FlxStringUtil;
import ui.editors.EditorPanel;
import ui.editors.EditorText;

class SongEditorDetailsPanel extends EditorPanel
{
	var state:SongEditorState;
	var noteCountText:EditorText;
	var bpmText:EditorText;
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
		resize(250, 120);
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

		timeText = new EditorText(bpmText.x, bpmText.y + bpmText.height + spacing, fieldWidth);
		tab.add(timeText);

		stepText = new EditorText(timeText.x, timeText.y + timeText.height + spacing, fieldWidth);
		tab.add(stepText);

		beatText = new EditorText(stepText.x, stepText.y + stepText.height + spacing, fieldWidth);
		tab.add(beatText);

		updateSongStuff();

		addGroup(tab);

		state.songSeeked.add(onSongSeeked);
	}

	override function update(elapsed:Float)
	{
		updateSongStuff();

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
		state.songSeeked.remove(onSongSeeked);
	}

	function onSongSeeked(_, _)
	{
		updateSongStuff();
	}

	function updateNoteCount()
	{
		noteCountText.text = 'Note Count: ${state.song.notes.length}';
	}

	function updateSongStuff()
	{
		var point = state.song.getTimingPointAt(state.inst.time);

		var bpm:Float = point != null ? point.bpm : 0;
		bpmText.text = 'BPM: $bpm';

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
