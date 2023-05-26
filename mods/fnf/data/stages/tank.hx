var tankmanRun:FlxTypedGroup<FlxSprite>;
var tankWatchtower:BGSprite;
var tankGround:BGSprite;
var tankAngle:Float = FlxG.random.int(-90, 45);
var tankSpeed:Float = FlxG.random.float(5, 7);
var tankX:Float = 400;
var foregroundSprites:FlxTypedGroup<BGSprite>;
var animationNotes:Array<NoteInfo> = [];
var tankmanRunMap:ObjectMap<FlxSprite, Dynamic> = new ObjectMap();

function onCreate()
{
	foregroundSprites = new FlxTypedGroup();

	state.defaultCamZoom = 0.9;

	var bg:BGSprite = new BGSprite('stages/tank/tankSky', -400, -400, 0, 0);
	addBehindChars(bg);

	if (!Settings.lowQuality)
	{
		var tankSky:BGSprite = new BGSprite('stages/tank/tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
		tankSky.active = true;
		tankSky.velocity.x = FlxG.random.float(5, 15) * playbackRate;
		addBehindChars(tankSky);

		var tankMountains:BGSprite = new BGSprite('stages/tank/tankMountains', -300, -20, 0.2, 0.2);
		tankMountains.setGraphicSize(Std.int(tankMountains.width * 1.2));
		tankMountains.updateHitbox();
		addBehindChars(tankMountains);

		var tankBuildings:BGSprite = new BGSprite('stages/tank/tankBuildings', -200, 0, 0.30, 0.30);
		tankBuildings.setGraphicSize(Std.int(tankBuildings.width * 1.1));
		tankBuildings.updateHitbox();
		addBehindChars(tankBuildings);
	}

	var tankRuins:BGSprite = new BGSprite('stages/tank/tankRuins', -200, 0, 0.35, 0.35);
	tankRuins.setGraphicSize(Std.int(tankRuins.width * 1.1));
	tankRuins.updateHitbox();
	addBehindChars(tankRuins);

	if (!Settings.lowQuality)
	{
		var smokeLeft:BGSprite = new BGSprite('stages/tank/smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
		addBehindChars(smokeLeft);

		var smokeRight:BGSprite = new BGSprite('stages/tank/smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
		addBehindChars(smokeRight);

		if (Settings.distractions)
		{
			tankWatchtower = new BGSprite('stages/tank/tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
			addBehindChars(tankWatchtower);
		}
	}

	if (Settings.distractions)
	{
		tankGround = new BGSprite('stages/tank/tankRolling', 300, 300, 0.5, 0.5, ['BG tank w lighting'], true);
		addBehindChars(tankGround);

		tankmanRun = new FlxTypedGroup();
		addBehindChars(tankmanRun);

		moveTank();
	}

	var tankGround:BGSprite = new BGSprite('stages/tank/tankGround', -420, -150);
	tankGround.setGraphicSize(Std.int(tankGround.width * 1.15));
	tankGround.updateHitbox();
	addBehindChars(tankGround);

	if (gf.charInfo.name == 'pico-speaker')
	{
		gf.danceDisabled = true;
		if (Settings.distractions)
			loadMappedAnims();
	}

	if (Settings.distractions)
	{
		var fgTank0:BGSprite = new BGSprite('stages/tank/tank0', -500, 650, 1.7, 1.5, ['fg']);
		foregroundSprites.add(fgTank0);

		if (!Settings.lowQuality)
		{
			var fgTank1:BGSprite = new BGSprite('stages/tank/tank1', -300, 750, 2, 0.2, ['fg']);
			foregroundSprites.add(fgTank1);
		}

		var fgTank2:BGSprite = new BGSprite('stages/tank/tank2', 450, 940, 1.5, 1.5, ['foreground']);
		foregroundSprites.add(fgTank2);

		if (!Settings.lowQuality)
		{
			var fgTank4:BGSprite = new BGSprite('stages/tank/tank4', 1300, 900, 1.5, 1.5, ['fg']);
			foregroundSprites.add(fgTank4);
		}

		var fgTank5:BGSprite = new BGSprite('stages/tank/tank5', 1620, 700, 1.5, 1.5, ['fg']);
		foregroundSprites.add(fgTank5);

		if (!Settings.lowQuality)
		{
			var fgTank3:BGSprite = new BGSprite('stages/tank/tank3', 1300, 1200, 3.5, 2.5, ['fg']);
			foregroundSprites.add(fgTank3);
		}

		addOverChars(foregroundSprites);
	}
	else
		close();
}

function onUpdate(elapsed)
{
	moveTank();
}

function onUpdatePost(elapsed)
{
	while (animationNotes.length > 0 && timing.audioPosition >= animationNotes[0].startTime)
	{
		var shootAnim:Int = 1;

		if (animationNotes[0].playerLane >= 2)
			shootAnim = 3;

		shootAnim += FlxG.random.int(0, 1);

		gf.playAnim('shoot' + shootAnim, true);
		animationNotes.shift();
	}

	if (tankmanRun != null && tankmanRun.length > 0)
	{
		var i = 0;
		while (i < tankmanRun.length)
		{
			var tankman = tankmanRun.members[i];
			var info = tankmanRunMap[tankman];

			if (tankman.animation.name == 'run')
			{
				var endDirection:Float = (FlxG.width * 0.74) + info.endingOffset;

				if (tankman.flipX)
				{
					endDirection = (FlxG.width * 0.02) - info.endingOffset;

					tankman.x = (endDirection + (timing.audioPosition - info.strumTime) * info.tankSpeed);
				}
				else
				{
					tankman.x = (endDirection - (timing.audioPosition - info.strumTime) * info.tankSpeed);
				}
			}

			if (timing.audioPosition >= info.strumTime)
			{
				tankman.animation.play('shot');

				if (tankman.flipX)
				{
					tankman.offset.y = 200;
					tankman.offset.x = 300;
				}
			}

			if (tankman.animation.name == 'shot' && tankman.animation.curAnim.curFrame >= tankman.animation.curAnim.frames.length - 1)
			{
				tankmanRun.remove(tankman, true);
				tankman.destroy();
				tankmanRunMap.remove(tankman);
			}
			else
				i++;
		}
	}
}

function onBeatHit(beat, decBeat)
{
	foregroundSprites.forEach(function(spr:BGSprite)
	{
		spr.dance();
	});

	if (tankWatchtower != null)
		tankWatchtower.dance();
}

function moveTank():Void
{
	var daAngleOffset:Float = 1;
	tankAngle += FlxG.elapsed * tankSpeed * playbackRate;
	tankGround.angle = tankAngle - 90 + 15;

	tankGround.x = tankX + Math.cos(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1500;
	tankGround.y = 1300 + Math.sin(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1100;
}

function loadMappedAnims()
{
	var daSong = loadDifficulty('!picospeaker');
	for (note in daSong.notes)
		animationNotes.push(note);
	animationNotes.sort(sortAnims);

	if (!Settings.lowQuality)
	{
		for (i in 0...animationNotes.length)
		{
			if (FlxG.random.bool(16))
			{
				var note = animationNotes[i];
				var tankman = createTankmanBG(500, 200 + FlxG.random.int(50, 100), note.startTime, note.playerLane < 2);
				tankmanRun.add(tankman);
			}
		}
	}
}

function sortAnims(val1:NoteInfo, val2:NoteInfo):Int
{
	return FlxSort.byValues(FlxSort.ASCENDING, val1.startTime, val2.startTime);
}

function createTankmanBG(x:Float, y:Float, strumTime:Float, isGoingRight:Bool)
{
	var spr = new FlxSprite(x, y);
	spr.frames = Paths.getSpritesheet('stages/tank/tankmanKilled1');
	spr.antialiasing = true;
	spr.animation.addByPrefix('run', 'tankman running', 24, true);
	spr.animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
	spr.animation.play('run');
	spr.animation.curAnim.curFrame = FlxG.random.int(0, spr.animation.curAnim.numFrames - 1);
	spr.scale.set(0.8, 0.8);
	spr.updateHitbox();

	spr.flipX = isGoingRight;
	tankmanRunMap[spr] = {
		strumTime: strumTime,
		endingOffset: FlxG.random.float(50, 200),
		tankSpeed: FlxG.random.float(0.6, 1)
	};
	return spr;
}
