package data;

typedef ReceptorSkin =
{
	var columnSize:Float;
	var receptors:Array<ReceptorData>;
	var receptorsImage:String;
	var receptorsOffset:Array<Float>;
	var receptorsPadding:Float;
	var receptorsScale:Float;

	var antialiasing:Bool;
}

typedef ReceptorData =
{
	var staticAnim:String;
	var pressedAnim:String;
	var confirmAnim:String;
	var ?staticFPS:Float;
	var ?pressedFPS:Float;
	var ?confirmFPS:Float;
}
