package states.editors.song;

import flixel.addons.ui.FlxUIText;
import flixel.text.FlxText.FlxTextFormat;
import flixel.util.FlxColor;

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

		noteCountText = new FlxUIText(2, 4, width - 8);
		noteCountText.setBorderStyle(OUTLINE, FlxColor.BLACK);
		updateNoteCount();
		tab.add(noteCountText);

		playbackSpeedText = new FlxUIText(noteCountText.x, noteCountText.y + noteCountText.height + spacing, width - 8);
		playbackSpeedText.setBorderStyle(OUTLINE, FlxColor.BLACK);
		updatePlaybackSpeed();
		tab.add(playbackSpeedText);

		bpmText = new FlxUIText(playbackSpeedText.x, playbackSpeedText.y + playbackSpeedText.height + spacing, width - 8);
		bpmText.setBorderStyle(OUTLINE, FlxColor.BLACK);
		updateBPM();
		tab.add(bpmText);

		beatSnapText = new FlxUIText(bpmText.x, bpmText.y + bpmText.height + spacing, width - 8);
		beatSnapText.setBorderStyle(OUTLINE, FlxColor.BLACK);
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
