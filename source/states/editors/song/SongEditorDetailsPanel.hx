package states.editors.song;

import ui.editors.EditorText;
import flixel.addons.ui.FlxUIText;
import flixel.text.FlxText.FlxTextFormat;

class SongEditorDetailsPanel extends EditorPanel
{
	var state:SongEditorState;
	var noteCountText:FlxUIText;
	var playbackSpeedText:FlxUIText;
	var bpmText:FlxUIText;
	var beatSnapText:FlxUIText;

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

		noteCountText = new EditorText(2, 4, width - 8);
		updateNoteCount();
		tab.add(noteCountText);

		playbackSpeedText = new EditorText(noteCountText.x, noteCountText.y + noteCountText.height + spacing, width - 8);
		updatePlaybackSpeed();
		tab.add(playbackSpeedText);

		bpmText = new EditorText(playbackSpeedText.x, playbackSpeedText.y + playbackSpeedText.height + spacing, width - 8);
		updateBPM();
		tab.add(bpmText);

		beatSnapText = new EditorText(bpmText.x, bpmText.y + bpmText.height + spacing, width - 8);
		updateBeatSnap();
		tab.add(beatSnapText);

		addGroup(tab);

		state.songSeeked.add(onSongSeeked);
		state.rateChanged.add(onRateChanged);
		state.beatSnap.valueChanged.add(onBeatSnapChanged);
	}

	override function update(elapsed:Float)
	{
		updateBPM();

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
		state.songSeeked.remove(onSongSeeked);
		state.rateChanged.remove(onRateChanged);
		state.beatSnap.valueChanged.remove(onBeatSnapChanged);
	}

	function onSongSeeked(_, _)
	{
		updateBPM();
	}

	function onRateChanged(_, _)
	{
		updatePlaybackSpeed();
	}

	function onBeatSnapChanged(_, _)
	{
		updateBeatSnap();
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

	function updateBeatSnap()
	{
		beatSnapText.text = 'Beat Snap: 1/${CoolUtil.formatOrdinal(state.beatSnap.value)}';
		beatSnapText.clearFormats();
		beatSnapText.addFormat(new FlxTextFormat(CoolUtil.getBeatSnapColor(state.beatSnap.value)), 11, beatSnapText.text.length);
	}
}
