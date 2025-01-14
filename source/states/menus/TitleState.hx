package states.menus;

import backend.Music;
import backend.MusicTiming;
import backend.structures.song.TimingPoint;
import backend.util.UpdateUtil;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import objects.DancingSprite;
import objects.menus.InfiniteEmitter;
import openfl.system.System;
import shaders.ColorSwap;

using StringTools;

class TitleState extends FNFState
{
	static var logoY:Float = -50;
	static var initialized:Bool = false;
	static var hasCheckedUpdates:Bool = false;
	
	var camHUD:FlxCamera;
	var timing:MusicTiming;
	var startTimer:FlxTimer;
	var textGroup:FlxTypedGroup<FlxText>;
	var gradient:FlxSprite;
	var logo:DancingSprite;
	var icon:FlxSprite;
	var iconTween:FlxTween;
	var pressEnter:AnimatedSprite;
	var colorSwap:ColorSwap;
	var gradientAlpha:Float = 0;
	var gradientBop:Float = 0;
	var emitter:InfiniteEmitter;
	var startedIntro:Bool = false;
	var skippedIntro:Bool = false;
	var introText:Array<String>;
	var transitioning:Bool = false;
	
	override function destroy()
	{
		super.destroy();
		camHUD = null;
		timing = FlxDestroyUtil.destroy(timing);
		startTimer = FlxDestroyUtil.destroy(startTimer);
		textGroup = null;
		gradient = null;
		logo = null;
		icon = null;
		iconTween = null;
		pressEnter = null;
		colorSwap = null;
		emitter = null;
		introText = null;
	}
	
	override public function create()
	{
		DiscordClient.changePresence(null, "Title Screen");
		
		transIn = transOut = null;
		
		FlxG.camera.bgColor = 0;
		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);
		
		if (!Music.playing)
			Music.playMenuMusic();
			
		timing = new MusicTiming(FlxG.sound.music, TimingPoint.getMusicTimingPoints("Gettin' Freaky"), !initialized, 0, onBeatHit);
		
		if (!initialized)
			timing.stopMusic();
			
		getIntroText();
		
		colorSwap = new ColorSwap();
		
		icon = new FlxSprite(FlxG.width, 0, Paths.getImage('menus/title/iconTitle'));
		icon.screenCenter(Y);
		icon.shader = colorSwap.shader;
		icon.antialiasing = Settings.antialiasing;
		add(icon);
		
		logo = new DancingSprite(-100, logoY, Paths.getSpritesheet('menus/title/logoBumpin'));
		logo.addAnim({
			name: 'idle',
			prefix: 'logo bumpin',
			loop: false
		});
		logo.forceRestartDance = true;
		logo.dance();
		logo.y -= logo.height;
		logo.shader = colorSwap.shader;
		logo.antialiasing = Settings.antialiasing;
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
		gradient.alpha = 0;
		add(gradient);
		
		pressEnter = new AnimatedSprite(100, FlxG.height, Paths.getSpritesheet('menus/title/titleEnter'));
		pressEnter.addAnim({
			name: 'idle',
			prefix: 'Press Enter to Begin'
		}, true);
		pressEnter.addAnim({
			name: 'press',
			prefix: 'ENTER PRESSED'
		});
		pressEnter.antialiasing = Settings.antialiasing;
		add(pressEnter);
		
		textGroup = new FlxTypedGroup();
		add(textGroup);
		
		if (!initialized)
		{
			startTimer = new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		else
			startIntro();
			
		CoolUtil.playConfirmSound(0);
		
		super.create();
	}
	
	override public function update(elapsed:Float)
	{
		if (timing != null)
			timing.update(elapsed);
			
		if (!startedIntro)
		{
			if (Controls.anyInputJustPressed())
			{
				startTimer.cancel();
				startIntro();
			}
		}
		else if (!skippedIntro)
		{
			if (Controls.anyJustPressed(ACCEPT))
				skipIntro();
		}
		else if (!transitioning)
		{
			var pressedEnter = Controls.anyJustPressed(ACCEPT) || FlxG.keys.justPressed.ENTER;
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
				onPressEnter();
			#if sys
			else if (Controls.anyJustPressed(BACK))
				onExit();
			#end
		}
		
		if (Controls.anyPressed(UI_LEFT))
			colorSwap.update(-elapsed * 0.1);
		else if (Controls.anyPressed(UI_RIGHT))
			colorSwap.update(elapsed * 0.1);
			
		for (particle in emitter)
		{
			if (particle.alive && (particle.x + particle.width < 0 || particle.x >= FlxG.width || particle.y + particle.height < 0))
				particle.kill();
		}
		
		gradient.alpha = gradientAlpha + gradientBop;
		
		super.update(elapsed);
		
		if (Controls.anyJustPressed(RESET))
			CoolUtil.restart();
	}
	
