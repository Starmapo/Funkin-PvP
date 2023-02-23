package states;

import data.PlayerSettings;
import data.song.TimingPoint;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import util.MusicTiming;

class TitleState extends FNFState
{
	static var initialized:Bool = false;

	var timing:MusicTiming;
	var startTimer:FlxTimer;
	var textGroup:FlxTypedGroup<FlxText>;
	var gradient:FlxSprite;
	var gradientAlpha:Float = 0;
	var gradientBop:Float = 0;
	var emitter:FlxEmitter;
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

		emitter = new FlxEmitter(FlxG.width / 2, FlxG.height + 50);
		emitter.loadParticles(Paths.getImage('titleScreen/particle'), 200, 0);
		emitter.velocity.set(-1000, -1000, 1000, -1000);
		emitter.alpha.set(0.5, 1, 0, 0);
		emitter.lifespan.set(1000);
		emitter.start(false, 0.1);
		add(emitter);

		gradient = FlxGradient.createGradientFlxSprite(FlxG.width, Std.int(FlxG.height / 2) + 20, [0, FlxColor.WHITE]);
		gradient.y = FlxG.height / 2;
		gradient.antialiasing = true;
		gradient.alpha = 0;
		add(gradient);

		textGroup = new FlxTypedGroup();
		add(textGroup);

		if (!initialized)
		{
			startTimer = FlxTimer.startTimer(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		else
		{
			skipIntro();
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

		// need to do this manually cause the alpha range doesn't work???
		// maybe im just missing something but this will have to do
		for (particle in emitter)
		{
			if (particle.alive && (particle.x + particle.width < 0 || particle.x >= FlxG.width || particle.y + particle.height < 0))
				particle.kill();
		}

		gradient.alpha = gradientAlpha + gradientBop;

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

		introText = swagGoodArray[FlxG.random.int(0, swagGoodArray.length - 1)];
	}

	function startIntro()
	{
		FlxG.sound.music.fadeIn(4, 0, 1);
		FlxTween.num(0, 0.5, timing.timingPoints[0].beatLength * 0.002, null, function(num)
		{
			gradientAlpha = num;
		});
	}

	function onBeatHit(beat:Int, decBeat:Float)
	{
		if (!skippedIntro)
		{
			var tweenDuration = timing.curTimingPoint.stepLength * 0.002;
			gradientBop = 0.5;
			FlxTween.num(0.5, 0, tweenDuration, null, function(num)
			{
				gradientBop = num;
			});
			gradient.y = (FlxG.height / 2) - 20;
			FlxTween.tween(gradient, {y: FlxG.height / 2}, tweenDuration);

			switch (beat)
			{
				case 0:
					addText('Starmapo');
				case 2:
					addText('presents', 0, true);
				case 4:
					resetTexts(['Friday Night Funkin', 'by'], -100);
				case 6:
					addTexts(['ninjamuffin99', 'PhantomArcade', 'Kawai Sprite', 'Evilsk8er', 'Newgrounds'], -100, true);
				case 8:
					resetText(introText[0].toUpperCase());
				case 10:
					addText(introText[1].toUpperCase(), 0, true);
				case 12:
					clearText();
				case 13:
					addText('Friday');
				case 14:
					addText('Night', 0, true);
				case 15:
					addText('Funkin', 0, true);
				case 16:
					skipIntro();
			}
		}
	}

	function addText(text:String, yOffset:Float = 0, bottom:Bool = false)
	{
		var coolText = new FlxText(0, 0, 0, text);
		coolText.setFormat('PhantomMuff 1.5', 65, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		coolText.antialiasing = true;
		if (coolText.width > FlxG.width)
		{
			var ratio = FlxG.width / coolText.width;
			coolText.size = Math.floor(coolText.size * ratio);
		}
		coolText.screenCenter(X);
		if (bottom)
			coolText.y = FlxG.height + (textGroup.length * 80);
		else
			coolText.y -= coolText.height;

		FlxTween.tween(coolText, {y: 200 + yOffset + (textGroup.length * 80)}, timing.curTimingPoint.stepLength * 0.002, {ease: FlxEase.quadOut});

		textGroup.add(coolText);
	}

	function addTexts(texts:Array<String>, yOffset:Float = 0, bottom:Bool = false)
	{
		for (text in texts)
		{
			addText(text, yOffset, bottom);
		}
	}

	function clearText()
	{
		textGroup.destroyMembers();
	}

	function resetText(text:String, yOffset:Float = 0, bottom:Bool = false)
	{
		clearText();
		addText(text, yOffset, bottom);
	}

	function resetTexts(texts:Array<String>, yOffset:Float = 0, bottom:Bool = false)
	{
		clearText();
		addTexts(texts, yOffset, bottom);
	}

	function skipIntro()
	{
		if (!skippedIntro)
		{
			FlxG.camera.flash(FlxColor.WHITE, 4);
			clearText();
			gradient.visible = false;
			skippedIntro = true;
		}
	}
}
