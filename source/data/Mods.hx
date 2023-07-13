package data;

import CoolUtil.NameInfo;
import flixel.FlxG;
import haxe.io.Path;
import sys.FileSystem;
import thx.semver.Version;
import thx.semver.VersionRule;

using StringTools;

class Mods
{
	public static final modsPath:String = 'mods';
	public static var currentMods:Array<Mod> = [];
	public static var currentMod:String = '';
	public static var pvpMusic:Array<NameInfo> = [];
	public static var songGroups:Map<String, ModSongGroup> = [];
	public static var characterGroups:Map<String, ModCharacterGroup> = [];
	public static var skins:Map<String, ModSkins> = new Map();
	
	public static function reloadMods()
	{
		currentMods.resize(0);
		currentMod = '';
		
		var directories:Array<String> = [];
		for (file in FileSystem.readDirectory(modsPath))
		{
			if (directories.contains(file))
				continue;
			var fullPath = Path.join([modsPath, file]);
			var jsonPath = Path.join([fullPath, 'mod.json']);
			if (FileSystem.isDirectory(fullPath))
			{
				if (FileSystem.exists(jsonPath))
				{
					var mod = Mod.getMod(Paths.getJson(jsonPath));
					if (mod == null)
						continue;
					mod.id = file;
					currentMods.push(mod);
					directories.push(file);
				}
				else
					FlxG.log.error('Could not find mod metadata file: $jsonPath');
			}
		}
		
		reloadPvPMusic();
		reloadSongs();
		reloadCharacters();
		reloadSkins();
	}
	
	public static function reloadPvPMusic()
	{
		pvpMusic.resize(0);
		
		for (mod in currentMods)
		{
			var fullPath = Path.join([modsPath, mod.id]);
			var pvpMusicPath = Path.join([fullPath, 'data/pvpMusic.txt']);
			if (FileSystem.exists(pvpMusicPath))
			{
				var pvpMusicList = Paths.getText(pvpMusicPath).split('\n');
				for (i in 0...pvpMusicList.length)
					pvpMusic.push({
						name: pvpMusicList[i].trim(),
						mod: mod.id
					});
			}
		}
	}
	
	public static function reloadSongs()
	{
		songGroups.clear();
		for (mod in currentMods)
		{
			mod.songCount = 0;
			
			var fullPath = Path.join([modsPath, mod.id]);
			
			var difficulties:Array<String> = [];
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
			
			if (difficulties.length < 1)
				difficulties = ['Easy', 'Normal', 'Hard'];
				
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
						var songData:Dynamic = group.songs[i];
						var name = songData.name;
						var icon:String = songData.icon;
						if (icon == null)
							icon = '';
						if (icon.length > 0 && !icon.contains(':'))
							icon = mod.id + ':' + icon;
							
						var songPath = Paths.getPath('songs/$name', mod.id);
						var songDifficulties:Array<String> = [];
						for (diff in difficulties)
						{
							var diffPath = Path.join([songPath, diff + '.json']);
							if (FileSystem.exists(diffPath))
								songDifficulties.push(diff);
						}
						if (songDifficulties.length > 0)
						{
							var forceCharacters:Bool = songData.forceCharacters;
							songs.push({
								name: name,
								icon: icon,
								forceCharacters: forceCharacters,
								forceCharacterDifficulties: songData.forceCharacterDifficulties != null ? songData.forceCharacterDifficulties : [],
								difficulties: songDifficulties,
								id: mod.id
							});
							mod.songCount++;
						}
					}
					
					if (songs.length > 0)
					{
						var songGroup = songGroups.get(group.name);
						if (songGroup == null)
						{
							songGroup = {
								name: group.name,
								songs: [],
								id: mod.id
							};
							songGroups.set(group.name, songGroup);
						}
						for (song in songs)
							songGroup.songs.push(song);
					}
				}
			}
		}
	}
	
	public static function reloadCharacters()
	{
		characterGroups.clear();
		for (mod in currentMods)
		{
			mod.characterCount = 0;
			
			var fullPath = Path.join([modsPath, mod.id]);
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
								id: mod.id
							});
							mod.characterCount++;
						}
					}
					
					if (chars.length > 0)
					{
						var charGroup = characterGroups.get(group.name);
						if (charGroup == null)
						{
							charGroup = {
								name: group.name,
								chars: [],
								id: mod.id
							};
							characterGroups.set(group.name, charGroup);
						}
						for (char in chars)
							charGroup.chars.push(char);
					}
				}
			}
		}
	}
	
	public static function reloadSkins()
	{
		skins.clear();
		for (mod in currentMods)
		{
			mod.splashSkinCount = mod.judgementSkinCount = mod.noteskinCount = 0;
			
			var fullPath = Path.join([modsPath, mod.id]);
			var skinGroup:ModSkins = {
				name: mod.title,
				noteskins: [],
				judgementSkins: [],
				splashSkins: []
			};
			skins.set(mod.id, skinGroup);
			
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
						mod: mod.id
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
						mod: mod.id
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
						mod: mod.id
					});
					mod.splashSkinCount++;
				}
			}
		}
	}
	
	public static function getMods():Array<String>
	{
		var mods:Array<String> = [];
		for (mod in currentMods)
			mods.push(mod.id);
		return mods;
	}
	
	public static function hasMod(id:String):Bool
	{
		for (mod in currentMods)
		{
			if (mod.id == id)
				return true;
		}
		
		return false;
	}
}

