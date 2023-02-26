package data;

class CreditsData extends JsonObject
{
	public var credits:Array<Credit> = [];
	public var directory:String = '';

	public function new(data:Dynamic)
	{
		for (c in readArray(data.credits))
		{
			credits.push(new Credit(c));
		}
	}
}

class Credit extends JsonObject
{
	public var name:String;
	public var description:String;
	public var color:Array<Int>;
	public var link:String;

	public function new(data:Dynamic)
	{
		name = readString(data.name, 'Unknown');
		description = readString(data.description, 'No Description Given');
		color = readIntArray(data.color, [255, 255, 255], null, 3, 0, 255);
		link = readString(data.link, '');
	}
}
