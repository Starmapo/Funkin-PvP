package subStates;

import data.Mods;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import states.PlayState;
import states.options.OptionsState;
import states.pvp.CharacterSelectState;
import states.pvp.RulesetState;
import states.pvp.SongSelectState;
import ui.lists.MenuList.TypedMenuList;
import ui.lists.TextMenuList;

class PauseSubState extends FlxSubState
{
	var state:PlayState;
	var menuList:PauseMenuList;
	var camSubState:FlxCamera;
	var camFollow:FlxObject;
	var playerText:FlxText;
	var music:FlxSound;

	public function new(state:PlayState)
	{
		super();
		this.state = state;

		camSubState = new FlxCamera();
		camSubState.bgColor = FlxColor.fromRGBFloat(0, 0, 0, 0.6);
		camSubState.visible = false;
		FlxG.cameras.add(camSubState, false);

		menuList = new PauseMenuList();
		menuList.onChange.add(onChange);
		menuList.cameras = [camSubState];
		add(menuList);

		menuList.createItem('Resume', function()
		{
			close();
		});
		menuList.createItem('Restart song', function()
		{
			FlxG.switchState(new PlayState(state.song, state.chars));
		});
		menuList.createItem('Exit to options', function()
		{
			state.exit(new OptionsState(new PlayState(state.song, state.chars)), false);
			CoolUtil.playMenuMusic();
		});
		menuList.createItem('Exit to character select', function()
		{
			state.exit(new CharacterSelectState());
			CoolUtil.playPvPMusic();
		});
		menuList.createItem('Exit to song select', function()
		{
			state.exit(new SongSelectState());
			CoolUtil.playPvPMusic();
		});
		menuList.createItem('Exit to ruleset settings', function()
		{
			state.exit(new RulesetState());
			CoolUtil.playPvPMusic();
		});

		playerText = new FlxText(0, 10);
		playerText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		playerText.cameras = [camSubState];
		playerText.scrollFactor.set();
		add(playerText);

		camFollow = new FlxObject(FlxG.width / 2);
		add(camFollow);

		camSubState.follow(camFollow, LOCKON, 0.1);

		menuList.selectItem(0);
		camSubState.snapToTarget();

		music = FlxG.sound.load(Paths.getMusic('Breakfast'), 0, true, FlxG.sound.defaultMusicGroup);

		openCallback = function()
		{
			camSubState.visible = true;
			music.volume = 0;
			music.play(false, FlxG.random.float(0, music.length / 2));
		}
		closeCallback = function()
		{
			camSubState.visible = false;
			music.stop();
		}
	}

	override function update(elapsed:Float)
	{
		if (music.volume < 0.5)
			music.volume = Math.min(music.volume + (elapsed * 0.01), 0.5);

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
		state = null;
		menuList = null;
		camSubState = null;
		camFollow = null;
		playerText = null;
		music = null;
	}

	public function onOpen(player:Int)
	{
		menuList.controlsMode = PLAYER(player);
		playerText.text = 'P' + (player + 1) + ' PAUSE';
		playerText.x = FlxG.width - 10 - playerText.width;
	}

	function onChange(item:TextMenuItem)
	{
		updateCamFollow(item);
	}

	function updateCamFollow(item:TextMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}
}

class PauseMenuList extends TypedMenuList<TextMenuItem>
{
	public function createItem(name:String, ?callback:Void->Void)
	{
		var item = new TextMenuItem(0, (156 * length), name, callback);
		item.screenCenter(X);
		return addItem(name, item);
	}
}
