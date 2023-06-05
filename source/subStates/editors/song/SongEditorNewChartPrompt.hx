package subStates.editors.song;

import data.song.Song;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.io.Path;
import states.editors.SongEditorState;
import ui.editors.EditorCheckbox;
import ui.editors.EditorInputText;
import ui.editors.EditorPanel;
import ui.editors.EditorText;

class SongEditorNewChartPrompt extends FNFSubState
{
	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;

		createCamera();

		var tabMenu = new EditorPanel([
			{
				name: 'tab',
				label: 'Create a new chart...'
			}
		]);
		tabMenu.resize(420, 200);
		add(tabMenu);

		var tab = tabMenu.createTab('tab');
		var spacing = 4;

		var difficultyNameLabel = new EditorText(4, 4, 0, 'Difficulty Name:');

		var difficultyNameInput = new EditorInputText(difficultyNameLabel.x, difficultyNameLabel.y + difficultyNameLabel.height + spacing);

		var copyMetadataCheckbox = new EditorCheckbox(difficultyNameInput.x, difficultyNameInput.y + difficultyNameInput.height + spacing,
			"Copy current chart's metadata");

		var copyObjectsCheckbox = new EditorCheckbox(copyMetadataCheckbox.x + copyMetadataCheckbox.box.width + copyMetadataCheckbox.button.label.width,
			copyMetadataCheckbox.y, "Copy current chart's objects");

		var createButton = new FlxUIButton(0, copyObjectsCheckbox.y + copyObjectsCheckbox.height + spacing, 'Create', function()
		{
			if (difficultyNameInput.text.length < 1)
			{
				FlxTween.cancelTweensOf(difficultyNameInput);
				FlxTween.color(difficultyNameInput, 0.2, FlxColor.RED, difficultyNameInput.color, {startDelay: 0.2});
				return;
			}

			state.save(false);

			var data:Dynamic = {
				instFile: state.song.instFile,
				vocalsFile: state.song.vocalsFile,
				timingPoints: [],
				scrollVelocities: [],
				cameraFocuses: [],
				events: [],
				lyricSteps: [],
				notes: []
			};
			if (copyMetadataCheckbox.checked)
			{
				data.title = state.song.title;
				data.artist = state.song.artist;
				data.source = state.song.source;
				data.bf = state.song.bf;
				data.opponent = state.song.opponent;
				data.gf = state.song.gf;
				data.stage = state.song.stage;
			}
			if (copyObjectsCheckbox.checked)
			{
				data.initialScrollVelocity = state.song.initialScrollVelocity;
				for (t in state.song.timingPoints)
					data.timingPoints.push({
						startTime: t.startTime,
						bpm: t.bpm,
						meter: t.meter
					});
				for (s in state.song.scrollVelocities)
					data.scrollVelocities.push({startTime: s.startTime, multipliers: s.multipliers, linked: s.linked});
				for (c in state.song.cameraFocuses)
					data.cameraFocuses.push({startTime: c.startTime, char: c.char});
				for (e in state.song.events)
				{
					var subs = [];
					for (s in e.events)
						subs.push({event: s.event, params: s.params.join(',')});
					data.events.push({startTime: e.startTime, events: subs});
				}
				for (l in state.song.lyricSteps)
					data.lyricSteps.push({startTime: l.startTime});
				for (n in state.song.notes)
					data.notes.push({
						startTime: n.startTime,
						lane: n.lane,
						endTime: n.endTime,
						type: n.type,
						params: n.params.join(',')
					});
			}

			var difficulty = difficultyNameInput.text;
			var path = Path.join([state.song.directory, difficulty + '.json']);

			var song = new Song(data);
			song.directory = Path.normalize(Path.directory(path));
			var split = song.directory.split('/');
			song.name = split[split.length - 1];
			song.difficultyName = difficulty;
			song.mod = state.song.mod;
			song.sort();

			song.save(path);
			FlxG.switchState(new SongEditorState(song));
		});
		createButton.x = (tabMenu.width - createButton.width) / 2;

		tab.add(difficultyNameLabel);
		tab.add(difficultyNameInput);
		tab.add(copyMetadataCheckbox);
		tab.add(copyObjectsCheckbox);
		tab.add(createButton);

		tabMenu.add(tab);
	}

	override function destroy()
	{
		super.destroy();
		state = null;
	}
}
