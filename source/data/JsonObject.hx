package data;

import flixel.math.FlxMath;

/**
	Basically this just allows for easily reading JSON files.
**/
class JsonObject
{
	/**
	 * Returns a property from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file.
	 */
	@:generic
	function readProperty<T>(value:T, defaultValue:T):T
	{
		if (value == null)
			return defaultValue;

		return value;
	}

	/**
	 * Returns a dynamic property from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file.
	 */
	function readDynamic(value:Dynamic, ?defaultValue:Dynamic):Dynamic
	{
		if (value == null)
			return defaultValue;

		return value;
	}

	/**
	 * Returns an integer value from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is `0`.
	 * @param min 			If set, the value will not go below this parameter.
	 * @param max 			If set, the value will not go above this parameter.
	 */
	function readInt(value:Null<Int>, defaultValue:Int = 0, ?min:Int, ?max:Int):Int
	{
		var int:Int = readProperty(value, defaultValue);

		if (min != null && int < min)
			int = min;
		if (max != null && int > max)
			int = max;

		return int;
	}

	/**
	 * Returns a float value from a JSON file.
	 * @param value 		The value from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is `0`.
	 * @param min 			If set, the value will not go below this parameter.
	 * @param max 			If set, the value will not go above this parameter.
	 * @param decimals 		If set, the value will be rounded in case there's more decimals than stated in this parameter.
	 */
	function readFloat(value:Null<Float>, defaultValue:Float = 0, ?min:Float, ?max:Float, ?decimals:Int):Float
	{
		var float:Float = readProperty(value, defaultValue);
		if (Math.isNaN(float))
			float = 0;

		if (min != null && float < min)
			float = min;
		if (max != null && float > max)
			float = max;
		if (decimals != null && FlxMath.getDecimals(float) > decimals)
			float = FlxMath.roundDecimal(float, decimals);

		return float;
	}

	/**
	 * Returns a boolean value from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is `false`.
	 */
	function readBool(value:Null<Bool>, defaultValue:Bool = false):Bool
	{
		return readProperty(value, defaultValue) == true;
	}

	/**
	 * Returns a string value from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is an empty string.
	 */
	function readString(value:String, defaultValue:String = ''):String
	{
		return readProperty(value, defaultValue);
	}

	/**
	 * Returns a dynamic array from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is an empty array.
	 */
	function readArray(value:Array<Dynamic>, ?defaultValue:Array<Dynamic>):Array<Dynamic>
	{
		if (defaultValue == null)
			defaultValue = [];

		var array:Array<Dynamic> = readProperty(value, defaultValue);
		return array;
	}

	/**
	 * Returns a typed array from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is an empty array.
	 */
	@:generic
	function readTypedArray<T>(value:Array<T>, ?defaultValue:Array<T>):Array<T>
	{
		if (defaultValue == null)
			defaultValue = [];

		var array:Array<T> = readProperty(value, defaultValue);
		return array;
	}

	/**
		Returns if a property isn't `null`.
	**/
	function propertyExists(value:Dynamic)
	{
		return value != null;
	}
}
