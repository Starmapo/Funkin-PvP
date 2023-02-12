package data;

typedef ReceptorSkin =
{
	var receptors:Array<ReceptorData>;
	var receptorsCenterAnimation:Bool;
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
	var ?staticOffset:Array<Float>;
	var ?pressedOffset:Array<Float>;
	var ?confirmOffset:Array<Float>;
} 
