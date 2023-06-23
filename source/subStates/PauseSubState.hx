package subStates;

import data.Mods;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import states.PlayState;
import states.options.OptionsState;
import states.pvp.CharacterSelectState;
import states.pvp.RulesetState;
import states.pvp.SongSelectState;
import ui.lists.MenuList.TypedMenuList;
import ui.lists.TextMenuList;

class PauseSubState extends FNFSubState
{
	var state:PlayState;
	var menuList:PauseMenuList;
	var camFollow:FlxObject;
	var playerText:FlxText;
	var music:FlxSound;

	public function new(state:PlayState)
	{
		super();
		this.state = state;

		music = FlxG.sound.load(Paths.getMusic('Breakfast'), 0, true, FlxG.sound.defaultMusicGroup);

		createCamera();

		menuList = new PauseMenuList();
		menuList.onChange.add(onChange);
		menuList.createItem('Resume', function()
		{
			close();
		});
		menuList.createItem('Restart song', function()
		{
			music.stop();
			menuList.controlsEnabled = false;
			state.exit(new PlayState(state.song, state.chars));
		});
		menuList.createItem('Exit to options', function()
		{
			music.stop();
			menuList.controlsEnabled = false;
			state.exit(new OptionsState(new PlayState(state.song, state.chars)));
			CoolUtil.playMenuMusic();
		});
		menuList.createItem('Exit to character select', function()
		{
			music.stop();
			menuList.controlsEnabled = false;
			state.exit(new CharacterSelectState());
			CoolUtil.playPvPMusic();
		});
		menuList.createItem('Exit to song select', function()
		{
			music.stop();
			menuList.controlsEnabled = false;
			state.exit(new SongSelectState());
			CoolUtil.playPvPMusic();
		});
		menuList.createItem('Exit to ruleset settings', function()
		{
			music.stop();
			menuList.controlsEnabled = false;
			state.exit(new RulesetState());
			CoolUtil.playPvPMusic();
		});
		add(menuList);

		playerText = new FlxText(0, 10);
		playerText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		playerText.scrollFactor.set();
		playerText.active = false;
		add(playerText);

		camFollow = new FlxObject(FlxG.width / 2);
		camFollow.exists = false;
		add(camFollow);

		camSubState.follow(camFollow, LOCKON, 0.1);

		menuList.selectItem(0);
		camSubState.snapToTarget();
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
		menuList = FlxDestroyUtil.destroy(menuList);
		camSubState = FlxDestroyUtil.destroy(camSubState);
		camFollow = FlxDestroyUtil.destroy(camFollow);
		playerText = FlxDestroyUtil.destroy(playerText);
		music = FlxDestroyUtil.destroy(music);
	}

	override function onOpen()
	{
		music.volume = 0;
		music.play(false, FlxG.random.float(0, music.length / 2));
		super.onOpen();
	}

	override function onClose()
	{
		music.stop();
		super.onClose();
	}

	public function setPlayer(player:Int)
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
		item.active = false;
		return addItem(name, item);
	}
}
