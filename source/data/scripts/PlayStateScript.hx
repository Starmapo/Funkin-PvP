package data.scripts;

import data.game.GameplayGlobals;
import data.skin.NoteSkin;
import data.song.NoteInfo;
import data.song.Song;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.addons.display.FlxRuntimeShader;
import flixel.math.FlxMath;
import haxe.io.Path;
import hxcodec.flixel.FlxVideoSprite;
import sprites.game.Character;
import states.PlayState;
import sys.FileSystem;
import sys.io.File;
import ui.game.Note;
import util.UnsafeUtil;

using StringTools;

/**
	A script for the gameplay screen (`PlayState`).
**/
class PlayStateScript extends Script
{
	var state:PlayState;
	
	public function new(state:PlayState, path:String, mod:String)
	{
		this.state = state;
		super(path, mod);
	}
	
	override function destroy()
	{
		state = null;
		super.destroy();
	}
	
	override function setStartingVariables()
	{
		super.setStartingVariables();
		
		setVariable("state", state);
		setVariable("members", state.members);
		setVariable("opponent", state.opponent);
		setVariable("bf", state.bf);
		setVariable("gf", state.gf);
		setVariable("camFollow", state.camFollow);
		setVariable("ruleset", state.ruleset);
		setVariable("timing", state.timing);
		setVariable("song", state.song);
		setVariable("songName", state.song.name);
		setVariable("difficultyName", state.song.difficultyName);
		setVariable("camHUD", state.camHUD);
		setVariable("camOther", state.camOther);
		setVariable("inst", state.inst);
		setVariable("vocals", state.vocals);
		setVariable("statsDisplay", state.statsDisplay);
		setVariable("judgementDisplay", state.judgementDisplay);
		setVariable("songInfoDisplay", state.songInfoDisplay);
		setVariable("lyricsDisplay", state.lyricsDisplay);
		setVariable("healthBars", state.healthBars);
		setVariable("deathBG", state.deathBG);
		setVariable("backgroundCover", state.backgroundCover);
		setVariable("judgementCounters", state.judgementCounters);
		setVariable("npsDisplay", state.npsDisplay);
		setVariable("msDisplay", state.msDisplay);
		setVariable("staticBG", state.staticBG);
		setVariable("playbackRate", GameplayGlobals.playbackRate);
		
		setVariable("add", state.add);
		setVariable("insert", state.insert);
		setVariable("remove", state.remove);
		setVariable("precacheGraphic", state.precacheGraphic);
		setVariable("precacheImage", state.precacheImage);
		setVariable("precacheCharacter", state.precacheCharacter);
		setVariable("debugPrint", Reflect.makeVarArgs(function(el)
		{
			var inf = interp.posInfos();
			var posInfo = inf.fileName + ':' + inf.lineNumber + ': ';
			var max = el.length - 1;
			for (i in 0...el.length)
			{
				posInfo += Std.string(el[i]);
				if (i < max)
					posInfo += ', ';
			}
			Main.showInternalNotification(posInfo);
			trace(posInfo);
		}));
		
		setVariable("getOrder", function(obj:FlxBasic)
		{
			return state.members.indexOf(obj);
		});
		setVariable("setOrder", function(obj:FlxBasic, index:Int)
		{
			state.remove(obj, true);
			return state.insert(index, obj);
		});
		setVariable("addBehindChars", function(obj:FlxBasic)
		{
			var index = FlxMath.minInt(FlxMath.minInt(state.members.indexOf(state.gf), state.members.indexOf(state.opponent)),
				state.members.indexOf(state.bf));
			return state.insert(index, obj);
		});
		setVariable("addOverChars", function(obj:FlxBasic)
		{
			var index = FlxMath.maxInt(FlxMath.maxInt(state.members.indexOf(state.gf), state.members.indexOf(state.opponent)),
				state.members.indexOf(state.bf));
			return state.insert(index + 1, obj);
		});
		setVariable("addBehindOpponent", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.opponent), obj);
		});
		setVariable("addBehindBF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.bf), obj);
		});
		setVariable("addBehindGF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.gf), obj);
		});
		setVariable("addOverOpponent", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.opponent) + 1, obj);
		});
		setVariable("addOverBF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.bf) + 1, obj);
		});
		setVariable("addOverGF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.gf) + 1, obj);
		});
		setVariable("addBehindUI", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.ruleset.playfields[0]), obj);
		});
		setVariable("getCharacters", function(?name:String, ?mod:String)
		{
			var characters:Array<Character> = [];
			var allChars = [state.gf, state.opponent, state.bf];
			for (char in allChars)
			{
				if (char.info != null && (name == null || char.info.name == name) && (mod == null || char.info.mod == mod))
					characters.push(char);
			}
			return characters;
		});
		setVariable("getPlayerCharacter", function(player:Int = 0)
		{
			return state.getPlayerCharacter(player);
		});
		setVariable("getNoteCharacter", function(note:Note)
		{
			return state.getNoteCharacter(note);
		});
		setVariable("getCurrentNotes", function()
		{
			var notes:Array<Note> = [];
			for (playfield in state.ruleset.playfields)
			{
				var manager = playfield.noteManager;
				pushLaneNotes(notes, manager.activeNoteLanes);
				pushLaneNotes(notes, manager.heldLongNoteLanes);
				pushLaneNotes(notes, manager.deadNoteLanes);
			}
			return notes;
		});
		setVariable("getActiveNotes", function()
		{
			var notes:Array<Note> = [];
			for (playfield in state.ruleset.playfields)
				pushLaneNotes(notes, playfield.noteManager.activeNoteLanes);
			return notes;
		});
		setVariable("getHeldNotes", function()
		{
			var notes:Array<Note> = [];
			for (playfield in state.ruleset.playfields)
				pushLaneNotes(notes, playfield.noteManager.heldLongNoteLanes);
			return notes;
		});
		setVariable("getDeadNotes", function()
		{
			var notes:Array<Note> = [];
			for (playfield in state.ruleset.playfields)
				pushLaneNotes(notes, playfield.noteManager.deadNoteLanes);
			return notes;
		});
		setVariable("getQueueNotes", function()
		{
			var notes:Array<NoteInfo> = [];
			for (playfield in state.ruleset.playfields)
				pushLaneNotes(notes, playfield.noteManager.noteQueueLanes);
			return notes;
		});
		setVariable("getShader", function(name:String, glslVersion:Int = 120)
		{
			return getShader(name, glslVersion);
		});
		setVariable("addGameShader", function(shader:FlxRuntimeShader)
		{
			if (shader == null)
			{
				onError("addGameShader: Shader is `null`.");
				return;
			}
			
			var cameras = [FlxG.camera, state.camHUD, state.camOther];
			for (camera in cameras)
				camera.addShader(shader);
		});
		setVariable("loadDifficulty", function(difficulty:String)
		{
			var song = Song.loadSong('${state.song.name}/$difficulty.json', Mods.currentMod);
			if (song == null)
				onError('loadDifficulty: Error loading difficulty "$difficulty".');
			return song;
		});
		setVariable("createVideoSprite", function(x:Float = 0, y:Float = 0, name:String, ?mod:String, loop:Bool = false, destroy:Bool = true)
		{
			var path = Paths.getVideo(name, mod);
			if (!Paths.exists(path))
			{
				onError('createVideoSprite: Could not find video "$name".');
				return null;
			}
			
			// The video is in a ZIP.
			if (!FileSystem.exists(path))
			{
				var tempPath = ".temp/" + path;
				if (!FileSystem.exists(tempPath))
				{
					// hxCodec currently only supports loading from files, so we must load it in a temporary folder.
					UnsafeUtil.createDirectory(Path.directory(tempPath));
					var bytes = Paths.getBytes(path);
					File.saveBytes(tempPath, bytes);
				}
				path = tempPath;
			}
			
			var video = new FlxVideoSprite();
			if (destroy)
				video.bitmap.onEndReached.add(video.destroy);
			video.play(path, loop);
			video.bitmap.rate = GameplayGlobals.playbackRate;
			return video;
		});
		setVariable("setupStrumline", function(char:Character, chartName:String)
		{
			if (char == null)
			{
				onError('setupStrumline: Character is `null`.');
				return null;
			}
			
			var song = Song.loadSong(Path.join([state.song.directory, chartName + '.json']), state.song.mod);
			if (song == null)
			{
				onError('setupStrumline: Error loading chart "$chartName".');
				return null;
			}
			
			var strumline = new FakeStrumline(state, char, song.notes);
			state.afterRulesetUpdate.add(function(elapsed)
			{
				strumline.update(elapsed);
			});
			return strumline;
		});
	}
	
	function pushLaneNotes<T:Any>(to:Array<T>, array:Array<Array<T>>)
	{
		for (lane in array)
		{
			for (note in lane)
				to.push(note);
		}
	}
	
	function getShader(name:String, glslVersion:Int = 120):FlxRuntimeShader
	{
		var nameInfo = CoolUtil.getNameInfo(name, Mods.currentMod);
		var ogPath = 'data/shaders/' + nameInfo.name;
		var frag = Paths.getContent(Paths.getPath(ogPath + '.frag', nameInfo.mod));
		var vert = Paths.getContent(Paths.getPath(ogPath + '.vert', nameInfo.mod));
		if (frag == null && vert == null)
		{
			onError("Couldn't find shader \"" + name + '".');
			return null;
		}
		
		var shader = new FlxRuntimeShader(frag, vert, glslVersion);
		return shader;
	}
}

