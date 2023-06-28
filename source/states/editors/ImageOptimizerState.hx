package states.editors;

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
import sys.thread.Mutex;
import sys.thread.Thread;
import systools.Dialogs;
import ui.editors.EditorPanel;

using StringTools;

class ImageOptimizerState extends FNFState
{
	var folder:String = '';
	var selectFolderButton:FlxUIButton;
	var bar:FlxBar;
	var progressText:FlxText;
	var canExit:Bool = true;
	var mutex:Mutex;
	var progress:ProgressData;
	var doneSpritesheets:Bool = false;

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

		var tabMenu = new EditorPanel([
			{
				name: 'tab',
				label: 'Image Optimizer'
			}
		]);
		tabMenu.resize(270, 75);

		var tab = tabMenu.createTab('tab');
		var spacing = 4;

		selectFolderButton = new FlxUIButton(0, 4, 'Select Folder', function()
		{
			var result = Dialogs.folder("Select folder to optimize", "");
			if (result == null)
			{
				if (folder.length > 0)
				{
					folderTween(FlxColor.RED);
					folder = '';
				}
				return;
			}

			folder = Path.normalize(result);
			folderTween(FlxColor.LIME);
		});
		selectFolderButton.x += (tabMenu.width - selectFolderButton.width) / 2;
		tab.add(selectFolderButton);

		var optimizeButton = new FlxUIButton(0, selectFolderButton.y + selectFolderButton.height + spacing, "Optimize Images", function()
		{
			if (folder.length < 1 || !FileSystem.exists(folder))
			{
				folderTween(FlxColor.RED);
				return;
			}
			var cwd = Path.normalize(Sys.getCwd());
			if (!folder.startsWith(cwd))
			{
				folderTween(FlxColor.RED);
				return;
			}

			startOptimize();
		});
		optimizeButton.resize(120, optimizeButton.height);
		optimizeButton.x += (tabMenu.width - optimizeButton.width) / 2;
		tab.add(optimizeButton);

		tabMenu.addGroup(tab);
		tabMenu.screenCenter();
		add(tabMenu);

		progressText = new FlxText(0, FlxG.height * 0.65);
		progressText.setFormat(null, 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		progressText.exists = false;
		add(progressText);

		bar = new FlxBar(0, FlxG.height * 0.75, LEFT_TO_RIGHT, Std.int(FlxG.width / 2));
		bar.exists = false;
		bar.screenCenter(X);
		bar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
		add(bar);

		Application.current.window.onDropFile.add(onDropFile);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (progress != null)
		{
			mutex.acquire();
			var text = progress.current + "/" + progress.total + " (" + (progress.current / progress.total * 100) + ")";
			if (progressText.text != text)
				progressText.text = text;
			if (bar.value != progress.current)
				bar.value = progress.current;
			if (doneSpritesheets)
			{
				CoolUtil.playConfirmSound();
				doneSpritesheets = false;
				canExit = true;
			}
			mutex.release();
		}
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
		selectFolderButton = null;
		bar = null;
		progressText = null;
		mutex = null;
	}

	function onDropFile(path:String)
	{
		if (!FileSystem.isDirectory(path))
			return;

		folder = Path.normalize(path);
		folderTween(FlxColor.LIME);
	}

	function folderTween(color:FlxColor)
	{
		FlxTween.cancelTweensOf(selectFolderButton);
		FlxTween.color(selectFolderButton, 0.2, selectFolderButton.color, color);
	}

	function startOptimize()
	{
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

		canExit = false;

		if (spritesheets.length > 0)
		{
			progress = {current: 0, total: spritesheets.length};
			progressText.exists = true;
			progressText.text = "0/" + progress.total + " (0%)";
			progressText.screenCenter(X);
			bar.exists = true;
			bar.setRange(0, spritesheets.length);
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
				mutex.acquire();
				doneSpritesheets = true;
				mutex.release();
			});
		}
	}

	function optimize(path:String)
	{
		var frames = Paths.getSpritesheet(path);
		if (frames == null)
			return;
		var image = frames.parent;

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
		if (maxX == 0 || maxY == 0)
			return;
		if (image.width <= maxX && image.height <= maxY)
			return;

		File.saveBytes(path + ".png", image.bitmap.encode(new Rectangle(0, 0, maxX, maxY), new PNGEncoderOptions()));
        
		FlxG.bitmap.remove(frames.parent);
        frames.destroy();
	}
}

typedef ProgressData =
{
	var current:Int;
	var total:Int;
}
