package backend.scripts;

import backend.game.GameplayGlobals;
import backend.structures.skin.NoteSkin;
import backend.structures.song.NoteInfo;
import backend.structures.song.Song;
import backend.util.UnsafeUtil;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxRuntimeShader;
import flixel.math.FlxMath;
import haxe.io.Path;
import hxcodec.flixel.FlxVideoSprite;
import objects.game.Character;
import objects.game.Note;
import openfl.display.BitmapData;
import openfl.filters.ShaderFilter;
import states.PlayState;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class PlayStateScript
{
	public static var shaders:Map<String, FlxRuntimeShader> = [];
	
	public static function implement(script:Script, state:PlayState)
	{
		script.set("state", state);
		script.set("members", state.members);
		script.set("opponent", state.opponent);
		script.set("bf", state.bf);
		script.set("gf", state.gf);
		script.set("camFollow", state.camFollow);
		script.set("ruleset", state.ruleset);
		script.set("timing", state.timing);
		script.set("song", state.song);
		script.set("songName", state.song.name);
		script.set("difficultyName", state.song.difficultyName);
		script.set("camHUD", state.camHUD);
		script.set("camOther", state.camOther);
		script.set("inst", state.inst);
		script.set("vocals", state.vocals);
		script.set("statsDisplay", state.statsDisplay);
		script.set("judgementDisplay", state.judgementDisplay);
		script.set("songInfoDisplay", state.songInfoDisplay);
		script.set("lyricsDisplay", state.lyricsDisplay);
		script.set("healthBars", state.healthBars);
		script.set("deathBG", state.deathBG);
		script.set("backgroundCover", state.backgroundCover);
		script.set("judgementCounters", state.judgementCounters);
		script.set("npsDisplay", state.npsDisplay);
		script.set("msDisplay", state.msDisplay);
		script.set("staticBG", state.staticBG);
		script.set("playbackRate", GameplayGlobals.playbackRate);
		
		script.set("add", state.add);
		script.set("insert", state.insert);
		script.set("remove", state.remove);
		script.set("precacheGraphic", state.precacheGraphic);
		script.set("precacheImage", state.precacheImage);
		script.set("precacheCharacter", state.precacheCharacter);
		
		script.set("getOrder", function(obj:FlxBasic)
		{
			return state.members.indexOf(obj);
		});
		script.set("setOrder", function(obj:FlxBasic, index:Int)
		{
			state.remove(obj, true);
			return state.insert(index, obj);
		});
		
		script.set("addBehindChars", function(obj:FlxBasic)
		{
			final index = FlxMath.minInt(FlxMath.minInt(state.members.indexOf(state.gf), state.members.indexOf(state.opponent)),
				state.members.indexOf(state.bf));
			return state.insert(index, obj);
		});
		script.set("addOverChars", function(obj:FlxBasic)
		{
			final index = FlxMath.maxInt(FlxMath.maxInt(state.members.indexOf(state.gf), state.members.indexOf(state.opponent)),
				state.members.indexOf(state.bf));
			return state.insert(index + 1, obj);
		});
		script.set("addBehindOpponent", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.opponent), obj);
		});
		script.set("addBehindBF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.bf), obj);
		});
		script.set("addBehindGF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.gf), obj);
		});
		script.set("addOverOpponent", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.opponent) + 1, obj);
		});
		script.set("addOverBF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.bf) + 1, obj);
		});
		script.set("addOverGF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.gf) + 1, obj);
		});
		
		script.set("addBehindUI", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.ruleset.playfields[0]), obj);
		});
		
		script.set("getCharacters", function(?name:String, ?mod:String)
		{
			final characters:Array<Character> = [];
			final allChars = [state.gf, state.opponent, state.bf];
			for (char in allChars)
			{
				if (char.info != null && (name == null || char.info.name == name) && (mod == null || char.info.mod == mod))
					characters.push(char);
			}
			return characters;
		});
		script.set("getPlayerCharacter", function(player:Int = 0)
		{
			return state.getPlayerCharacter(player);
		});
		script.set("getNoteCharacter", function(note:Note)
		{
			return state.getNoteCharacter(note);
		});
		
		script.set("getCurrentNotes", function()
		{
			final notes:Array<Note> = [];
			for (playfield in state.ruleset.playfields)
			{
				final manager = playfield.noteManager;
				pushLaneNotes(notes, manager.activeNoteLanes);
				pushLaneNotes(notes, manager.heldLongNoteLanes);
				pushLaneNotes(notes, manager.deadNoteLanes);
			}
			return notes;
		});
		script.set("getActiveNotes", function()
		{
			final notes:Array<Note> = [];
			for (playfield in state.ruleset.playfields)
				pushLaneNotes(notes, playfield.noteManager.activeNoteLanes);
			return notes;
		});
		script.set("getHeldNotes", function()
		{
			final notes:Array<Note> = [];
			for (playfield in state.ruleset.playfields)
				pushLaneNotes(notes, playfield.noteManager.heldLongNoteLanes);
			return notes;
		});
		script.set("getDeadNotes", function()
		{
			final notes:Array<Note> = [];
			for (playfield in state.ruleset.playfields)
				pushLaneNotes(notes, playfield.noteManager.deadNoteLanes);
			return notes;
		});
		script.set("getQueueNotes", function()
		{
			final notes:Array<NoteInfo> = [];
			for (playfield in state.ruleset.playfields)
				pushLaneNotes(notes, playfield.noteManager.noteQueueLanes);
			return notes;
		});
		
		script.set("initShader", function(name:String)
		{
			return initShader(name);
		});
		script.set("setSpriteShader", function(sprite:FlxSprite, name:String)
		{
			if (sprite == null)
			{
				Main.showInternalNotification("setSpriteShader: Sprite is `null`.", ERROR);
				return false;
			}
			
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification("setSpriteShader: Shader is `null`.", ERROR);
				return false;
			}
			
			sprite.shader = shader;
			return true;
		});
		script.set("addShaderToCamera", function(name:String, ?camera:FlxCamera)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification("addShaderToCamera: Shader is `null`.", ERROR);
				return;
			}
				
			addShaderToCamera(shader, camera);
		});
		script.set("addGameShader", function(name:String)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification("addGameShader: Shader is `null`.", ERROR);
				return;
			}
			
			for (camera in [FlxG.camera, state.camHUD, state.camOther])
				addShaderToCamera(shader, camera);
		});
		script.set("getShaderFloat", function(name:String, variable:String)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('getShaderFloat: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			return shader.getFloat(variable);
		});
		script.set("setShaderFloat", function(name:String, variable:String, value:Float)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('setShaderFloat: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			shader.setFloat(variable, value);
			return value;
		});
		script.set("getShaderFloatArray", function(name:String, variable:String)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('getShaderFloatArray: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			return shader.getFloatArray(variable);
		});
		script.set("setShaderFloatArray", function(name:String, variable:String, value:Array<Float>)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('setShaderFloatArray: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			shader.setFloatArray(variable, value);
			return value;
		});
		script.set("getShaderInt", function(name:String, variable:String)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('getShaderInt: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			return shader.getInt(variable);
		});
		script.set("setShaderInt", function(name:String, variable:String, value:Int)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('setShaderInt: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			shader.setInt(variable, value);
			return value;
		});
		script.set("getShaderIntArray", function(name:String, variable:String)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('getShaderIntArray: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			return shader.getIntArray(variable);
		});
		script.set("setShaderIntArray", function(name:String, variable:String, value:Array<Int>)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('setShaderIntArray: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			shader.setIntArray(variable, value);
			return value;
		});
		script.set("getShaderBool", function(name:String, variable:String)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('getShaderBool: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			return shader.getBool(variable);
		});
		script.set("setShaderBool", function(name:String, variable:String, value:Bool)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('setShaderBool: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			shader.setBool(variable, value);
			return value;
		});
		script.set("getShaderSampler2D", function(name:String, variable:String)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('getShaderSampler2D: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			return shader.getSampler2D(variable);
		});
		script.set("setShaderSampler2D", function(name:String, variable:String, value:BitmapData)
		{
			final shader = getShader(name);
			if (shader == null)
			{
				Main.showInternalNotification('setShaderSampler2D: Shader "$name" is not loaded.', ERROR);
				return null;
			}
			
			shader.setSampler2D(variable, value);
			return value;
		});
		
		script.set("loadDifficulty", function(difficulty:String)
		{
			final song = Song.loadSong('${state.song.name}/$difficulty.json', Mods.currentMod);
			if (song == null)
				Main.showInternalNotification('loadDifficulty: Error loading difficulty "$difficulty".', ERROR);
			return song;
		});
		
		script.set("createVideoSprite", function(x:Float = 0, y:Float = 0, name:String, ?mod:String, loop:Bool = false, destroy:Bool = true)
		{
			var path = Paths.getVideo(name, mod);
			if (!Paths.exists(path))
			{
				Main.showInternalNotification('createVideoSprite: Could not find video "$name".', ERROR);
				return null;
			}
			
			// The video is in a ZIP.
			if (!FileSystem.exists(path))
			{
				final tempPath = ".temp/" + path;
				if (!FileSystem.exists(tempPath))
				{
					// hxCodec currently only supports loading from files, so we must load it in a temporary folder.
					UnsafeUtil.createDirectory(Path.directory(tempPath));
					var bytes = Paths.getBytes(path);
					File.saveBytes(tempPath, bytes);
				}
				path = tempPath;
			}
			
			final video = new FlxVideoSprite();
			if (destroy)
				video.bitmap.onEndReached.add(video.destroy);
			video.play(path, loop);
			video.bitmap.rate = GameplayGlobals.playbackRate;
			return video;
		});
		
		script.set("setupStrumline", function(char:Character, chartName:String)
		{
			if (char == null)
			{
				Main.showInternalNotification('setupStrumline: Character is `null`.', ERROR);
				return null;
			}
			
			final song = Song.loadSong(Path.join([state.song.directory, chartName + '.json']), state.song.mod);
			if (song == null)
			{
				Main.showInternalNotification('setupStrumline: Error loading chart "$chartName".', ERROR);
				return null;
			}
			
			final strumline = new FakeStrumline(state, char, song.notes);
			state.afterRulesetUpdate.add(function(elapsed)
			{
				strumline.update(elapsed);
			});
			return strumline;
		});
	}
	
	public static function clear()
	{
		shaders.clear();
	}
	
	static inline function pushLaneNotes<T:Any>(to:Array<T>, array:Array<Array<T>>)
	{
		for (lane in array)
		{
			for (note in lane)
				to.push(note);
		}
	}
	
	static function initShader(name:String):FlxRuntimeShader
	{
		if (!Settings.shaders)
			return null;
			
		final nameInfo = CoolUtil.getNameInfo(name, Mods.currentMod);
		final shaderName = nameInfo.mod + ':' + nameInfo.name;
		
		if (shaders.exists(shaderName))
		{
			Main.showInternalNotification("initShader: Shader \"" + name + '" is already initialized.', ERROR);
			return shaders.get(shaderName);
		}
		
		final ogPath = 'data/shaders/' + nameInfo.name;
		final frag = Paths.getContent(Paths.getPath(ogPath + '.frag', nameInfo.mod));
		final vert = Paths.getContent(Paths.getPath(ogPath + '.vert', nameInfo.mod));
		
		if (frag == null && vert == null)
		{
			Main.showInternalNotification("Couldn't find shader \"" + name + '".', ERROR);
			return null;
		}
		
		shaders.set(shaderName, new FlxRuntimeShader(frag, vert));
		
		return shaders.get(shaderName);
	}
	
	static function getShaderName(name:String)
	{
		final nameInfo = CoolUtil.getNameInfo(name, Mods.currentMod);
		return nameInfo.mod + ':' + nameInfo.name;
	}
	
	static function getShader(name:String)
	{
		return shaders.get(getShaderName(name));
	}
	
	static function addShaderToCamera(shader:FlxRuntimeShader, ?camera:FlxCamera)
	{
		if (camera == null)
			camera = FlxG.camera;

		@:privateAccess
		var filters = camera._filters != null ? camera._filters : [];
		filters.push(new ShaderFilter(shader));
		camera.setFilters(filters);
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
