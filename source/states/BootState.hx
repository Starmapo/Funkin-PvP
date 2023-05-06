package states;

import data.Mods;
import data.PlayerSettings;
import data.Settings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.io.Path;
import lime.app.Application;
import states.pvp.CharacterSelectState;
import sys.FileSystem;
import sys.thread.Thread;
import util.WindowsAPI;

using StringTools;

class BootState extends FNFState
{
	var bg:FlxSprite;
	var loadingText:FlxText;
	var loadingBG:FlxSprite;
	var loadingSteps:Array<LoadingStep> = [];
	var aborted:Bool = false;
	var wantedText:String = 'Loading...';

	override function create()
	{
		initGame();

		FlxG.camera.bgColor = 0xFFCAFF4D;

		bg = new FlxSprite(0, 0, Paths.getImage('menus/loading/funkay'));
		bg.setGraphicSize(0, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		loadingBG = new FlxSprite().makeGraphic(FlxG.width, 1, FlxColor.BLACK);
		loadingBG.alpha = 0.8;
		add(loadingBG);

		loadingText = new FlxText(0, FlxG.height, FlxG.width);
		loadingText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		loadingText.y -= loadingText.height;
		loadingText.screenCenter(X);
		add(loadingText);

		loadingSteps.push({
			name: 'Loading Save Data',
			func: loadSave
		});
		loadingSteps.push({
			name: 'Loading Mods',
			func: loadMods
		});

		Thread.create(function()
		{
			for (i in 0...loadingSteps.length)
			{
				var step = loadingSteps[i];
				updateText(step.name + '... ' + Math.floor((i / loadingSteps.length) * 100) + '%');
				step.func();

				if (aborted)
				{
					CoolUtil.playCancelSound();
					return;
				}
			}

			updateText('Finished!');
			FlxG.camera.fade(FlxColor.BLACK, Main.TRANSITION_TIME, false, exit, true);
			CoolUtil.playConfirmSound();
		});

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		loadingText.text = wantedText;
		loadingText.y = FlxG.height - loadingText.height;
		loadingBG.setPosition(loadingText.x, loadingText.y - 2);
		loadingBG.setGraphicSize(FlxG.width, Std.int(loadingText.height + 4));
		loadingBG.updateHitbox();
	}

	function initGame()
	{
		FlxG.fixedTimestep = false; // allow elapsed time to be variable
		FlxG.debugger.toggleKeys = [GRAVEACCENT, BACKSLASH]; // remove F2 from debugger toggle keys
		FlxG.game.focusLostFramerate = 60; // 60 fps instead of 10 when focus is lost
		FlxG.mouse.useSystemCursor = true; // use system cursor instead of HaxeFlixel one
		FlxG.mouse.visible = false; // hide mouse by default
		FlxG.sound.volumeUpKeys = [NUMPADPLUS];
		FlxG.sound.volumeDownKeys = [NUMPADMINUS];
		FlxG.sound.muteKeys = [NUMPADZERO];
		FlxGraphic.defaultPersist = true; // graphics won't be cleared by default
		// create custom transitions
		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.7, FlxPoint.get(0, -1), null);
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, FlxPoint.get(0, 1), null);
		WindowsAPI.setWindowToDarkMode(); // change window to dark mode
	}

	function loadSave()
	{
		Settings.loadData(); // load settings
		PlayerSettings.init(); // initialize players and controls

		// make sure to save settings if the player exits the game
		Application.current.onExit.add(function(_)
		{
			Settings.saveData();
		});
	}

	function loadMods()
	{
		if (!FileSystem.exists(Mods.modsPath))
		{
			updateText("Mods folder not detected. If you deleted it, please download the game again.");
			aborted = true;
			return;
		}

		var hasFNF = false;
		for (file in FileSystem.readDirectory(Mods.modsPath))
		{
			var fullPath = Path.join([Mods.modsPath, file]);
			var jsonPath = Path.join([fullPath, 'mod.json']);
			if (FileSystem.isDirectory(fullPath) && FileSystem.exists(jsonPath))
			{
				var mod = new Mod(Paths.getJson(jsonPath));
				mod.directory = file;
				Mods.currentMods.push(mod);
				if (file == 'fnf')
					hasFNF = true;

				var pvpMusicPath = Path.join([fullPath, 'data/pvpMusic.txt']);
				if (FileSystem.exists(pvpMusicPath))
				{
					var pvpMusicList = Paths.getText(pvpMusicPath).split('\n');
					for (i in 0...pvpMusicList.length)
						Mods.pvpMusic.push(Path.join([fullPath, 'music', pvpMusicList[i]]));
				}

				var songSelectPath = Path.join([fullPath, 'data/songSelect.json']);
				if (FileSystem.exists(songSelectPath))
				{
					var songSelect = Paths.getJson(songSelectPath);
					var groups:Array<Dynamic> = songSelect.groups;
					for (group in groups)
					{
						var songs:Array<ModSong> = [];
						for (i in 0...group.songs.length)
						{
							var song = group.songs[i];
							var songPath = Paths.getPath('songs/$song', mod.directory);
							var difficulties:Array<String> = [];
							for (songFile in FileSystem.readDirectory(songPath))
							{
								if (songFile.endsWith('.json') && !songFile.startsWith('!'))
									difficulties.push(songFile.substr(0, songFile.length - 5));
							}
							songs.push({
								name: song,
								difficulties: difficulties,
								directory: mod.directory
							});
						}

						var songGroup = Mods.songGroups.get(group.name);
						if (songGroup == null)
						{
							songGroup = {
								name: group.name,
								bg: group.bg,
								songs: [],
								directory: mod.directory
							};
							Mods.songGroups.set(group.name, songGroup);
						}
						for (song in songs)
							songGroup.songs.push(song);
					}
				}

				var characterSelectPath = Path.join([fullPath, 'data/charSelect.json']);
				if (FileSystem.exists(characterSelectPath)) {}
			}
		}
		if (!hasFNF)
		{
			updateText("Base FNF mod not detected. If you deleted it, please download the game again.");
			aborted = true;
		}
	}

	function exit()
	{
		FlxG.switchState(new CharacterSelectState());
	}

	function updateText(text:String)
	{
		wantedText = text;
	}
}

typedef LoadingStep =
{
	var name:String;
	var func:Void->Void;
}
