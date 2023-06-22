package states;

import data.Mods;
import data.PlayerSettings;
import data.Settings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import haxe.io.Path;
import hscript.Interp;
import lime.app.Application;
import sys.FileSystem;
import sys.thread.Thread;
import util.AudioSwitchFix;
import util.WindowsAPI;

using StringTools;

#if !macro
import util.DiscordClient;
#end

class BootState extends FNFState
{
	/**
		The state to switch to after the game finishes booting up.
	**/
	static var initialState:Class<FlxState> = states.menus.TitleState;

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
		WindowsAPI.setWindowToDarkMode(); // change window to dark mode
		AudioSwitchFix.init();

		Paths.init();

		#if !macro
		DiscordClient.initialize();
		#end

		FlxG.fixedTimestep = false; // allow elapsed time to be variable
		FlxG.debugger.toggleKeys = [GRAVEACCENT, BACKSLASH]; // remove F2 from debugger toggle keys
		FlxG.game.focusLostFramerate = 60; // 60 fps instead of 10 when focus is lost
		FlxG.mouse.useSystemCursor = true; // use system cursor instead of HaxeFlixel one
		FlxG.mouse.visible = false; // hide mouse by default
		FlxG.sound.volumeUpKeys = [NUMPADPLUS];
		FlxG.sound.volumeDownKeys = [NUMPADMINUS];
		FlxG.sound.muteKeys = [NUMPADZERO];
		// create custom transitions
		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.7, FlxPoint.get(0, -1), null);
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, FlxPoint.get(0, 1), null);

		Interp.getRedirects["Int"] = function(obj:Dynamic, name:String):Dynamic
		{
			var c:FlxColor = obj;
			switch (name)
			{
				case "alpha":
					return c.alpha;
				case "alphaFloat":
					return c.alphaFloat;
				case "black":
					return c.black;
				case "blue":
					return c.blue;
				case "blueFloat":
					return c.blueFloat;
				case "brightness":
					return c.brightness;
				case "cyan":
					return c.cyan;
				case "to24Bit":
					return c.to24Bit;
				case "getAnalogousHarmony":
					return c.getAnalogousHarmony;
				case "getColorInfo":
					return c.getColorInfo;
				case "getComplementHarmony":
					return c.getComplementHarmony;
				case "getDarkened":
					return c.getDarkened;
				case "getInverted":
					return c.getInverted;
				case "getLightened":
					return c.getLightened;
				case "toHexString":
					return c.toHexString;
				case "getSplitComplementHarmony":
					return c.getSplitComplementHarmony;
				case "getTriadicHarmony":
					return c.getTriadicHarmony;
				case "toWebString":
					return c.toWebString;
				case "green":
					return c.green;
				case "greenFloat":
					return c.greenFloat;
				case "hue":
					return c.hue;
				case "lightness":
					return c.lightness;
				case "magenta":
					return c.magenta;
				case "red":
					return c.red;
				case "redFloat":
					return c.redFloat;
				case "rgb":
					return c.rgb;
				case "setCMYK":
					return c.setCMYK;
				case "setHSB":
					return c.setHSB;
				case "setHSL":
					return c.setHSL;
				case "setRGB":
					return c.setRGB;
				case "setRGBFloat":
					return c.setRGBFloat;
				case "saturation":
					return c.saturation;
				case "yellow":
					return c.yellow;
			}
			var c:FlxAxes = obj;
			switch (name)
			{
				case "x":
					return c.x;
				case "y":
					return c.y;
			}
			return null;
		}
		Interp.setRedirects["Int"] = function(obj:Dynamic, name:String, val:Dynamic):Dynamic
		{
			var c:FlxColor = obj;
			switch (name)
			{
				case "alpha":
					return c.alpha = val;
				case "alphaFloat":
					return c.alphaFloat = val;
				case "black":
					return c.black = val;
				case "blue":
					return c.blue = val;
				case "blueFloat":
					return c.blueFloat = val;
				case "brightness":
					return c.brightness = val;
				case "cyan":
					return c.cyan = val;
				case "green":
					return c.green = val;
				case "greenFloat":
					return c.greenFloat = val;
				case "hue":
					return c.hue = val;
				case "lightness":
					return c.lightness = val;
				case "magenta":
					return c.magenta = val;
				case "red":
					return c.red = val;
				case "redFloat":
					return c.redFloat = val;
				case "rgb":
					return c.rgb = val;
				case "saturation":
					return c.saturation = val;
				case "yellow":
					return c.yellow = val;
			}
			return null;
		}
		Interp.getRedirects["flixel.math.FlxBasePoint"] = function(obj:Dynamic, name:String):Dynamic
		{
			var c:FlxPoint = obj;
			switch (name)
			{
				case "add":
					return c.add;
				case "addNew":
					return c.addNew;
				case "addPoint":
					return c.addPoint;
				case "addToFlash":
					return c.addToFlash;
				case "bounce":
					return c.bounce;
				case "bounceWithFriction":
					return c.bounceWithFriction;
				case "ceil":
					return c.ceil;
				case "clone":
					return c.clone;
				case "copyFrom":
					return c.copyFrom;
				case "copyFromFlash":
					return c.copyFromFlash;
				case "copyTo":
					return c.copyTo;
				case "copyToFlash":
					return c.copyToFlash;
				case "crossProductLength":
					return c.crossProductLength;
				case "degrees":
					return c.degrees;
				case "degreesBetween":
					return c.degreesBetween;
				case "degreesFrom":
					return c.degreesFrom;
				case "degreesTo":
					return c.degreesTo;
				case "dist":
					return c.dist;
				case "distSquared":
					return c.distSquared;
				case "distanceTo":
					return c.distanceTo;
				case "divide":
					return c.divide;
				case "divideNew":
					return c.divideNew;
				case "dividePoint":
					return c.dividePoint;
				case "dot":
					return c.dot;
				case "dotProduct":
					return c.dotProduct;
				case "dotProdWithNormalizing":
					return c.dotProdWithNormalizing;
				case "dx":
					return c.dx;
				case "dy":
					return c.dy;
				case "findIntersection":
					return c.findIntersection;
				case "findIntersectionInBounds":
					return c.findIntersectionInBounds;
				case "floor":
					return c.floor;
				case "inCoords":
					return c.inCoords;
				case "inRect":
					return c.inRect;
				case "isNormalized":
					return c.isNormalized;
				case "isParallel":
					return c.isParallel;
				case "isPerpendicular":
					return c.isPerpendicular;
				case "isValid":
					return c.isValid;
				case "isZero":
					return c.isZero;
				case "leftNormal":
					return c.leftNormal;
				case "length":
					return c.length;
				case "lengthSquared":
					return c.lengthSquared;
				case "lx":
					return c.lx;
				case "ly":
					return c.ly;
				case "negate":
					return c.negate;
				case "negateNew":
					return c.negateNew;
				case "normalize":
					return c.normalize;
				case "perpProduct":
					return c.perpProduct;
				case "pivotDegrees":
					return c.pivotDegrees;
				case "pivotRadians":
					return c.pivotRadians;
				case "projectTo":
					return c.projectTo;
				case "projectToNormalized":
					return c.projectToNormalized;
				case "radians":
					return c.radians;
				case "radiansBetween":
					return c.radiansBetween;
				case "radiansFrom":
					return c.radiansFrom;
				case "radiansTo":
					return c.radiansTo;
				case "ratio":
					return c.ratio;
				case "rightNormal":
					return c.rightNormal;
				case "rotateByDegrees":
					return c.rotateByDegrees;
				case "rotateByRadians":
					return c.rotateByRadians;
				case "rotateWithTrig":
					return c.rotateWithTrig;
				case "round":
					return c.round;
				case "rx":
					return c.rx;
				case "ry":
					return c.ry;
				case "setPolarDegrees":
					return c.setPolarDegrees;
				case "setPolarRadians":
					return c.setPolarRadians;
				case "sign":
					return c.sign;
				case "scale":
					return c.scale;
				case "scaleNew":
					return c.scaleNew;
				case "scalePoint":
					return c.scalePoint;
				case "subtract":
					return c.subtract;
				case "subtractFromFlash":
					return c.subtractFromFlash;
				case "subtractNew":
					return c.subtractNew;
				case "subtractPoint":
					return c.subtractPoint;
				case "transform":
					return c.transform;
				case "truncate":
					return c.truncate;
				case "zero":
					return c.zero;
			}
			return null;
		}
		Interp.setRedirects["flixel.math.FlxBasePoint"] = function(obj:Dynamic, name:String, val:Dynamic):Dynamic
		{
			var c:FlxPoint = obj;
			switch (name)
			{
				case "degrees":
					return c.degrees = val;
				case "length":
					return c.length = val;
				case "radians":
					return c.radians = val;
			}
			return null;
		};
	}

	function loadSave()
	{
		Settings.loadData(); // load settings
		PlayerSettings.init(); // initialize players and controls

		Application.current.onExit.add(function(_)
		{
			Settings.saveData();
			#if !macro
			DiscordClient.shutdown();
			#end
			Sys.exit(0);
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
					difficulties = [];
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
							if (icon == null)
								icon = '';
							if (icon.length > 0 && !icon.contains(':'))
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
							{
								songs.push({
									name: name,
									icon: icon,
									difficulties: songDifficulties,
									directory: mod.directory
								});
								mod.songCount++;
							}
						}

						if (songs.length > 0)
						{
							var songGroup = Mods.songGroups.get(group.name);
							if (songGroup == null)
							{
								songGroup = {
									name: group.name,
									songs: [],
									directory: mod.directory
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
								mod.characterCount++;
							}
						}

						if (chars.length > 0)
						{
							var charGroup = Mods.characterGroups.get(group.name);
							if (charGroup == null)
							{
								charGroup = {
									name: group.name,
									chars: [],
									directory: mod.directory
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
						mod.noteskinCount++;
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
						mod.judgementSkinCount++;
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
						mod.splashSkinCount++;
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
		FlxG.switchState(Type.createInstance(initialState, []));
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
