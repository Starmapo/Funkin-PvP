package objects;

import backend.structures.char.IconInfo;
import flixel.math.FlxPoint;
import haxe.io.Path;

class HealthIcon extends AnimatedSprite
{
	public static function getImagePath(info:IconInfo)
	{
		var name = info.name;
		var mod = info.mod;
		
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
		}
		if (!Paths.exists(imagePath))
		{
			name = 'face';
			mod = 'fnf';
			imagePath = Paths.getPath('images/icons/$name.png', mod);
		}
		
		return imagePath;
	}
	
	public var icon(default, set):String;
	public var info(default, null):IconInfo;
	
	public function new(x:Float = 0, y:Float = 0, icon:String = 'face')
	{
		super(x, y);
		setOffsetScale(1, 1);
		this.icon = icon;
	}
	
	public function reloadGraphic()
	{
		info = IconInfo.loadIconFromName(icon);
		
		var imagePath = getImagePath(info);
		var path = Path.withoutExtension(imagePath);
		
		if (Paths.isSpritesheet(path))
		{
			frames = Paths.getSpritesheet(path);
			
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
			var image = Paths.getImage(imagePath);
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
					loop: false,
					offset: info.losingOffset
				});
			if (info.frames > 2)
				addAnim({
					name: 'winning',
					indices: [2],
					fps: 0,
					loop: false,
					offset: info.winningOffset
				});
		}
		antialiasing = info.antialiasing && Settings.antialiasing;
	}
	
	override function calculateOffset(offset:FlxPoint)
	{
		var daOffset = super.calculateOffset(offset);
		if (!flipX)
			return daOffset;
			
		var newOffset = FlxPoint.weak().copyFrom(daOffset);
		newOffset.x *= -1;
		return newOffset;
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
	
	override function set_flipX(value:Bool)
	{
		if (flipX != value)
		{
			flipX = value;
			updateOffset();
		}
		return value;
	}
}
