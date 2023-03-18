package states.editors.song;

import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUITypedButton;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class SongEditorDetailsPanel extends FlxUITabMenu
{
	var state:SongEditorState;
	var detailsTab:FlxUI;
	var noteCountText:FlxUIText;
	var playbackSpeedText:FlxUIText;
	var bpmText:FlxUIText;
	var beatSnapText:FlxUIText;

	public function new(state:SongEditorState)
	{
		super(null, null, [
			{
				name: 'Details',
				label: 'Details'
			}
		]);
		resize(250, 158);
		screenCenter(Y);
		y -= 132;
		this.state = state;

		for (tab in _tabs)
		{
			var tab:FlxUITypedButton<FlxText> = cast tab;
			tab.label.setBorderStyle(OUTLINE, FlxColor.BLACK);
		}

		detailsTab = new FlxUI();
		detailsTab.name = 'Details';

		noteCountText = new FlxUIText(2, 4, width - 8);
		noteCountText.setBorderStyle(OUTLINE, FlxColor.BLACK);
		updateNoteCount();
		detailsTab.add(noteCountText);

		var spacing = 4;

		playbackSpeedText = new FlxUIText(noteCountText.x, noteCountText.y + noteCountText.height + spacing, width - 8);
		playbackSpeedText.setBorderStyle(OUTLINE, FlxColor.BLACK);
		updatePlaybackSpeed();
		detailsTab.add(playbackSpeedText);

		bpmText = new FlxUIText(playbackSpeedText.x, playbackSpeedText.y + playbackSpeedText.height + spacing, width - 8);
		bpmText.setBorderStyle(OUTLINE, FlxColor.BLACK);
		updateBPM();
		detailsTab.add(bpmText);

		beatSnapText = new FlxUIText(bpmText.x, bpmText.y + bpmText.height + spacing, width - 8);
		beatSnapText.setBorderStyle(OUTLINE, FlxColor.BLACK);
		updateBeatSnap();
		detailsTab.add(beatSnapText);

		addGroup(detailsTab);

		scrollFactor.set();

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
