var tankmanRun:FlxTypedGroup<FlxSprite>;
var tankWatchtower:BGSprite;
var tankGround:BGSprite;

function onCreate()
{
	state.defaultCamZoom = 0.9;

	var bg:BGSprite = new BGSprite('stages/tank/tankSky', -400, -400, 0, 0);
	add(bg);

	if (!Settings.lowQuality)
	{
		var tankSky:BGSprite = new BGSprite('stages/tank/tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
		tankSky.active = true;
		tankSky.velocity.x = FlxG.random.float(5, 15);
		add(tankSky);

		var tankMountains:BGSprite = new BGSprite('stages/tank/tankMountains', -300, -20, 0.2, 0.2);
		tankMountains.setGraphicSize(Std.int(tankMountains.width * 1.2));
		tankMountains.updateHitbox();
		add(tankMountains);

		var tankBuildings:BGSprite = new BGSprite('stages/tank/tankBuildings', -200, 0, 0.30, 0.30);
		tankBuildings.setGraphicSize(Std.int(tankBuildings.width * 1.1));
		tankBuildings.updateHitbox();
		add(tankBuildings);
	}

	var tankRuins:BGSprite = new BGSprite('stages/tank/tankRuins', -200, 0, 0.35, 0.35);
	tankRuins.setGraphicSize(Std.int(tankRuins.width * 1.1));
	tankRuins.updateHitbox();
	add(tankRuins);

	if (!Settings.lowQuality)
	{
		var smokeLeft:BGSprite = new BGSprite('stages/tank/smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
		add(smokeLeft);

		var smokeRight:BGSprite = new BGSprite('stages/tank/smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
		add(smokeRight);

		tankWatchtower = new BGSprite('stages/tank/tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
		add(tankWatchtower);
	}

	tankGround = new BGSprite('stages/tank/tankRolling', 300, 300, 0.5, 0.5, ['BG tank w lighting'], true);
	add(tankGround);

	tankmanRun = new FlxTypedGroup();
	add(tankmanRun);

	var tankGround:BGSprite = new BGSprite('stages/tank/tankGround', -420, -150);
	tankGround.setGraphicSize(Std.int(tankGround.width * 1.15));
	tankGround.updateHitbox();
	add(tankGround);

	moveTank();

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
}
