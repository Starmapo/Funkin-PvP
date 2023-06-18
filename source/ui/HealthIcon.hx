package ui;

import data.char.IconInfo;
import haxe.io.Path;
import sprites.AnimatedSprite;

class HealthIcon extends AnimatedSprite
{
	public var icon(default, set):String;
	public var info(default, null):IconInfo;

	public function new(x:Float = 0, y:Float = 0, icon:String = 'face')
	{
		super(x, y);
		frameOffsetScale = 1;
		this.icon = icon;
	}

	public function reloadGraphic()
	{
		info = IconInfo.loadIconFromName(icon);
		if (info == null)
			info = new IconInfo({});

		var nameInfo = CoolUtil.getNameInfo(icon);
		var name = nameInfo.name;
		var mod = nameInfo.mod;

		var imagePath = '';
		if (info.image.length > 0)
			imagePath = Paths.getPath('images/${info.image}.png', mod);
		else
		{
			imagePath = Paths.getPath('images/icons/$name.png', mod);
			if (!Paths.exists(imagePath))
				imagePath = Paths.getPath('images/icons/icon-$name.png', mod);
			if (!Paths.exists(imagePath))
			{
				mod = 'fnf';
				imagePath = Paths.getPath('images/icons/$name.png', mod);
			}
			if (!Paths.exists(imagePath))
			{
				name = 'face';
				mod = 'fnf';
				imagePath = Paths.getPath('images/icons/$name.png', mod);
			}
		}

		var path = Path.withoutExtension(imagePath);

		if (Paths.isSpritesheet(path, mod))
		{
			frames = Paths.getSpritesheet(path, mod);

			addAnim({
				name: 'normal',
				atlasName: info.normalAnim,
				fps: info.normalFPS
			}, true);
			if (info.frames > 1)
				addAnim({
					name: 'losing',
					atlasName: info.losingAnim,
					fps: info.losingFPS,
					offset: info.losingOffset
				});
			if (info.frames > 2)
				addAnim({
					name: 'winning',
					atlasName: info.winningAnim,
					fps: info.winningFPS,
					offset: info.winningOffset
				});
		}
		else
		{
			var image = Paths.getImage(imagePath, mod);
			loadGraphic(image, true, Std.int(image.width / info.frames), image.height);

			addAnim({
				name: 'normal',
				indices: [0],
				fps: 0,
				loop: false
			}, true);
			if (info.frames > 1)
				addAnim({
					name: 'losing',
					indices: [1],
					fps: 0,
					loop: false
				});
			if (info.frames > 2)
				addAnim({
					name: 'winning',
					indices: [2],
					fps: 0,
					loop: false
				});
		}
		antialiasing = info.antialiasing;
	}

	override function destroy()
	{
		super.destroy();
		info = null;
	}

	function set_icon(value:String)
	{
		if (value != null && icon != value)
		{
			icon = value;
			reloadGraphic();
		}
		return value;
	}
}