	function getIntroText()
	{
		var fullText:String = Paths.getText('introText');
		
		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];
		
		for (i in firstArray)
			swagGoodArray.push(i.trim().split('--'));
			
		introText = swagGoodArray[FlxG.random.int(0, swagGoodArray.length - 1)];
	}
	
	function startIntro()
	{
		FlxTween.num(0, 0.5, timing.timingPoints[0].beatLength * 0.002, null, function(num)
		{
			gradientAlpha = num;
		});
		if (!initialized)
		{
			timing.playMusic();
			FlxG.sound.music.fadeIn(4);
		}
		else
			skipIntro();
		startedIntro = true;
		initialized = true;
	}
	
	function onBeatHit(beat:Int, decBeat:Float)
	{
		if (!startedIntro)
			return;
			
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
					addTexts(['ninjamuffin99', 'PhantomArcade', 'Kawai Sprite', 'evilsk8er', 'Newgrounds'], -100, true);
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
		else
		{
			icon.scale.set(1.1, 1.1);
			if (iconTween != null)
				iconTween.cancel();
			FlxTween.tween(icon.scale, {x: 1, y: 1}, 0.55, {ease: FlxEase.cubeOut});
		}
	}
	
	function addText(text:String, yOffset:Float = 0, bottom:Bool = false)
	{
		var coolText = new FlxText(0, 0, 0, text);
		coolText.setFormat(Paths.FONT_PHANTOMMUFF, 65, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
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
			addText(text, yOffset, bottom);
	}
	
	function clearText()
	{
		textGroup.forEach(function(text)
		{
			text.destroy();
		});
		textGroup.clear();
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
			camHUD.flash(FlxColor.WHITE, 1);
			clearText();
			var tweenDuration = timing.timingPoints[0].beatLength * 0.002;
			FlxTween.tween(logo, {y: logoY}, tweenDuration, {ease: FlxEase.quadInOut});
			FlxTween.tween(icon, {x: FlxG.width * 0.62}, tweenDuration, {ease: FlxEase.quadInOut});
			FlxTween.tween(pressEnter, {y: FlxG.height * 0.8}, tweenDuration, {ease: FlxEase.backOut, startDelay: timing.timingPoints[0].beatLength * 0.001});
			skippedIntro = true;
		}
	}
	
	function onPressEnter()
	{
		if (!transitioning)
		{
			pressEnter.playAnim('press');
			if (!Settings.flashing)
				pressEnter.animation.pause();
			var duration = Main.getTransitionTime();
			camHUD.flash(FlxColor.WHITE, duration);
			FlxTween.tween(pressEnter, {y: FlxG.height + pressEnter.height}, duration, {ease: FlxEase.backIn, startDelay: 0.2});
			FlxTween.tween(FlxG.camera, {y: FlxG.height}, duration, {
				ease: FlxEase.expoIn,
				onComplete: function(_)
				{
					exitMenu();
				},
				startDelay: 0.2
			});
			CoolUtil.playConfirmSound();
			transitioning = true;
		}
	}
	
	function exitMenu()
	{
		var updateCheck:UpdateCheckCallback = !hasCheckedUpdates && Settings.checkForUpdates ? UpdateUtil.checkForUpdates() : null;
		hasCheckedUpdates = true;
		
		if (updateCheck != null && updateCheck.newUpdate)
			FlxG.switchState(new UpdateState(updateCheck));
		else
			FlxG.switchState(new MainMenuState());
	}
	
	#if sys
	function onExit()
	{
		FlxG.camera.fade(FlxColor.BLACK, 1, false, function()
		{
			System.exit(0);
		}, true);
		FlxG.sound.music.fadeOut(1, 0);
		transitioning = true;
	}
	#end
}
