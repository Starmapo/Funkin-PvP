import("flixel.effects.particles.FlxEmitterMode");
import("flixel.effects.particles.FlxTypedEmitter");

var brightShader:FlxRuntimeShader;
var defaultBrightVal:Float = -0.05;
var brightSpeed:Float = 0.5;
var brightMagnitude:Float = 0.05;
var bgs:Array<FlxSprite> = [];
var randomPick:Int;
var oldRando:Int;
var nmStairs:Bool = false;
var inBlackout:Bool = false;
var transition:FlxSprite;
var backbg:FlxTypedGroup<FlxSprite>;
var frontbg:FlxTypedGroup<FlxSprite>;
var stairsBG:FlxBackdrop;
var stairs:FlxSprite;
var stairsGradient:FlxSprite;
var stairsChainL:FlxBackdrop;
var stairsChainR:FlxBackdrop;
var stairsGrp:FlxTypedGroup<FlxSprite>;
var iskinky = false;
var infiniteResize:Float = 2.3;
var emitt:FlxTypedGroup<FlxTypedEmitter>;
var darkHallway:FlxSprite;

function onCreatePost()
{
	var bgAmount = Settings.lowQuality ? 1 : 5;
	for (i in 0...bgAmount)
	{
		var bg = new FlxSprite();
		var imgName:String = 'Fuck_the_hallway';
		var animName:String = '';
		switch (i)
		{
			case 0:
				animName = 'Loop01 instance 1';
			case 1:
				animName = 'Loop02 instance 1';
			case 2:
				animName = 'Loop03 instance 1';
			case 3:
				animName = 'Loop04 instance 1';
			case 4:
				animName = 'Loop05 instance 1';
		}

		bg.frames = Paths.getSpritesheet('stages/factory-chase/' + imgName);
		bg.animation.addByPrefix('bruh', animName, 75, false);
		bg.setGraphicSize(Std.int(bg.width * 3));
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set(0.8, 0.8);
		bg.y -= 50;
		bg.antialiasing = true;
		bg.alpha = 0.0001;
		addBehindChars(bg);

		bgs.push(bg);
	}
	
	randomPick = FlxG.random.int(0, bgs.length - 1);
	oldRando = randomPick;
	
	bgs[randomPick].alpha = 1;
	bgs[randomPick].animation.play('bruh', true);
	
	if (!Settings.lowQuality)
	{
		darkHallway = new FlxSprite();
		darkHallway.frames = Paths.getSpritesheet('stages/factory-chase/Fuck_the_hallway');
		darkHallway.animation.addByPrefix('bruh', 'Tunnel instance 1', 75, false);
		darkHallway.setGraphicSize(Std.int(darkHallway.width * infiniteResize));
		darkHallway.updateHitbox();
		darkHallway.screenCenter();
		darkHallway.x -= 200;
		darkHallway.scrollFactor.set(0.8, 0.8);
		darkHallway.antialiasing = true;
		darkHallway.alpha = 0.0001;
		addBehindChars(darkHallway);
		darkHallway.animation.play('bruh', true);
						
		transition = new FlxSprite();
		transition.frames = Paths.getSpritesheet('stages/factory-chase/Trans');
		transition.animation.addByPrefix('bruh', 'beb instance 1', 24, false);
		transition.setGraphicSize(Std.int(transition.width * infiniteResize));
		transition.updateHitbox();
		transition.screenCenter();
		transition.scrollFactor.set(0.8, 0.8);
		transition.antialiasing = true;
		transition.alpha = 0.0001;
		transition.animation.play('bruh', true);
		transition.cameras = [camHUD];
		addBehindUI(transition);
		
		stairsGradient = new FlxSprite(0, -1).loadGraphic(Paths.getImage('stages/factory-chase/gradient'));
		stairsGradient.updateHitbox();
		stairsGradient.screenCenter();
		stairsGradient.blend = BlendMode.OVERLAY;
		
		stairsGrp = new FlxTypedGroup();
		add(stairsGrp);
		
		backbg = new FlxTypedGroup();
		addBehindChars(backbg);
		
		frontbg = new FlxTypedGroup();
		add(frontbg);
		
		var strings = ['0','4','3','2','6_BLEND_MODE_ADD'];
		for (killme in 0...5)
		{
			var bg:FlxSprite = new FlxSprite();
			bg.loadGraphic(Paths.getImage('stages/factory-chase/C_0' + strings[killme]));
			if (killme == 4)
				bg.blend = BlendMode.ADD;
			backbg.add(bg);
		}
		
		for (i in 0...3)
		{
			var bg:FlxSprite = new FlxSprite();
			bg.loadGraphic(Paths.getImage('stages/factory-chase/C_01'));
			bg.x += i * bg.width;
			frontbg.add(bg);
		}
		
		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getImage('stages/factory-chase/C_05'));
		frontbg.add(bg);

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getImage('stages/factory-chase/C_07'));
		frontbg.add(bg);
		
		for (i in frontbg)
		{
			i.scrollFactor.set();
			i.alpha = 0.00001;
			i.setGraphicSize(Std.int(FlxG.width * 1.815));
			i.screenCenter();
			i.antialiasing = true;
		}
		
		for (i in 0...3)
		{
			frontbg.members[i].x += i * FlxG.width * 1.815;
		}

		for (i in backbg)
		{
			i.scrollFactor.set(0, 0);
			i.alpha = 0.00001;
			i.setGraphicSize(Std.int(FlxG.width * 1.815));
			i.screenCenter();
			i.antialiasing = true;
		}

		for (i in 1...5)
		{
			backbg.members[i].x += 300;
		}
		
		emitt = new FlxTypedGroup();
		for (i in 0...3)
		{
			var emitter:FlxTypedEmitter;
			emitter = new FlxTypedEmitter(FlxG.width * 1.85 / 2 - 2500, 1300);
			emitter.scale.set(0.9, 0.9, 2, 2, 0.9, 0.9, 1, 1);
			emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
			emitter.width = FlxG.width * 2;
			emitter.alpha.set(1, 1, 1, 0);
			emitter.lifespan.set(5 / playbackRate, 10 / playbackRate);
			emitter.launchMode = FlxEmitterMode.SQUARE;
			emitter.velocity.set(-50 * playbackRate, -150 * playbackRate, 50 * playbackRate, -750 * playbackRate, -100 * playbackRate, 0, 100 * playbackRate, -100 * playbackRate);
			emitter.loadParticles(Paths.getImage('stages/factory-chase/Particlestuff' + i), 500, 16, true);
			emitter.start(false, FlxG.random.float(0.2, 0.3) / playbackRate, 10000000);
			emitt.add(emitter);
		}
		
		precacheCharacter("bendyChaseDark");
		precacheCharacter("bfChaseDark");
		precacheImage("stages/factory-chase/chainleft");
		precacheImage("stages/factory-chase/chainright");
		for (i in 0...3)
			precacheImage("stages/factory-chase/Particlestuff" + i);
	}
	
	if (Settings.shaders)
	{
		brightShader = getShader("bright");
		brightShader.setFloat("contrast", 1);
		FlxG.camera.addShader(brightShader);
	}
}

