package data;

import flixel.FlxG;

class Mods
{
	public static final modsPath:String = 'mods';
	public static var currentMods:Array<Mod> = [];
	public static var currentMod:String = '';
	public static var pvpMusic:Array<String> = [];
	public static var songGroups:Map<String, ModSongGroup> = [];
	public static var characterGroups:Map<String, ModCharacterGroup> = [];
	public static var skins:Map<String, ModSkins> = new Map();
}

class Mod extends JsonObject
{
	public var directory:String;
	public var name:String;
	public var author:String;
	public var description:String;
	public var modVersion:String;
	public var gameVersion:String;

	public function new(data:Dynamic)
	{
		name = readString(data.name, 'Unknown Mod');
		author = readString(data.author, 'Unknown Author');
		description = readString(data.description, 'No Description');
		modVersion = readString(data.modVersion, '1.0.0');
		gameVersion = readString(data.gameVersion, FlxG.stage.application.meta["version"]);
	}
}

typedef ModSongGroup =
{
	var name:String;
	var bg:String;
	var songs:Array<ModSong>;
}

typedef ModSong =
{
	var name:String;
	var icon:String;
	var difficulties:Array<String>;
	var directory:String;
}

typedef ModCharacterGroup =
{
	var name:String;
	var bg:String;
	var chars:Array<ModCharacter>;
}

typedef ModCharacter =
{
	var name:String;
	var displayName:String;
	var directory:String;
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
