package states;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class TitleTest extends FNFState
{
	var textGroup:FlxTypedGroup<FlxText>;
	var introTexts:Array<Array<String>>;
	var curSelected:Int = 0;

	override function create()
	{
		textGroup = new FlxTypedGroup();
		add(textGroup);

		for (i in 0...2)
		{
			var coolText = new FlxText(0, 200 + (textGroup.length * 80));
			coolText.setFormat('PhantomMuff 1.5', 65, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			coolText.antialiasing = true;
			coolText.screenCenter(X);
			textGroup.add(coolText);
		}

		getIntroTexts();

		changeSelection();

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.LEFT)
		{
			if (FlxG.keys.pressed.SHIFT)
				changeSize(-1);
			else
				changeSelection(-1);
		}
		else if (FlxG.keys.justPressed.RIGHT)
		{
			if (FlxG.keys.pressed.SHIFT)
				changeSize(1);
			else
				changeSelection(1);
		}

		FlxG.watch.addQuick('Current Selected', curSelected);
		FlxG.watch.addQuick('Current Size', textGroup.members[0].size);

		super.update(elapsed);
	}

	function changeSelection(value:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + value, 0, introTexts.length - 1);

		var introText = introTexts[curSelected];
		for (i in 0...2)
		{
			textGroup.members[i].text = introText[i].toUpperCase();
			textGroup.members[i].screenCenter(X);
		}
	}

	function changeSize(value:Int = 0)
	{
		for (i in 0...2)
		{
			textGroup.members[i].size += value;
			textGroup.members[i].screenCenter(X);
		}
	}

	function getIntroTexts()
	{
		var fullText:String = Paths.getText('introText');

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		introTexts = swagGoodArray;
	}
}
