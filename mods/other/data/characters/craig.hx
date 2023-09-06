var chars:Array<Character>;
var charBlinks:ObjectMap<Character, Int> = new ObjectMap();

function onCreate()
{
	for (char in getCharacters("craig", "other"))
	{
		charBlinks[char] = resetBlinks();
		char.onDance.add(function(anim) {onDance(char, anim);});
	}
}

function onDance(char, anim)
{
	charBlinks[char] -= 1;
	if (charBlinks[char] <= 0)
	{
		char.playAnim(anim + "-blink");
		charBlinks[char] = resetBlinks();
	}
}

function resetBlinks()
{
	return FlxG.random.int(2, 4);
}