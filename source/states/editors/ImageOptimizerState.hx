package states.editors;

import data.Mods;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import haxe.io.Path;
import lime.app.Application;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Rectangle;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import sys.thread.Mutex;
import sys.thread.Thread;
import systools.Dialogs;
import ui.editors.EditorDropdownMenu;
import ui.editors.EditorPanel;

using StringTools;

class ImageOptimizerState extends FNFState
{
	var folderDropdown:EditorDropdownMenu;
	var bar:FlxBar;
	var progressText:FlxText;
	var canExit:Bool = true;
	var mutex:Mutex;
	var progress:ProgressData;
	var doneSpritesheets:Bool = false;
	var oxipng:Bool = false;
	var folders:Array<String> = [];
	var optimizing:Bool = false;

	public function new()
	{
		super();
		checkObjects = true;
		persistentUpdate = true;
	}

	override function create()
	{
		mutex = new Mutex();

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF353535;
		add(bg);

		progressText = new FlxText(0, FlxG.height * 0.65);
		progressText.setFormat(null, 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		progressText.exists = false;
		add(progressText);

		bar = new FlxBar(0, FlxG.height * 0.75, LEFT_TO_RIGHT, Std.int(FlxG.width / 2));
		bar.exists = false;
		bar.screenCenter(X);
		bar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
		add(bar);

		var tabMenu = new EditorPanel([
			{
				name: 'tab',
				label: 'Image Optimizer'
			}
		]);
		tabMenu.resize(270, 75);

		var tab = tabMenu.createTab('tab');
		var spacing = 4;

		folders.push("assets/");
		for (mod in Mods.currentMods)
		{
			if (mod.zip)
				continue;

			var folder = Path.join([Mods.modsPath, mod.directory]);
			if (!folder.endsWith("/"))
				folder += "/";
			folders.push(folder);
		}

		folderDropdown = new EditorDropdownMenu(0, 4, EditorDropdownMenu.makeStrIdLabelArray(folders), null, tabMenu, 160);
		folderDropdown.x += (tabMenu.width - folderDropdown.width) / 2;

		var optimizeButton = new FlxUIButton(0, folderDropdown.y + folderDropdown.height + spacing, "Optimize Images", function()
		{
			if (!optimizing)
				startOptimize();
		});
		optimizeButton.resize(120, optimizeButton.height);
		optimizeButton.x += (tabMenu.width - optimizeButton.width) / 2;
		tab.add(optimizeButton);

		tab.add(folderDropdown);
		tabMenu.addGroup(tab);
		tabMenu.screenCenter();
		add(tabMenu);

		Application.current.window.onDropFile.add(onDropFile);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (progress != null)
		{
			mutex.acquire();
			var text = if (oxipng)
			{
				"Optimizing with Oxipng...";
			}
			else
			{progress.current
				+ "/"
				+ progress.total
				+ " ("
				+ (progress.total > 0 ? Math.round(progress.current / progress.total * 100) : 0)
				+ "%)";
			}
			if (progressText.text != text)
			{
				progressText.text = text;
				progressText.screenCenter(X);
			}
			if (bar.value != progress.current)
				bar.value = progress.current;
			if (doneSpritesheets && !oxipng)
			{
				CoolUtil.playConfirmSound();
				doneSpritesheets = false;
				canExit = true;
			}
			mutex.release();
		}
		if (FlxG.keys.justPressed.SPACE && oxipng)
			trace(Sys.stdout());
		if (FlxG.keys.justPressed.ESCAPE && canExit)
		{
			persistentUpdate = false;
			FlxG.switchState(new ToolboxState());
		}

		super.update(elapsed);

		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}

	override function destroy()
	{
		super.destroy();
		Application.current.window.onDropFile.remove(onDropFile);
		folderDropdown = null;
		bar = null;
		progressText = null;
		mutex = null;
		progress = null;
	}

	function onDropFile(path:String)
	{
		if (!FileSystem.isDirectory(path))
			return;

		path = Path.normalize(path);
		var cwd = Path.normalize(Sys.getCwd());
		if (!path.startsWith(cwd))
			return;

		path = path.substr(cwd.length);
		if (!path.endsWith('/'))
			path += '/';
		folderDropdown.selectedLabel = path;
	}

	function startOptimize()
	{
		var folder = folderDropdown.selectedLabel;
		var images:Array<String> = [];
		var spritesheets:Array<String> = [];
		function readFolder(path:String)
		{
			for (file in FileSystem.readDirectory(path))
			{
				var fullPath = Path.join([path, file]);
				if (FileSystem.isDirectory(fullPath))
					readFolder(fullPath);
				else if (Path.extension(file) == "png")
				{
					images.push(fullPath);
					var idk = Path.withoutExtension(fullPath);
					if (FileSystem.exists(idk + ".xml"))
						spritesheets.push(idk);
				}
			}
		}
		readFolder(folder);
		if (images.length < 1)
			return;

		optimizing = true;
		doneSpritesheets = canExit = false;

		progress = {current: 0, total: spritesheets.length};
		progressText.exists = true;
		progressText.text = "0/" + progress.total + " (0%)";
		progressText.screenCenter(X);
		bar.exists = true;
		bar.setRange(0, Math.max(spritesheets.length, 1));
		bar.value = 0;

		var i = 0;
		Thread.create(function()
		{
			while (i < spritesheets.length)
			{
				optimize(spritesheets[i]);

				i++;
				mutex.acquire();
				progress.current = i;
				mutex.release();
			}

			if (FileSystem.exists('./oxipng.exe'))
			{
				mutex.acquire();
				oxipng = true;
				mutex.release();
				Sys.command("oxipng", images);
			}

			mutex.acquire();
			doneSpritesheets = true;
			optimizing = oxipng = false;
			mutex.release();
		});
	}

	function optimize(path:String)
	{
		var frames = Paths.getSpritesheet(path);
		if (frames == null)
			return;
		var image = frames.parent;

		function dispose()
		{
			FlxG.bitmap.remove(frames.parent);
			frames.destroy();
		}

		var maxX = 0;
		var maxY = 0;
		for (frame in frames.frames)
		{
			var x = frame.frame.x + frame.frame.width;
			var y = frame.frame.y + frame.frame.height;
			if (x > maxX)
				maxX = Std.int(x);
			if (y > maxY)
				maxY = Std.int(y);
		}
		if (maxX <= 0 || maxY <= 0 || (image.width <= maxX && image.height <= maxY))
		{
			dispose();
			return;
		}

		File.saveBytes(path + ".png", image.bitmap.encode(new Rectangle(0, 0, maxX, maxY), new PNGEncoderOptions()));

		dispose();
	}
}

typedef ProgressData =
{
	var current:Int;
	var total:Int;
}
