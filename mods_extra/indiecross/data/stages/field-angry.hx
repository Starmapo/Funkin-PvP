var shader:FlxRuntimeShader;
var chromVal:Float = 0.001;
var fgStatic:FlxSprite;
var fgGrain:FlxSprite;
var mugdead:FlxSprite;
var cupBullet:FlxSprite;
var shooting:Bool = false;
var knockoutSpr:FlxSprite;
var danceYouIdiot:Bool = false; // grrrr

function onCreatePost()
{
	if (Settings.shaders)
	{
		shader = getShader("chromaticAberration");
		setChroma(0.001);
		addGameShader(shader);
	}
	
	if (!Settings.lowQuality)
	{
		if ((opponent.info.name == "angrycuphead" || opponent.info.name == "angrycuphead-pew") && opponent.info.mod == modID)
		{
			mugdead = new FlxSprite();
			mugdead.frames = Paths.getSpritesheet('stages/field-angry/Mugman Fucking dies');
			mugdead.animation.addByPrefix('Dead', 'MUGMANDEAD', 24, false);
			mugdead.animation.addByPrefix('Stroll', 'Mugman instance', 24, true);
			mugdead.animation.play('Stroll', true);
			mugdead.animation.pause();
			mugdead.updateHitbox();
			mugdead.antialiasing = true;
			mugdead.x = 945 + 500;
			mugdead.y = 100 + 350;
			mugdead.alpha = 0.00001;
			add(mugdead);
			
			cupBullet = createBullet(0, 0, "hadoken");
			add(cupBullet);
			
			knockoutSpr = new FlxSprite();
			knockoutSpr.frames = Paths.getSpritesheet('stages/field-angry/knock');
			knockoutSpr.animation.addByPrefix('start', "A KNOCKOUT!", 24, false);
			knockoutSpr.updateHitbox();
			knockoutSpr.screenCenter();
			knockoutSpr.antialiasing = true;
			knockoutSpr.scrollFactor.set();
			knockoutSpr.alpha = 0.0001;
			add(knockoutSpr);
			
			Paths.getSound('cup/hurt');
		}
		
		fgStatic = new FlxSprite();
		fgStatic.frames = Paths.getSpritesheet('stages/CUpheqdshid');
		fgStatic.animation.addByPrefix('play', 'Cupheadshit_gif instance 1', 24, true);
		fgStatic.animation.play('play', true);
		fgStatic.setGraphicSize(FlxG.width);
		fgStatic.updateHitbox();
		fgStatic.screenCenter();
		fgStatic.antialiasing = true;
		fgStatic.scrollFactor.set();
		fgStatic.cameras = [camOther];
		fgStatic.alpha = 0.6;
		add(fgStatic);
		
		fgGrain = new FlxSprite();
		fgGrain.frames = Paths.getSpritesheet('stages/Grainshit');
		fgGrain.animation.addByPrefix('play', 'Geain instance 1', 24, true);
		fgGrain.animation.play('play', true);
		fgGrain.setGraphicSize(FlxG.width);
		fgGrain.updateHitbox();
		fgGrain.screenCenter();
		fgGrain.antialiasing = true;
		fgGrain.scrollFactor.set();
		fgGrain.cameras = [camOther];
		add(fgGrain);
	}
	else
		close();
}

function onUpdatePost(elapsed)
{
	if (shooting)
	{
		var timeIndex = elapsed * 120 * playbackRate;
		cupBullet.animation.play("fire");
		cupBullet.x += 12 * timeIndex;
	}
	
	if (mugdead != null && shooting && mugdead.overlaps(cupBullet) && (cupBullet.x < mugdead.x + mugdead.width / 4) && (cupBullet.x > mugdead.x - mugdead.width / 2) && mugdead.animation.name == "Stroll")
	{
		shooting = false;
		cupBullet.alpha = 0.00001;
		var cupheadPewThing = createBullet(cupBullet.x + cupBullet.width / 4, cupBullet.y, "hadokenFX");
		cupheadPewThing.alpha = 1;
		add(cupheadPewThing);
		cupheadPewThing.animation.finishCallback = function(name:String)
		{
			cupheadPewThing.destroy();
			remove(cupheadPewThing);
		};
		mugdead.animation.play('Dead', true);
		FlxG.sound.play(Paths.getSound('cup/hurt'));
		knockout();
	}
	
	if (Settings.flashing)
		setChroma(chromVal);
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Mugman Stroll":
			if (mugdead == null)
				return;
			mugdead.animation.play('Stroll', true);
			mugdead.alpha = 1;
			FlxTween.tween(mugdead, {x: 945 + 200}, 1 / playbackRate, {ease: FlxEase.quadInOut});
		case "Hadoken":
			if (mugdead == null)
				return;
			state.defaultCamZoom = 0.61 * 4 / 3;
			opponent.singDisabled = opponent.danceDisabled = true;
			opponent.playSpecialAnim("indiecross_attack2");
			new FlxTimer().start(0.5 / playbackRate, function(tmr:FlxTimer)
			{
				danceYouIdiot = true;
				opponent.singDisabled = false;
				cupBullet.setPosition(opponent.x + opponent.startWidth / 2, opponent.y + opponent.startHeight / 2);
				cupBullet.alpha = 1;
				shooting = true;
				chromVal = 0.01;
				FlxTween.num(chromVal, 0.001, 0.3 / playbackRate, null, function(n)
				{
					chromVal = n;
				});
			});
	}
}

function onNoteHit(note)
{
	if (danceYouIdiot && note.info.player == 0)
	{
		opponent.danceDisabled = false;
		danceYouIdiot = false;
	}
}

function onDeath(player)
{
	if (Settings.lowQuality)
		return;
	
	FlxTween.tween(fgStatic, {alpha: 0}, 1);
	FlxTween.tween(fgGrain, {alpha: 0}, 1);
	FlxTween.tween(fgRain, {alpha: 0}, 1);
	FlxTween.tween(fgRain2, {alpha: 0}, 1);
}

function setChroma(value)
{
	if (shader == null)
		return;
	shader.setFloat("rOffset", value);
	shader.setFloat("bOffset", -value);
}

function createBullet(x:Float, y:Float, type:String)
{
	var sprite = new FlxSprite(x, y);
	switch (type)
	{
		case "hadoken":
			sprite.frames = Paths.getSpritesheet('bull/Cuphead Hadoken');
			sprite.animation.addByPrefix('fire', 'Hadolen instance 1', 24, false);
			sprite.animation.play('fire');
		case "hadokenFX":
			sprite.frames = Paths.getSpritesheet('bull/Cuphead Hadoken');
			sprite.animation.addByPrefix('fire', 'BurstFX', 24, false);
			sprite.animation.play('fire');	
	}
	sprite.antialiasing = true;
	sprite.alpha = 0.00001;
	sprite.blend = BlendMode.ADD;
	sprite.updateHitbox();
	sprite.offset.set(sprite.frameWidth / 2, sprite.frameHeight / 2);
	return sprite;
}

function knockout()
{
	knockoutSpr.alpha = 1;
	knockoutSpr.animation.play('start');

	new FlxTimer().start(2 / playbackRate, function(tmr:FlxTimer)
	{
		FlxTween.tween(knockoutSpr, {alpha: 0}, 2.5 / playbackRate);
	});
	
	FlxG.sound.play(Paths.getSound('cup/knockout')).pitch = playbackRate;
}