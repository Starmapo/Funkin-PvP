package backend.structures;

import thx.semver.Version;
import thx.semver.VersionRule;

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
	
	// internal stuff
	public var id:String;
	public var characterCount:Int = 0;
	public var songCount:Int = 0;
	public var noteskinCount:Int = 0;
	public var judgementSkinCount:Int = 0;
	public var splashSkinCount:Int = 0;
	public var warnings:Array<String> = [];
	
	public function new() {}
	
	public static function getMod(path:String)
	{
		var data:Dynamic = Paths.getJson(path);
		if (data == null || data.length < 1)
		{
			Main.showInternalNotification('Error parsing mod metadata file ($path), was null or empty.', ERROR);
			return null;
		}
		
		var mod = new Mod();
		try
		{
			mod.apiVersion = mod.readString(data.api_version);
		}
		catch (e)
		{
			Main.showInternalNotification('Error parsing API version: ($e) metadata was $data', ERROR);
			return null;
		}
		try
		{
			mod.modVersion = mod.readString(data.mod_version);
		}
		catch (e)
		{
			Main.showInternalNotification('Error parsing mod version: ($e) metadata was $data', ERROR);
			return null;
		}
		
		mod.title = mod.readString(data.title, 'No Title');
		mod.description = mod.readString(data.description, 'No Description');
		mod.homepage = mod.readString(data.homepage);
		mod.dependencies = readModDependencies(data.dependencies);
		
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