/**
	An object containing info about a mod, including its metadata.
**/
class Mod extends JsonObject
{
	public var title:String;
	public var description:String;
	public var homepage:String;
	public var apiVersion:Version;
	public var modVersion:Version;
	public var dependencies:ModDependencies;
	public var optionalDependencies:ModDependencies;
	
	// internal stuff
	public var id:String;
	public var characterCount:Int = 0;
	public var songCount:Int = 0;
	public var noteskinCount:Int = 0;
	public var judgementSkinCount:Int = 0;
	public var splashSkinCount:Int = 0;
	
	public function new() {}
	
	public static function getMod(data:Dynamic)
	{
		var mod = new Mod();
		try
		{
			mod.apiVersion = mod.readString(data.api_version);
		}
		catch (e)
		{
			FlxG.log.error('Error parsing API version: ($e) metadata was $data');
			return null;
		}
		try
		{
			mod.modVersion = mod.readString(data.mod_version);
		}
		catch (e)
		{
			FlxG.log.error('Error parsing mod version: ($e) metadata was $data');
			return null;
		}
		
		mod.title = mod.readString(data.title, 'No Title');
		mod.description = mod.readString(data.description, 'No Description');
		mod.homepage = mod.readString(data.homepage);
		mod.dependencies = readModDependencies(data.dependencies);
		mod.optionalDependencies = readModDependencies(data.optionalDependencies);
		
		return mod;
	}
	
	public static function readModDependencies(data:Dynamic)
	{
		var map = new ModDependencies();
		if (data == null)
			return map;
		for (field in Reflect.fields(data))
		{
			var fieldVal = Reflect.field(data, field);
			map.set(field, VersionRule.stringToVersionRule(fieldVal));
		}
		return map;
	}
}

/**
 * A type representing a mod's dependencies.
 * 
 * The map takes the mod's ID as the key and the required version as the value.
 * The version follows the Semantic Versioning format, with `*.*.*` meaning any version.
 */
typedef ModDependencies = Map<String, VersionRule>;

typedef ModSongGroup =
{
	var name:String;
	var songs:Array<ModSong>;
	var id:String;
}

typedef ModSong =
{
	var name:String;
	var icon:String;
	var forceCharacters:Bool;
	var forceCharacterDifficulties:Array<String>;
	var difficulties:Array<String>;
	var id:String;
}

typedef ModCharacterGroup =
{
	var name:String;
	var chars:Array<ModCharacter>;
	var id:String;
}

typedef ModCharacter =
{
	var name:String;
	var displayName:String;
	var id:String;
}

typedef ModSkins =
{
	var name:String;
	var noteskins:Array<ModSkin>;
	var judgementSkins:Array<ModSkin>;
	var splashSkins:Array<ModSkin>;
}

typedef ModSkin =
{
	var name:String;
	var displayName:String;
	var mod:String;
}
