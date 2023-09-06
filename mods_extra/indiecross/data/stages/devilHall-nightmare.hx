var chromaShader:FlxRuntimeShader;
var defaultChromVal:Float = 0.001;
var chromVal:Float = defaultChromVal;
var brightShader:FlxRuntimeShader;
var defaultBrightVal:Float = -0.05;
var brightSpeed:Float = 0.2;
var brightMagnitude:Float = 0.05;
var fgStatic:FlxSprite;
var fgGrain:FlxSprite;

function onCreatePost()
{
	if (Settings.shaders)
	{
		chromaShader = getShader("chromaticAberration");
		setChroma(chromVal);
		addGameShader(chromaShader);
		
		brightShader = getShader("bright");
		brightShader.setFloat("contrast", 1);
		FlxG.camera.addShader(brightShader);
	}
	
	if (!Settings.lowQuality)
	{
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
}

function onUpdatePost(elapsed)
{
	if (Settings.flashing)
		setChroma(chromVal);
		
	var bpmScale = (timing.curTimingPoint != null ? (timing.curTimingPoint.bpm / 60) : 1);
		
	if (brightSpeed != 0)
		setBrightness(defaultBrightVal + Math.sin((timing.audioPosition / 1000) * bpmScale * brightSpeed) * brightMagnitude);
	else
		setBrightness(defaultBrightVal);
}

function onCharacterSing(char, lane, hold)
{
	if (char == opponent && Settings.flashing)
	{
		FlxG.camera.shake(0.015, 0.1 / playbackRate);
		camHUD.shake(0.005, 0.1 / playbackRate);
		chromVal = FlxG.random.float(0.005, 0.01);
		FlxTween.num(chromVal, defaultChromVal, FlxG.random.float(0.05, 0.12) / playbackRate, null, function(n)
		{
			chromVal = n;
		});
	}
}

function onDeath(player)
{
	if (Settings.lowQuality)
		return;
		
	FlxTween.tween(fgStatic, {alpha: 0}, 1);
	FlxTween.tween(fgGrain, {alpha: 0}, 1);
}

function setChroma(value)
{
	if (chromaShader == null)
		return;
	chromaShader.setFloat("rOffset", value);
	chromaShader.setFloat("bOffset", -value);
}

function setBrightness(value)
{
	if (brightShader != null)
		brightShader.setFloat("brightness", value);
}