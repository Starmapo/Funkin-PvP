package states.pvp;

import data.Mods;
import data.PlayerSettings;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.lists.GroupMenuList;
import ui.lists.MenuList.MenuItem;
import ui.lists.MenuList.TypedMenuItem;
import ui.lists.MenuList.TypedMenuList;

class CharacterSelectState extends FNFState
{
	public var transitioning:Bool = true;

	var camPlayers:Array<FlxCamera> = [];
	var camDivision:FlxCamera;
	var camScroll:FlxCamera;
	var camOver:FlxCamera;
	var iconScroll:FlxBackdrop;
	var stateText:FlxText;
	var playerGroups:FlxTypedGroup<PlayerCharacterSelect>;

	override function create()
	{
		transIn = transOut = null;
		persistentUpdate = true;

		for (i in 0...2)
		{
			var camPlayer = new FlxCamera(Std.int((FlxG.width / 2) * i), 0, Std.int(FlxG.width / 2));
			camPlayer.bgColor = 0;
			camPlayers.push(camPlayer);
			FlxG.cameras.add(camPlayer, false);
		}

		camDivision = new FlxCamera(Std.int((FlxG.width / 2) - 1), 0, 3);
		camDivision.bgColor = FlxColor.WHITE;
		FlxG.cameras.add(camDivision, false);

		camScroll = new FlxCamera();
		camScroll.bgColor = FlxColor.fromRGBFloat(0, 0, 0, 0.5);
		FlxG.cameras.add(camScroll, false);
		camOver = new FlxCamera();
		camOver.bgColor = 0;
		FlxG.cameras.add(camOver, false);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF21007F;
		add(bg);

		playerGroups = new FlxTypedGroup();
		add(playerGroups);

		for (i in 0...2)
			playerGroups.add(new PlayerCharacterSelect(i, camPlayers[i], this));

		stateText = new FlxText(0, 0, 0, 'Song Selection');
		stateText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		stateText.screenCenter(X);
		stateText.scrollFactor.set();
		stateText.cameras = [camOver];
		camScroll.height = Math.ceil(stateText.height);
		stateText.y = camScroll.y -= camScroll.height;

		iconScroll = new FlxBackdrop(Paths.getImage('menus/pvp/iconScroll'));
		iconScroll.alpha = 0.5;
		iconScroll.cameras = [camScroll];
		iconScroll.velocity.set(25, 25);
		iconScroll.scale.set(0.5, 0.5);

		add(iconScroll);
		add(stateText);

		FlxG.camera.zoom = 3;
		FlxTween.tween(camScroll, {y: 0}, Main.TRANSITION_TIME, {ease: FlxEase.expoOut});
		FlxTween.tween(FlxG.camera, {zoom: 1}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				for (group in playerGroups)
					group.setControlsEnabled(true);
			}
		});
		camOver.fade(FlxColor.BLACK, Main.TRANSITION_TIME, true, null, true);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// prevent overflow (it would probably take an eternity for that to happen but you can never be too safe)
		if (iconScroll.x >= 300)
			iconScroll.x %= 300;
		if (iconScroll.y >= 300)
			iconScroll.y %= 300;

		stateText.y = camScroll.y;
		for (cam in camPlayers)
			cam.zoom = FlxG.camera.zoom;
	}

	public function exitTransition(onComplete:FlxTween->Void)
	{
		transitioning = true;
		for (group in playerGroups)
			group.setControlsEnabled(false);
		FlxTween.tween(camScroll, {y: -camScroll.height}, Main.TRANSITION_TIME / 2, {ease: FlxEase.expoIn});
		FlxTween.tween(FlxG.camera, {zoom: 5}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoIn,
			onComplete: onComplete
		});
		camOver.fade(FlxColor.BLACK, Main.TRANSITION_TIME, false, null, true);
	}
}

class PlayerCharacterSelect extends FlxGroup
{
	static var lastSelectedGroups:Array<Int> = [0, 0];

	public var viewing:Int = 0;
	public var ready:Bool = false;

	var player:Int = 0;
	var state:CharacterSelectState;
	var groupMenuList:GroupMenuList;
	var camFollow:FlxObject;

	public function new(player:Int, camera:FlxCamera, state:CharacterSelectState)
	{
		super();
		this.player = player;
		this.state = state;
		cameras = [camera];

		camFollow = new FlxObject(FlxG.width / 4);
		camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);

		groupMenuList = new GroupMenuList(player);
		groupMenuList.onChange.add(onGroupChange);
		groupMenuList.onAccept.add(onGroupAccept);

		for (name => group in Mods.songGroups)
			groupMenuList.createItem(group);
		groupMenuList.afterInit();

		add(groupMenuList);

		setControlsEnabled(false);

		groupMenuList.selectItem(lastSelectedGroups[player]);
		camera.snapToTarget();
	}

	override function update(elapsed:Float)
	{
		if (!state.transitioning && PlayerSettings.checkPlayerAction(player, BACK_P))
		{
			if (viewing == 1)
			{
				groupMenuList.controlsEnabled = true;
				camFollow.x = FlxG.width * 0.25;
				updateCamFollow(groupMenuList.selectedItem);
				viewing = 0;
			}
			else
			{
				state.exitTransition(function(_)
				{
					FlxG.switchState(new SongSelectState());
				});
				CoolUtil.playCancelSound();
			}
		}

		super.update(elapsed);
	}

	public function setControlsEnabled(value:Bool)
	{
		groupMenuList.controlsEnabled = value;
	}

	function updateCamFollow(item:MenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}

	function onGroupChange(item:GroupMenuItem)
	{
		updateCamFollow(item);
		lastSelectedGroups[player] = item.ID;
	}

	function onGroupAccept(item:GroupMenuItem)
	{
		groupMenuList.controlsEnabled = false;
		camFollow.x = FlxG.width * 0.75;
		viewing = 1;
		CoolUtil.playScrollSound();
	}
}

class CharacterMenuList extends TypedMenuList<CharacterMenuItem> {}

class CharacterMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	var bg:FlxSprite;

	public function new(x:Float = 0, y:Float = 0, name:String, char:String)
	{
		var label = new FlxSpriteGroup();

		bg = new FlxSprite();
		label.add(bg);

		super(x, y, label, name);

		setEmptyBackground();
	}

	function getBGGraphic(char:String) {}
}
