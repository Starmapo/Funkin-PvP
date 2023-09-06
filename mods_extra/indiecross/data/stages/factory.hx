var brightShader:FlxRuntimeShader;
var defaultBrightVal:Float = -0.05;
var brightSpeed:Float = 0.5;
var brightMagnitude:Float = 0.05;

function onCreatePost()
{
	if (Settings.shaders)
	{
		brightShader = getShader("bright");
		brightShader.setFloat("contrast", 1);
		FlxG.camera.addShader(brightShader);
	}
	else
		close();
}

function onUpdatePost(elapsed)
{
	if (brightSpeed != 0)
		setBrightness(defaultBrightVal + Math.sin((timing.audioPosition / 1000) * (timing.curTimingPoint != null ? (timing.curTimingPoint.bpm / 60) : 1) * brightSpeed) * brightMagnitude);
	else
		setBrightness(defaultBrightVal);
}

function setBrightness(value)
{
	if (brightShader != null)
		brightShader.setFloat("brightness", value);
}