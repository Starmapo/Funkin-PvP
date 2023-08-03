package backend;

import backend.structures.Mod;
import backend.util.StringUtil;
import backend.util.VersionUtil;
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
		Paths.library.reset();
		
		final curVersion:Version = CoolUtil.getVersion();
		final apiVersionRule:VersionRule = '${curVersion.major}.${curVersion.minor}.${curVersion.patch}';
		
		final modsToLoad:Array<Mod> = [];
		for (file in FileSystem.readDirectory(modsPath))
		{
			final modID = Path.withoutExtension(file);
			final jsonPath = Path.join([modsPath, modID, 'mod.json']);
			if (Paths.exists(jsonPath))
			{
				final mod = Mod.getMod(jsonPath);
				if (mod == null)
					continue;
				if (!VersionUtil.match(mod.apiVersion, apiVersionRule))
				{
					mod.warnings.push('Mod "$modID" was built for incompatible API version ${mod.apiVersion}, expected "$apiVersionRule"');
					trace(mod.id);
				}
				mod.id = modID;
				modsToLoad.push(mod);
			}
			else
				Main.showInternalNotification('Could not find mod metadata file: $jsonPath', ERROR);
		}
		final filteredMods = filterDependencies(modsToLoad);
		filteredMods.sort(function(a, b)
		{
			return StringUtil.sortAlphabetically(a.title, b.title);
		});
		for (mod in filteredMods)
			currentMods.push(mod);
			
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
			if (Paths.exists(pvpMusicPath))
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
			if (Paths.exists(difficultiesPath))
			{
				var diffs = Paths.getContent(difficultiesPath).split('\n');
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
			if (Paths.exists(songSelectPath))
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
							if (Paths.exists(diffPath))
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
			if (Paths.exists(characterSelectPath))
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
			if (Paths.exists(noteskinList))
			{
				var list = Paths.getContent(noteskinList).split('\n');
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
			if (Paths.exists(judgementSkinList))
			{
				var list = Paths.getContent(judgementSkinList).split('\n');
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
			if (Paths.exists(splashSkinList))
			{
				var list = Paths.getContent(splashSkinList).split('\n');
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
	
	public static function getMod(id:String):Mod
	{
		for (mod in currentMods)
		{
			if (mod.id == id)
				return mod;
		}
		
		return null;
	}
	
	public static function hasMod(id:String):Bool
	{
		return getMod(id) != null;
	}
	
	static function filterDependencies(mods:Array<Mod>):Array<Mod>
	{
		var result:Array<Mod> = [];
		
		var modMap = new Map<String, Mod>();
		for (mod in mods)
			modMap.set(mod.id, mod);
			
		for (mod in mods)
		{
			var depError = false;
			if (mod.dependencies != null)
			{
				for (dep => depRule in mod.dependencies)
				{
					var depMod = modMap.get(dep);
					if (depMod == null)
					{
						Main.showInternalNotification('Dependency "$dep" not found, which is required for mod "${mod.id}".', ERROR);
						depError = true;
						break;
					}
					if (!VersionUtil.match(depMod.modVersion, depRule))
					{
						Main.showInternalNotification('Dependency "$dep" has version "${depMod.modVersion}", but requires "${VersionUtil.ruleToString(depRule)}" for mod "${mod.id}".',
							ERROR);
						depError = true;
						break;
					}
				}
			}
			
			if (!depError)
				result.push(mod);
		}
		
		return result;
	}
}

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
