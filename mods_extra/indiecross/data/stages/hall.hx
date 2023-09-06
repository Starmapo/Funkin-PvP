var brightShader:FlxRuntimeShader;
var defaultBrightVal:Float = 0;
var grayscaleShader:FlxRuntimeShader;
var waterfall:Bool = false;
var finalStretchWaterFallBG:FlxSprite;
var finalStretchBarTop:FlxSprite;
var finalStretchBarBottom:FlxSprite;
var blackBars:Bool = false;
var finalStretchwhiteBG:FlxSprite;
var whiteBG:Bool = false;
var battle:FlxSprite;
var battleBG:FlxSprite;
var doBattle:Bool = false;
var combat:Bool = false;

function onCreatePost()
{
	if (songName == "Final Stretch")
	{
		finalStretchWaterFallBG = new FlxSprite().loadGraphic(Paths.getImage('stages/hall/Waterfall'));
		finalStretchWaterFallBG.setGraphicSize(Std.int(bg.width * 1.5));
		finalStretchWaterFallBG.updateHitbox();
		finalStretchWaterFallBG.screenCenter();
		finalStretchWaterFallBG.x -= 300;
		finalStretchWaterFallBG.alpha = 0.0001;
		addBehindChars(finalStretchWaterFallBG);
		
		finalStretchwhiteBG = new FlxSprite(-640, -640).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
		finalStretchwhiteBG.scrollFactor.set();
		finalStretchwhiteBG.visible = false;
		addBehindChars(finalStretchwhiteBG);
		
		finalStretchBarTop = new FlxSprite(-640, -560).makeGraphic(FlxG.width * 2, 560, FlxColor.BLACK);
		finalStretchBarTop.scrollFactor.set();
		finalStretchBarTop.cameras = [camHUD];
		addBehindUI(finalStretchBarTop);

		finalStretchBarBottom = new FlxSprite(-640, 720).makeGraphic(FlxG.width * 2, 560, FlxColor.BLACK);
		finalStretchBarBottom.scrollFactor.set();
		finalStretchBarBottom.cameras = [camHUD];
		addBehindUI(finalStretchBarBottom);
		
		for (char in getCharacters())
		{
			if (char.info.mod != modID)
				continue;
			if (char.info.name == "sans")
				precacheCharacter("sanswaterfall");
			if (char.info.name == "sanswaterfall")
				precacheCharacter("sans");
			if (char.info.name == "bfSans")
				precacheCharacter("bfsanswaterfall");
			if (char.info.name == "bfsanswaterfall")
				precacheCharacter("bfSans");
		}
	}
	
	doBattle = (opponent.info.name == "sans" || opponent.info.name == "sansScared" || opponent.info.name == "sansTired") && opponent.info.mod == modID && (bf.info.name == "bfSans" || bf.info.name == "bfsanswaterfall" || bf.info.name == "bfchara") && bf.info.mod == modID;
	
	if (songName == "Sansational" && doBattle)
	{
		battle = new FlxSprite(-600, -200).loadGraphic(Paths.getImage('stages/battleUI/battle'));
		battle.antialiasing = true;
		battle.alpha = 0.0001;

		battleBG = new FlxSprite(-600, 0).loadGraphic(Paths.getImage('stages/battleUI/bg'));
		battleBG.alpha = 0.0001;
		battleBG.setGraphicSize(Std.int(battle.width));
		battleBG.updateHitbox();

		addBehindChars(battle);
		addBehindChars(battleBG);
		
		precacheCharacter("sansbattle");
		if (bf.info.name == "bfchara")
			precacheCharacter("charabattle");
		else
			precacheCharacter("bfbattle");
	}
	
	if (songName != "Whoopee")
		Paths.getSound("sans/countdown");
	
	if (Settings.shaders)
	{
		if (songName == "Whoopee")
		{
			brightShader = getShader("bright");
			brightShader.setFloat("contrast", 1);
			FlxG.camera.addShader(brightShader);
		}
		
		if (songName == "Sansational" && !doBattle)
		{
			grayscaleShader = getShader("grayscale");
			grayscaleShader.setFloat("influence", 1);
		}
	}
}

