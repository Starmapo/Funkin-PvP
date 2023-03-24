package states.editors.song;

import flixel.addons.ui.FlxUIText;
import flixel.math.FlxMath;
import flixel.text.FlxText.FlxTextFormat;
import flixel.util.FlxStringUtil;
import ui.editors.EditorText;

class SongEditorDetailsPanel extends EditorPanel
{
	var state:SongEditorState;
	var noteCountText:FlxUIText;
	var playbackSpeedText:FlxUIText;
	var bpmText:FlxUIText;
	var timeText:FlxUIText;

	public function new(state:SongEditorState)
	{
		super([
			{
				name: 'Details',
				label: 'Details'
			}
		]);
		resize(250, 100);
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

		playbackSpeedText = new EditorText(noteCountText.x, noteCountText.y + noteCountText.height + spacing, fieldWidth);
		updatePlaybackSpeed();
		tab.add(playbackSpeedText);

		bpmText = new EditorText(playbackSpeedText.x, playbackSpeedText.y + playbackSpeedText.height + spacing, fieldWidth);
		updateBPM();
		tab.add(bpmText);

		timeText = new EditorText(bpmText.x, bpmText.y + bpmText.height + spacing, fieldWidth);
		updateTime();
		tab.add(timeText);

		addGroup(tab);

		state.songSeeked.add(onSongSeeked);
		state.rateChanged.add(onRateChanged);
	}

	override function update(elapsed:Float)
	{
		updateBPM();
		updateTime();

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
		state.songSeeked.remove(onSongSeeked);
		state.rateChanged.remove(onRateChanged);
	}

	function onSongSeeked(_, _)
	{
		updateBPM();
	}

	function onRateChanged(_, _)
	{
		updatePlaybackSpeed();
	}

	function updateNoteCount()
	{
		noteCountText.text = 'Note Count: ${state.song.notes.length}';
	}

	function updatePlaybackSpeed()
	{
		playbackSpeedText.text = 'Playback Speed: ${state.inst.pitch * 100}%';
	}

	function updateBPM()
	{
		var bpm:Float = 0;
		var point = state.song.getTimingPointAt(state.inst.time);
		if (point != null)
		{
			bpm = point.bpm;
		}
		bpmText.text = 'BPM: $bpm';
	}

	function updateTime()
	{
		var time = FlxStringUtil.formatTime(state.inst.time / 1000, true);
		var length = FlxStringUtil.formatTime(state.inst.length / 1000, true);
		timeText.text = 'Song Time: $time / $length';
	}
}
