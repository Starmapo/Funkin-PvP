package util.editors.song;

import data.Settings;
import flixel.FlxG;
import states.editors.SongEditorState;

class SongEditorMetronome
{
	var state:SongEditorState;
	var lastBeat:Int;
	var currentBeat:Int;
	var currentTotalBeats:Int;
	var lastTotalBeats:Int;

	public function new(state:SongEditorState)
	{
		this.state = state;
	}

	public function update()
	{
		if (Settings.editorMetronome.value == NONE)
			return;

		if (!state.inst.playing || state.song.timingPoints.length == 0)
			return;

		var time = state.inst.time;
		var point = state.song.getTimingPointAt(time);

		if (time < point.startTime)
		{
			lastBeat = -1;
			return;
		}

		var beats = Settings.editorMetronome.value == EVERY_HALF_BEAT ? 2 : 1;
		var totalBeats = (time - point.startTime) / (point.beatLength / beats);

		currentTotalBeats = Math.floor(totalBeats);

		currentBeat = Std.int(totalBeats % point.meter);

		if (currentTotalBeats == 0 && lastTotalBeats < 0 || currentBeat != lastBeat)
		{
			if (currentBeat == 0)
				FlxG.sound.play(Paths.getSound('editor/metronome-measure'));
			else
				FlxG.sound.play(Paths.getSound('editor/metronome-beat'));
		}

		lastBeat = currentBeat;
		lastTotalBeats = currentTotalBeats;
	}
}
