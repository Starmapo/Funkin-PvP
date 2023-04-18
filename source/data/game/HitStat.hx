package data.game;

import data.song.NoteInfo;

class HitStat
{
	public var type:HitStatType;
	public var keyPressType:KeyPressType;
	public var note:NoteInfo;
	public var songPosition:Int;
	public var judgement:Judgement;
	public var hitDifference:Int;
	public var accuracy:Float;

	public function new(type:HitStatType, keyPressType:KeyPressType, note:NoteInfo, songPosition:Int, judgement:Judgement, hitDifference:Int, accuracy:Float)
	{
		this.type = type;
		this.keyPressType = keyPressType;
		this.note = note;
		this.songPosition = songPosition;
		this.judgement = judgement;
		this.hitDifference = hitDifference;
		this.accuracy = accuracy;
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