import flixel.math.FlxAngle;

var tankmanRun:FlxTypedGroup<FlxSprite>;
var tankAngle:Float = FlxG.random.int(-90, 45);
var tankSpeed:Float = FlxG.random.float(5, 7);
var tankX:Float = 400;
var animationNotes:Array<NoteInfo> = [];
var tankmanRunMap:ObjectMap<FlxSprite, Dynamic> = new ObjectMap();

function onCreate()
{
	if (!Settings.lowQuality)
	{
		var tankSky:BGSprite = new BGSprite('stages/tank/tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
		tankSky.active = true;
		tankSky.velocity.x = FlxG.random.float(5, 15) * playbackRate;
		insert(members.indexOf(bg) + 1, tankSky);
	}

	tankmanRun = new FlxTypedGroup();
	addBehindChars(tankmanRun);

	moveTank();

	if (gf.info.name == 'pico-speaker')
	{
		gf.danceDisabled = true;
		loadMappedAnims();
	}
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

function moveTank():Void
{
	var daAngleOffset:Float = 1;
	tankAngle += FlxG.elapsed * tankSpeed * playbackRate;
	tankRolling.angle = tankAngle - 90 + 15;

	tankRolling.x = tankX + Math.cos(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1500;
	tankRolling.y = 1300 + Math.sin(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1100;
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
	spr.antialiasing = Settings.antialiasing;
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
