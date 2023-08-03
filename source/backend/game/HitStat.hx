package backend.game;

import backend.structures.song.NoteInfo;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

/**
	Information for a hit/missed note.
**/
class HitStat implements IFlxDestroyable
{
	/**
		The type of this stat (`HIT` or `MISS`).
	**/
	public var type:HitStatType;
	
	/**
		The key press type of this stat (`NONE`, `PRESS`, or `RELEASE`).
	**/
	public var keyPressType:KeyPressType;
	
	/**
		The related note of this stat.
	**/
	public var note:NoteInfo;
	
	/**
		The song position of this stat.
	**/
	public var songPosition:Float;
	
	/**
		The judgement of this stat.
	**/
	public var judgement:Judgement;
	
	/**
		The hit difference of this stat.
	**/
	public var hitDifference:Float;
	
	/**
		The last accuracy of the player before this stat.
	**/
	public var accuracy:Float;
	
	/**
		The last health of the player before this stat.
	**/
	public var health:Float;
	
	public function new(type:HitStatType, keyPressType:KeyPressType, note:NoteInfo, songPosition:Float, judgement:Judgement, hitDifference:Float,
			accuracy:Float, health:Float)
	{
		this.type = type;
		this.keyPressType = keyPressType;
		this.note = note;
		this.songPosition = songPosition;
		this.judgement = judgement;
		this.hitDifference = hitDifference;
		this.accuracy = accuracy;
		this.health = health;
	}
	
	/**
		Frees up memory.
	**/
	public function destroy()
	{
		note = null;
	}
}

/**
	The type of a `HitStat`.
**/
enum HitStatType
{
	HIT;
	MISS;
}

/**
	The key press type of a `HitStat`.
**/
enum KeyPressType
{
	NONE;
	PRESS;
	RELEASE;
}
