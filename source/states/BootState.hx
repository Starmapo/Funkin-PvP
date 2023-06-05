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
import states.menus.TitleState;
import sys.FileSystem;
import sys.thread.Thread;
import util.DiscordClient;
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
			FlxG.camera.fade(FlxColor.BLACK, Main.getTransitionTime(), false, exit, true);
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
		loadingBG.setGraphicSize(FlxG.width, loadingText.height + 4);
		loadingBG.updateHitbox();
	}

	override function destroy()
	{
		super.destroy();
		bg = null;
		loadingText = null;
		loadingBG = null;
		loadingSteps = null;
	}

	function initGame()
	{
		DiscordClient.initialize();
		Application.current.window.onClose.add(function()
		{
			DiscordClient.shutdown();
		});

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

		Paths.init();
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

				var difficulties:Array<String> = ['Easy', 'Normal', 'Hard'];
				var difficultiesPath = Path.join([fullPath, 'data/difficulties.txt']);
				if (FileSystem.exists(difficultiesPath))
				{
					var diffs = Paths.getContent(difficultiesPath).trim().split('\n');
					for (diff in diffs)
					{
						diff = diff.trim();
						if (diff.length > 0)
							difficulties.push(diff);
					}
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
							var songData = group.songs[i];
							var name = songData.name;
							var icon:String = songData.icon;
							if (!icon.contains(':'))
								icon = mod.directory + ':' + icon;

							var songPath = Paths.getPath('songs/$name', mod.directory);
							var songDifficulties:Array<String> = [];
							if (difficulties.length > 0)
							{
								for (diff in difficulties)
								{
									var diffPath = Path.join([songPath, diff + '.json']);
									if (FileSystem.exists(diffPath))
										songDifficulties.push(diff);
								}
							}
							else
							{
								for (songFile in FileSystem.readDirectory(songPath))
								{
									if (songFile.endsWith('.json') && !songFile.startsWith('!'))
										songDifficulties.push(songFile.substr(0, songFile.length - 5));
								}
							}
							if (songDifficulties.length > 0)
								songs.push({
									name: name,
									icon: icon,
									difficulties: songDifficulties,
									directory: mod.directory
								});
						}

						if (songs.length > 0)
						{
							var songGroup = Mods.songGroups.get(group.name);
							if (songGroup == null)
							{
								songGroup = {
									name: group.name,
									bg: mod.directory + ':' + group.bg,
									songs: []
								};
								Mods.songGroups.set(group.name, songGroup);
							}
							for (song in songs)
								songGroup.songs.push(song);
						}
					}
				}

				var characterSelectPath = Path.join([fullPath, 'data/charSelect.json']);
				if (FileSystem.exists(characterSelectPath))
				{
					var characterSelect = Paths.getJson(characterSelectPath);
					var groups:Array<Dynamic> = characterSelect.groups;
					for (group in groups)
					{
						var chars:Array<ModCharacter> = [];
						for (i in 0...group.chars.length)
						{
							var char = group.chars[i];
							if (char != null)
							{
								chars.push({
									name: char.name,
									displayName: char.displayName,
									directory: mod.directory
								});
							}
						}

						if (chars.length > 0)
						{
							var charGroup = Mods.characterGroups.get(group.name);
							if (charGroup == null)
							{
								charGroup = {
									name: group.name,
									bg: mod.directory + ':' + group.bg,
									chars: []
								};
								Mods.characterGroups.set(group.name, charGroup);
							}
							for (char in chars)
								charGroup.chars.push(char);

							// trace(charGroup);
						}
					}
				}

				var skinGroup:ModSkins = {
					name: mod.name,
					noteskins: [],
					judgementSkins: [],
					splashSkins: []
				};
				Mods.skins.set(mod.directory, skinGroup);

				var noteskinList = Path.join([fullPath, 'data/noteskins/skins.txt']);
				if (FileSystem.exists(noteskinList))
				{
					var list = Paths.getContent(noteskinList).trim().split('\n');
					for (n in list)
					{
						var split = n.trim().split(':');
						skinGroup.noteskins.push({
							name: split[0],
							displayName: split[1],
							mod: mod.directory
						});
					}
				}

				var judgementSkinList = Path.join([fullPath, 'data/judgementSkins/skins.txt']);
				if (FileSystem.exists(judgementSkinList))
				{
					var list = Paths.getContent(judgementSkinList).trim().split('\n');
					for (n in list)
					{
						var split = n.trim().split(':');
						skinGroup.judgementSkins.push({
							name: split[0],
							displayName: split[1],
							mod: mod.directory
						});
					}
				}

				var splashSkinList = Path.join([fullPath, 'data/splashSkins/skins.txt']);
				if (FileSystem.exists(splashSkinList))
				{
					var list = Paths.getContent(splashSkinList).trim().split('\n');
					for (n in list)
					{
						var split = n.trim().split(':');
						skinGroup.splashSkins.push({
							name: split[0],
							displayName: split[1],
							mod: mod.directory
						});
					}
				}
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
		FlxG.switchState(new TitleState());
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
