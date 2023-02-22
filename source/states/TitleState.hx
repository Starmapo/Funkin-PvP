package states;

import data.PlayerSettings;
import data.song.TimingPoint;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import ui.AtlasText;
import util.MusicTiming;

class TitleState extends FNFState
{
	static var initialized:Bool = false;

	var timing:MusicTiming;
	var startTimer:FlxTimer;
	var textGroup:FlxTypedGroup<FlxText>;
	var skippedIntro:Bool = false;
	var introText:Array<String>;

	override public function create()
	{
		if (!FlxG.sound.musicPlaying)
		{
			CoolUtil.playMenuMusic(0);
			FlxG.sound.music.stop();
		}

		getIntroText();

		timing = new MusicTiming(FlxG.sound.music, null, [
			new TimingPoint({
				startTime: 0,
				bpm: 102,
				meter: 4
			})
		]);
		timing.onBeatHit.add(onBeatHit);

		textGroup = new FlxTypedGroup();
		add(textGroup);

		if (!initialized)
		{
			startTimer = FlxTimer.startTimer(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}

		super.create();
	}

	override public function update(elapsed:Float)
	{
		if (timing != null)
			timing.update(elapsed);

		if (startTimer != null && !startTimer.finished && PlayerSettings.anyJustPressed())
		{
			startTimer.cancel();
			startIntro();
		}

		super.update(elapsed);
	}

	function getIntroText()
	{
		var fullText:String = Paths.getText('introText');

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		introText = FlxG.random.getObject(swagGoodArray);
	}

	function startIntro()
	{
		FlxG.sound.music.fadeIn(4, 0, 1);
	}

	function onBeatHit(beat:Int, decBeat:Float)
	{
		if (!skippedIntro)
		{
			switch (beat)
			{
				case 0:
					addText('Starmapo');
				case 2:
					addText('presents', 200, true);
				case 4:
					resetTexts(['Friday Night Funkin', 'by'], 150);
				case 6:
					addTexts(['ninjamuffin99', 'PhantomArcade', 'Kawai Sprite', 'Evilsk8er', 'Newgrounds'], 150, true);
				case 8:
					resetText(introText[0].toUpperCase());
				case 10:
					addText(introText[1].toUpperCase(), 200, true);
				case 12:
					clearText();
				case 13:
					addText('Friday');
				case 14:
					addText('Night', 200, true);
				case 15:
					addText('Funkin', 200, true);
				case 16:
					skipIntro();
			}
		}
	}

	function addText(text:String, y:Float = 200, bottom:Bool = false)
	{
		var coolText = new FlxText(0, 0, 0, text);
		coolText.setFormat('PhantomMuff 1.5', 65, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		coolText.antialiasing = true;
		coolText.screenCenter(X);
		if (bottom)
			coolText.y = FlxG.height + (textGroup.length * 80);
		else
			coolText.y -= coolText.height;

		FlxTween.tween(coolText, {y: y + (textGroup.length * 60)}, timing.curTimingPoint.stepLength * 0.002, {ease: FlxEase.quadOut});

		textGroup.add(coolText);
	}

	function addTexts(texts:Array<String>, y:Float = 200, bottom:Bool = false)
	{
		for (text in texts)
		{
			addText(text, y, bottom);
		}
	}

	function clearText()
	{
		textGroup.destroyMembers();
	}

	function resetText(text:String, y:Float = 200, bottom:Bool = false)
	{
		clearText();
		addText(text, y, bottom);
	}

	function resetTexts(texts:Array<String>, y:Float = 200, bottom:Bool = false)
	{
		clearText();
		addTexts(texts, y, bottom);
	}

	function skipIntro()
	{
		if (!skippedIntro)
		{
			FlxG.camera.flash(FlxColor.WHITE, 4);
			clearText();
			skippedIntro = true;
		}
	}
}
