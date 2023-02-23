package states;

import data.PlayerSettings;
import data.song.TimingPoint;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import shaders.ColorSwap;
import sprites.DancingSprite;
import sprites.InfiniteEmitter;
import util.MusicTiming;

class TitleState extends FNFState
{
	static var initialized:Bool = false;

	var timing:MusicTiming;
	var startTimer:FlxTimer;
	var textGroup:FlxTypedGroup<FlxText>;
	var gradient:FlxSprite;
	var logo:DancingSprite;
	var gf:DancingSprite;
	var pressEnter:FlxSprite;
	var colorSwap:ColorSwap;
	var gradientAlpha:Float = 0;
	var gradientBop:Float = 0;
	var emitter:InfiniteEmitter;
	var startedIntro:Bool = false;
	var skippedIntro:Bool = false;
	var introText:Array<String>;
	var transitioning:Bool = false;

	override public function create()
	{
		if (!FlxG.sound.musicPlaying)
		{
			CoolUtil.playMenuMusic(initialized ? 1 : 0);
			if (!initialized)
				FlxG.sound.music.stop();
		}

		getIntroText();

		timing = new MusicTiming(FlxG.sound.music, null, TimingPoint.getMusicTimingPoints("Gettin' Freaky"));
		timing.onBeatHit.add(onBeatHit);

		colorSwap = new ColorSwap();

		gf = new DancingSprite(FlxG.width, FlxG.height * 0.07, Paths.getSpritesheet('menus/title/gfDanceTitle'));
		gf.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gf.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gf.setDancePreset(DOUBLE);
		gf.antialiasing = true;
		gf.shader = colorSwap.shader;
		timing.addDancingSprite(gf);
		add(gf);

		logo = new DancingSprite(-150, -100, Paths.getSpritesheet('menus/title/logoBumpin'));
		logo.animation.addByPrefix('idle', 'logo bumpin', 24, false);
		logo.dance();
		logo.y -= logo.height;
		logo.shader = colorSwap.shader;
		timing.addDancingSprite(logo);
		add(logo);

		emitter = new InfiniteEmitter(0, FlxG.height + 30);
		emitter.width = FlxG.width;
		emitter.loadParticles(Paths.getImage('menus/title/particle'), 10, 0);
		emitter.velocity.set(-500, -500, 500, -500);
		emitter.acceleration.set(0, -250, 0, -250);
		emitter.alpha.set(0.5, 0.8, 0, 0);
		emitter.lifespan.set(5, 10);
		emitter.start(false, 0.1);
		add(emitter);

		gradient = FlxGradient.createGradientFlxSprite(FlxG.width, Std.int(FlxG.height / 2) + 20, [0, FlxColor.WHITE]);
		gradient.y = FlxG.height / 2;
		gradient.antialiasing = true;
		gradient.alpha = 0;
		add(gradient);

		pressEnter = new FlxSprite(100, FlxG.height);
		pressEnter.frames = Paths.getSpritesheet('menus/title/titleEnter');
		pressEnter.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		pressEnter.animation.addByPrefix('press', "ENTER PRESSED", 24);
		pressEnter.animation.play('idle');
		pressEnter.antialiasing = true;
		add(pressEnter);

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
			startIntro();
		}

		super.create();
	}

	override public function update(elapsed:Float)
	{
		if (timing != null)
			timing.update(elapsed);

		if (!startedIntro)
		{
			if (CoolUtil.anyJustInputted())
			{
				startTimer.cancel();
				startIntro();
			}
		}
		else if (!skippedIntro)
		{
			if (PlayerSettings.checkAction(ACCEPT_P))
				skipIntro();
		}
		else if (!transitioning)
		{
			var pressedEnter = FlxG.keys.justPressed.ENTER;
			if (!pressedEnter)
			{
				for (i in 0...FlxG.gamepads.numActiveGamepads)
				{
					var gamepad = FlxG.gamepads.getByID(i);
					if (gamepad != null && gamepad.justPressed.START)
						pressedEnter = true;
				}
			}

			if (pressedEnter)
			{
				pressEnter.animation.play('press');
				pressEnter.centerOffsets();
				FlxG.camera.flash(FlxColor.WHITE, 1);
				CoolUtil.playConfirmSound();
				transitioning = true;
			}
		}

		if (PlayerSettings.checkAction(UI_LEFT))
			colorSwap.update(-elapsed * 0.1);
		else if (PlayerSettings.checkAction(UI_RIGHT))
			colorSwap.update(elapsed * 0.1);

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
		if (!initialized)
		{
			FlxG.sound.music.fadeIn(4, 0, 1);
		}
		FlxTween.num(0, 0.5, timing.timingPoints[0].beatLength * 0.002, null, function(num)
		{
			gradientAlpha = num;
		});
		startedIntro = true;
	}

	function onBeatHit(beat:Int, decBeat:Float)
	{
		var tweenDuration = timing.curTimingPoint.stepLength * 0.002;
		gradientBop = 0.5;
		FlxTween.num(0.5, 0, tweenDuration, null, function(num)
		{
			gradientBop = num;
		});
		gradient.y = (FlxG.height / 2) - 20;
		FlxTween.tween(gradient, {y: FlxG.height / 2}, tweenDuration);

		if (!skippedIntro)
		{
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
			FlxG.camera.flash(FlxColor.WHITE, 1);
			clearText();

			var tweenDuration = timing.curTimingPoint.beatLength * 0.002;
			FlxTween.tween(logo, {y: -100}, tweenDuration, {ease: FlxEase.quadInOut});
			FlxTween.tween(gf, {x: FlxG.width * 0.4}, tweenDuration, {ease: FlxEase.quadInOut});
			FlxTween.tween(pressEnter, {y: FlxG.height * 0.8}, tweenDuration, {ease: FlxEase.backOut, startDelay: timing.curTimingPoint.beatLength * 0.001});
			skippedIntro = true;
		}
	}
}
