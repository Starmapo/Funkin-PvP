package data;

import flixel.util.FlxColor;

class CreditsData extends JsonObject
{
	public var groups:Array<CreditGroup> = [];

	public function new(data:Dynamic)
	{
		for (c in readArray(data.groups))
		{
			groups.push(new CreditGroup(c));
		}
	}

	override function destroy()
	{
		groups = null;
	}
}

class CreditGroup extends JsonObject
{
	public var name:String = '';
	public var credits:Array<Credit> = [];

	public function new(data:Dynamic)
	{
		name = readString(data.name, 'Unknown');
		for (c in readArray(data.credits))
		{
			credits.push(new Credit(c));
		}
	}

	override function destroy()
	{
		credits = null;
	}
}

class Credit extends JsonObject
{
	public var name:String;
	public var description:String;
	public var color:FlxColor;
	public var link:String;

	public function new(data:Dynamic)
	{
		name = readString(data.name, 'Unknown');
		description = readString(data.description, 'No Description Given');
		color = readColor(data.color, 0xFFFDE871, false);
		link = readString(data.link, '');
	}
}
