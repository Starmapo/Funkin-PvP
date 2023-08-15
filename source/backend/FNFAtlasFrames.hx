package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets;

class FNFAtlasFrames extends FlxAtlasFrames
{
	public static function fromSparrow(source:FlxGraphicAsset, xml:FlxXmlAsset)
	{
		return createFrames(SPARROW, FlxAtlasFrames.fromSparrow(source, xml));
	}
	
	public static function fromSpriteSheetPacker(source:FlxGraphicAsset, description:String)
	{
		return createFrames(SPRITE_SHEET_PACKER, FlxAtlasFrames.fromSpriteSheetPacker(source, description));
	}
	
	public static function fromTexturePackerJson(source:FlxGraphicAsset, description:FlxTexturePackerJsonAsset, useFrameDuration = false):FlxAtlasFrames
	{
		return createFrames(TEXTURE_PACKER, FlxAtlasFrames.fromTexturePackerJson(source, description, useFrameDuration));
	}
	
	static inline function createFrames(atlasType:AtlasType, frames:FlxAtlasFrames)
	{
		return new FNFAtlasFrames(atlasType, frames);
	}
	
	public var atlasType:AtlasType;
	
	public function new(atlasType:AtlasType, frames:FlxAtlasFrames)
	{
		super(frames.parent, frames.border.copyTo());
		this.atlasType = atlasType;
		
		for (frame in frames.frames)
			pushFrame(frame);
			
		parent.getFramesCollections(ATLAS).remove(frames);
		frames.frames.resize(0); // prevents the frames from being destroyed
		frames.destroy();
	}
	
	public function checkAtlasName(name:String, atlasName:String)
	{
		return getAtlasName(name) == atlasName;
	}
	
	public function getAtlasName(name:String)
	{
		return switch (atlasType)
		{
			case TEXTURE_PACKER:
				name.substr(0, name.lastIndexOf('instance'));
			case SPRITE_SHEET_PACKER:
				name.substr(0, name.lastIndexOf('_'));
			case SPARROW:
				name.substr(0, name.length - 4);
		}
	}
}

enum AtlasType
{
	SPARROW;
	SPRITE_SHEET_PACKER;
	TEXTURE_PACKER;
}
