package subStates.editors.song;

import data.song.Song;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
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
		checkObjects = true;
		
		createCamera();
		
		var tabMenu = new EditorPanel([
			{
				name: 'tab',
				label: 'Create a new chart...'
			}
		]);
		tabMenu.resize(270, 100);
		
		var tab = tabMenu.createTab('tab');
		var spacing = 4;
		
		var difficultyNameLabel = new EditorText(4, 5, 0, 'Difficulty Name:');
		
		var difficultyNameInput = new EditorInputText(difficultyNameLabel.x + difficultyNameLabel.width + spacing, difficultyNameLabel.y - 1, 0, null, 8,
			true, camSubState);
			
		var copyMetadataCheckbox = new EditorCheckbox(difficultyNameLabel.x, difficultyNameLabel.y + difficultyNameLabel.height + spacing * 2,
			"Copy current chart's metadata");
		copyMetadataCheckbox.checked = true;
		
		var copyObjectsCheckbox = new EditorCheckbox(copyMetadataCheckbox.x + copyMetadataCheckbox.box.width + copyMetadataCheckbox.button.label.width,
			copyMetadataCheckbox.y, "Copy current chart's objects");
		copyObjectsCheckbox.checked = true;
		
		var createButton = new FlxUIButton(0, copyObjectsCheckbox.y + copyObjectsCheckbox.height + spacing * 2, 'Create', function()
		{
			var diff = difficultyNameInput.text;
			if (diff.length < 1 || FlxStringUtil.hasInvalidChars(diff))
			{
				FlxTween.cancelTweensOf(difficultyNameInput);
				FlxTween.color(difficultyNameInput, 0.2, FlxColor.RED, FlxColor.WHITE, {startDelay: 0.2});
				return;
			}
			
			state.save(false);
			
			var data:Dynamic = {
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
			else
				data.timingPoints.push({});
				
			var path = Path.join([state.song.directory, diff + '.json']);
			
			var song = new Song(data);
			song.directory = Path.normalize(Path.directory(path));
			var split = song.directory.split('/');
			song.name = split[split.length - 1];
			song.difficultyName = diff;
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
		
		tabMenu.addGroup(tab);
		
		tabMenu.screenCenter();
		add(tabMenu);
		
		var closeButton = new FlxUIButton(tabMenu.x + tabMenu.width - 20 - spacing, tabMenu.y + spacing, "X", function()
		{
			close();
		});
		closeButton.resize(20, 20);
		closeButton.color = FlxColor.RED;
		closeButton.label.color = FlxColor.WHITE;
		add(closeButton);
	}
	
	override function destroy()
	{
		super.destroy();
		state = null;
	}
}