function onUpdatePost(elapsed)
{
	if (bgs != null && !nmStairs)
	{
		if (inBlackout)
		{
			if (darkHallway.animation.curAnim != null && darkHallway.animation.curAnim.finished)
			{
				darkHallway.animation.play('bruh', true);
			}
		}
		else if (bgs[randomPick].animation.curAnim.finished)
		{
			if (Settings.lowQuality)
			{
				// making it just use one if shit pc
				randomPick = 0;
			}
			else
			{
				randomPick = FlxG.random.int(0, bgs.length - 1);
				if ((randomPick == oldRando) && randomPick != 0)
				{
					if (randomPick + 1 != bgs.length)
					{
						randomPick += 1;
					}
					else
					{
						randomPick -= 1;
					}
				}
				oldRando = randomPick;
			}

			for (i in 0...bgs.length)
			{
				if (i == randomPick)
				{
					bgs[i].alpha = 1;
					bgs[i].animation.play('bruh', true);
				}
				else
				{
					bgs[i].alpha = 0.0001;
				}
			}
		}
	}
	
	var daElapsed = elapsed * playbackRate;
	if (iskinky) 
	{
		backbg.members[1].x -= 35 * daElapsed;
		backbg.members[4].x -= 35 * daElapsed;
		backbg.members[3].x -= 30 * daElapsed;
		backbg.members[2].x -= 30 * daElapsed;
	}
	
	if (frontbg != null)
	{
		for (i in 0...3)
			{
				frontbg.members[i].x -= 1450 * daElapsed;
				if (frontbg.members[i].x <= -FlxG.width * 1.815)
					frontbg.members[i].x = FlxG.width * 1.815 - 200;
			}
	}
	
	if (Settings.shaders && brightSpeed != 0)
		setBrightness(defaultBrightVal + Math.sin((timing.audioPosition / 1000) * (timing.curTimingPoint != null ? (timing.curTimingPoint.bpm / 60) : 1) * brightSpeed) * brightMagnitude);
	else
		setBrightness(defaultBrightVal);
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Dark Tunnel":
			if (Settings.lowQuality)
				return;
			transition.alpha = 1;
			transition.animation.play('bruh', true);
			transition.animation.finishCallback = function(name:String)
			{
				transition.alpha = 0.0001;
			}
			if (iskinky)
			{
				new FlxTimer().start(0.5 / playbackRate, function(_)
				{
					iskinky = false;
				});
			}
			inBlackout = !inBlackout;
			if (inBlackout)
			{
				new FlxTimer().start(0.6 / playbackRate, function(tmr:FlxTimer)
				{
					bgs[randomPick].alpha = 0.0001;

					darkHallway.alpha = 1;
					darkHallway.animation.play('bruh', true, false, bgs[randomPick].animation.curAnim.curFrame);
					FlxTween.tween(state,{defaultCamZoom: state.defaultCamZoom - 0.15},0.7 / playbackRate,{ease:FlxEase.smoothStepOut,startDelay:1 / playbackRate});

					bf.changeCharacter("bfChaseDark");
					opponent.changeCharacter("bendyChaseDark");
				});
			}
			else
			{
				new FlxTimer().start(0.6 / playbackRate, function(tmr:FlxTimer)
				{
					if (frontbg != null)
					{
						for (i in frontbg)
							i.alpha = 0;
						for (i in backbg)
							i.alpha = 0;
						if (emitt != null && members.contains(emitt))
						{
							remove(emitt);
							emitt.destroy();
						}
					}
					darkHallway.alpha = 0.0001;
					state.defaultCamZoom = 0.3;
					FlxTween.tween(state,{defaultCamZoom: state.defaultCamZoom + 0.15},0.7 / playbackRate,{ease:FlxEase.smoothStepOut,startDelay: 1 / playbackRate});

					bgs[randomPick].alpha = 1;
					bgs[randomPick].animation.play('bruh', true, false, darkHallway.animation.curAnim.curFrame);

					bf.changeCharacter("bfChase");
					opponent.changeCharacter("bendyChase");
					state.disableCamFollow = false;
				});
			}
			defaultBrightVal = -0.05;
			brightSpeed = 0.5;
			brightMagnitude = 0.05;
		case "Stairs":
			if (Settings.lowQuality)
				return;
			transition.alpha = 1;
			transition.animation.play('bruh', true);
			transition.animation.finishCallback = function(name:String)
			{
				transition.alpha = 0.0001;
			}
			
			new FlxTimer().start(0.6 / playbackRate, function(tmr:FlxTimer)
			{
				nmStairs = !nmStairs;
				if (nmStairs)
				{
					defaultBrightVal = 0.0;
					brightSpeed = 0.0;
					brightMagnitude = 0.0;
					
					bf.setPosition(-160, -520);
					bf.angle = -15;
					opponent.setPosition(-1080, -320);
					opponent.angle = -15;
					
					FlxTween.cancelTweensOf(opponent);
					FlxTween.cancelTweensOf(bf);
					FlxTween.tween(opponent, {x: 1080, y: 950}, 2.3 / playbackRate, {type: FlxTweenType.LOOPING});
					FlxTween.tween(bf, {x: 2000, y: 880}, 2.3 / playbackRate, {type: FlxTweenType.LOOPING});
					
					stairsBG = new FlxBackdrop(Paths.getImage('stages/factory-chase/scrollingBG'), FlxAxes.Y);
					stairsBG.scrollFactor.set(0, 1);
					stairsBG.screenCenter();
					stairsBG.velocity.set(0, 240 * playbackRate);

					stairsChainL = new FlxBackdrop(Paths.getImage('stages/factory-chase/chainleft'), FlxAxes.Y);
					stairsChainL.scrollFactor.set(0, 1);
					stairsChainL.screenCenter();
					stairsChainL.x -= 500;
					stairsChainL.velocity.set(0, 1000 * playbackRate);

					stairsChainR = new FlxBackdrop(Paths.getImage('stages/factory-chase/chainright'), FlxAxes.Y);
					stairsChainR.scrollFactor.set(0, 1);
					stairsChainR.screenCenter();
					stairsChainR.x += 520;
					stairsChainR.velocity.set(0, 1510 * playbackRate);

					addBehindChars(stairsBG);
					bf.scale.set(0.6, 0.6);
					opponent.scale.set(0.85, 0.85);

					stairs = new FlxSprite(0, 0).loadGraphic(Paths.getImage('stages/factory-chase/stairs'));
					stairs.updateHitbox();
					stairs.screenCenter();
					stairs.alpha = 1.0;
					stairs.antialiasing = true;
					stairs.y -= 920;
					stairsGrp.add(stairs);
					FlxTween.tween(stairs, {y: 1120}, 2.3 / playbackRate, {type: FlxTweenType.LOOPING});
					stairsGrp.add(stairsChainL);
					stairsGrp.add(stairsChainR);
					stairsGrp.add(stairsGradient);
					
					FlxTween.cancelTweensOf(state);
					state.defaultCamZoom = 1;
					state.disableCamFollow = true;
					FlxTween.tween(camFollow, {x: 500, y: 500}, 0.4 / playbackRate, {ease: FlxEase.quintOut});
				}
			});
		case "Trans Rights": // indie cross based?!
			if (Settings.lowQuality)
				return;
			transition.alpha = 1;
			transition.animation.play('bruh', true);
			transition.animation.finishCallback = function(name:String)
			{
				transition.alpha = 0.0001;
				iskinky = true;
			}
			
			new FlxTimer().start(0.65 / playbackRate, function(tmr:FlxTimer)
			{
				nmStairs = false;
				stairsBG.alpha = 0.0001;
				stairs.alpha = 0.0001;
				remove(stairsGrp);
				stairsGrp.destroy();
				addBehindChars(emitt);
				bf.changeCharacter("bfChaseDark");
				opponent.changeCharacter("bendyChaseDark");
				bf.scale.set(1, 1);
				opponent.scale.set(1, 1);
				bf.updateHitbox();
				opponent.updateHitbox();
				opponent.screenCenter();
				bf.screenCenter();
				opponent.x -= 445;
				opponent.y += 400;
				bf.x += 130;
				bf.y += 520;
				bf.angle = 0;
				opponent.angle = 0;
				bf.scale.set(0.75, 0.75);
				opponent.scale.set(1, 1);
				FlxTween.cancelTweensOf(bf);
				FlxTween.cancelTweensOf(opponent);
				state.defaultCamZoom = 0.6;
				for (i in frontbg)
					i.alpha = 1;
				for (i in backbg)
					i.alpha = 1;
				inBlackout = true;
			});
	}
}

function setBrightness(value)
{
	if (brightShader != null)
		brightShader.setFloat("brightness", value);
}