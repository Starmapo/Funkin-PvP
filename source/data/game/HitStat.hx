package data.game;

import data.song.NoteInfo;

class HitStat
{
	public var type:HitStatType;
	public var keyPressType:KeyPressType;
	public var note:NoteInfo;
	public var songPosition:Float;
	public var judgement:Judgement;
	public var hitDifference:Float;
	public var accuracy:Float;
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
}

enum HitStatType
{
	HIT;
	MISS;
}

enum KeyPressType
{
	NONE;
	PRESS;
	RELEASE;
}