function onUpdatePost(elapsed)
{
	var bpmScale = (timing.curTimingPoint != null ? (timing.curTimingPoint.bpm / 60) : 1);
	
	if (combat && doBattle)
		bf.y = 1248.7 + Math.sin((timing.audioPosition / 1000) * bpmScale * 2.5) * 20;
		
	setBrightness(defaultBrightVal);
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Play Animation":
			if (params[0] == "indiecross_snap" && opponent.animation.exists(params[0]))
				opponent.danceDisabled = true;
		case "Tween Default Brightness":
			FlxTween.num(defaultBrightVal, Std.parseFloat(params[0]), Std.parseFloat(params[1]) / playbackRate, null, function(n) {
				defaultBrightVal = n;
			});
		case "Switch to Combat":
			if (params[0] == "1")
				FlxG.camera.visible = true;
			else
			{
				combat = true;
				bg.visible = false;
				if (staticBG != null)
					staticBG.visible = false;
				if (doBattle)
				{
					battle.alpha = 1;
					battleBG.alpha = 1;
					opponent.changeCharacter("sansbattle");
					opponent.setCharacterPosition(155.1, 436.5);
					opponent.danceDisabled = false;
					switch (bf.info.name)
					{
						case "bfchara":
							bf.changeCharacter("charabattle");
						default:
							bf.changeCharacter("bfbattle");
					}
					bf.setCharacterPosition(158.3, 1248.7);
					FlxG.camera.zoom = state.defaultCamZoom = 0.35;
					state.updateCamPosition();
					FlxG.camera.snapToTarget();
				}
				else
				{
					if (grayscaleShader != null)
						FlxG.camera.addShader(grayscaleShader);
				}
				FlxG.camera.visible = false;
			}
			FlxG.sound.play(Paths.getSound("sans/countdown"));
		case "Waterfall":
			if (params[0] == "1")
				FlxG.camera.visible = true;
			else
			{
				FlxG.camera.visible = false;
				waterfall = !waterfall;
				if (waterfall)
				{
					if (opponent.info.name == "sans" && opponent.info.mod == modID)
						opponent.changeCharacter("sanswaterfall");
					if (bf.info.name == "bfSans" && bf.info.mod == modID)
						bf.changeCharacter("bfsanswaterfall");
				}
				else
				{
					if (opponent.info.name == "sanswaterfall" && opponent.info.mod == modID)
						opponent.changeCharacter("sans");
					if (bf.info.name == "bfsanswaterfall" && bf.info.mod == modID)
						bf.changeCharacter("bfSans");
				}
				finalStretchWaterFallBG.alpha = waterfall ? 1 : 0.00001;
			}
			FlxG.sound.play(Paths.getSound("sans/countdown"));
		case "Black Bars":
			if (!blackBars)
			{
				blackBars = true;
				FlxTween.cancelTweensOf(finalStretchBarTop);
				FlxTween.tween(finalStretchBarTop, {y: -560 + 112}, 1.5 / playbackRate, {ease: FlxEase.quadInOut});
				FlxTween.cancelTweensOf(finalStretchBarBottom);
				FlxTween.tween(finalStretchBarBottom, {y: 720 - 112}, 1.5 / playbackRate, {ease: FlxEase.quadInOut});
			}
			else
			{
				blackBars = false;
				FlxTween.cancelTweensOf(finalStretchBarTop);
				FlxTween.tween(finalStretchBarTop, {y: -560}, 1.5 / playbackRate, {ease: FlxEase.quadInOut});
				FlxTween.cancelTweensOf(finalStretchBarBottom);
				FlxTween.tween(finalStretchBarBottom, {y: 720}, 1.5 / playbackRate, {ease: FlxEase.quadInOut});
			}
		case "White BG":
			whiteBG = !whiteBG;
			if (whiteBG)
			{
				finalStretchwhiteBG.visible = true;
				finalStretchwhiteBG.alpha = 0.0001;
				FlxTween.cancelTweensOf(finalStretchwhiteBG);
				FlxTween.tween(finalStretchwhiteBG, {alpha: 1.0}, 1.5 / playbackRate, {ease: FlxEase.quadInOut});
				bf.doColorTween(1.5 / playbackRate, FlxColor.WHITE, FlxColor.BLACK, {ease: FlxEase.quadInOut});
				opponent.doColorTween(1.5 / playbackRate, FlxColor.WHITE, FlxColor.BLACK, {ease: FlxEase.quadInOut});
			}
			else
			{
				finalStretchwhiteBG.visible = false;
				bf.color = FlxColor.WHITE;
				opponent.color = FlxColor.WHITE;
				finalStretchBarTop.visible = false;
				finalStretchBarBottom.visible = false;
			}
	}
}

function setBrightness(value)
{
	if (brightShader != null)
		brightShader.setFloat("brightness", value);
}