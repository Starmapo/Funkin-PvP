package objects;

import flixel.system.FlxBGSprite;

class CameraBackground extends FlxBGSprite
{
	@:access(flixel.FlxCamera)
	override public function draw():Void
	{
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
			{
				continue;
			}
			
			_matrix.identity();
			_matrix.translate(camera.viewMarginX - 1, camera.viewMarginY - 1);
			_matrix.scale(camera.viewWidth + 2, camera.viewHeight + 2);
			camera.drawPixels(frame, _matrix, colorTransform);
			
			#if FLX_DEBUG
			flixel.FlxBasic.visibleCount++;
			#end
		}
	}
}