/**
	This creates a "fake" strumline, as in it won't be visible on-screen but it'll make a character sing notes.
**/
class FakeStrumline extends FlxBasic
{
	var state:PlayState;
	var char:Character;
	var notes:Array<NoteInfo> = [];
	var holdingNotes:Array<Note> = [];
	var skin:NoteSkin;
	
	public function new(state:PlayState, char:Character, notes:Array<NoteInfo>)
	{
		super();
		this.state = state;
		this.char = char;
		this.notes = notes;
		skin = NoteSkin.loadSkinFromName('fnf:default');
	}
	
	override function update(elapsed:Float)
	{
		var time = state.timing.audioPosition;
		while (notes.length > 0 && time >= notes[0].startTime)
		{
			var info = notes.shift();
			var note = new Note(info, null, null, skin);
			if (!note.noAnim)
			{
				if (note.heyNote)
					char.playSpecialAnim('hey', 0.6 / GameplayGlobals.playbackRate, true);
				else if (info.type == 'Play Animation')
				{
					var anim = info.params[0] != null ? info.params[0].trim() : '';
					if (char.animation.exists(anim))
					{
						var force = true;
						if (info.params[1] != null)
						{
							var param = info.params[1].trim();
							force = param != 'false' && param != '0';
						}
						char.playAnim(anim, force);
					}
					else
						playNoteAnim(note);
				}
				else if (info.type == 'Special Animation')
				{
					var anim = info.params[0] != null ? info.params[0].trim() : '';
					if (char.animation.exists(anim))
					{
						var time = info.params[1] != null ? Std.parseFloat(info.params[1].trim()) : Math.NaN;
						if (Math.isNaN(time) || time < 0)
							time = 0;
						var force = true;
						if (info.params[2] != null)
						{
							var param = info.params[2].trim();
							force = param != 'false' && param != '0';
						}
						char.playSpecialAnim(anim, time, force);
					}
					else
						playNoteAnim(note);
				}
				else
					playNoteAnim(note);
			}
		}
		
		var i = holdingNotes.length - 1;
		while (i >= 0)
		{
			var note = holdingNotes[i];
			if (time >= note.info.endTime)
			{
				note.currentlyBeingHeld = false;
				note.destroy();
				holdingNotes.remove(note);
			}
			i--;
		}
	}
	
	override function destroy()
	{
		super.destroy();
		notes = null;
		if (holdingNotes != null)
		{
			for (note in holdingNotes)
				note.destroy();
		}
		holdingNotes = null;
		skin = null;
	}
	
	function playNoteAnim(note:Note)
	{
		char.playNoteAnim(note, state.getBeatLength());
		if (note.info.isLongNote)
		{
			note.currentlyBeingHeld = true;
			holdingNotes.push(note);
		}
		else
			note.destroy();
	}
}
