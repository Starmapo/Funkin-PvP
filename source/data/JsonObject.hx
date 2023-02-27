package data;

import flixel.math.FlxMath;
import flixel.util.FlxColor;

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
		Returns a color value from a JSON file, whether it be an integer, a string, or an array.
		* @param value 			The property from the JSON file.
		* @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is the color white.
	**/
	function readColor(value:Dynamic, defaultValue:FlxColor = FlxColor.WHITE):FlxColor
	{
		var color:Null<FlxColor> = null;
		if (value != null)
		{
			if (Std.isOfType(value, Array))
			{
				var colorArray:Array<Int> = cast value;
				if (colorArray != null && colorArray.length >= 3)
				{
					if (colorArray.length > 3)
						color = FlxColor.fromRGB(colorArray[0], colorArray[1], colorArray[2], colorArray[3]);
					else
						color = FlxColor.fromRGB(colorArray[0], colorArray[1], colorArray[2]);
				}
			}
			else if (Std.isOfType(value, String))
			{
				var colorString:String = cast value;
				color = FlxColor.fromString(colorString);
			}
			else if (Std.isOfType(value, Int))
			{
				var colorInt:Int = cast value;
				color = new FlxColor(colorInt);
			}
		}

		if (color == null)
			color = defaultValue;

		return color;
	}

	/**
	 * Returns a dynamic array from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is an empty array.
	 * @param maxLength 	Optional parameter to set the maximum length of the returned array. The array will have the last elements removed until its the maximum length. Has no effect if `fixedLength` is set.
	 * @param fixedLength	Optional parameter to set the fixed length of the returned array. If the array has less or more elements than this, the default value is returned. This overrides `maxLength`.
	 */
	function readArray(value:Array<Dynamic>, ?defaultValue:Array<Dynamic>, ?maxLength:Int, ?fixedLength:Int):Array<Dynamic>
	{
		if (defaultValue == null)
			defaultValue = [];

		var array:Array<Dynamic> = readProperty(value, defaultValue);
		if (fixedLength != null && array.length != fixedLength)
		{
			array = defaultValue;
		}
		else if (maxLength != null)
		{
			while (array.length > maxLength)
			{
				array.pop();
			}
		}
		return array;
	}

	/**
	 * Returns a typed array from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is an empty array.
	 * @param maxLength 	Optional parameter to set the maximum length of the returned array. The array will have the last elements removed until its the maximum length. Has no effect if `fixedLength` is set.
	 * @param fixedLength	Optional parameter to set the fixed length of the returned array. If the array has less or more elements than this, the default value is returned. This overrides `maxLength`.
	 */
	@:generic
	function readTypedArray<T>(value:Array<T>, ?defaultValue:Array<T>, ?maxLength:Int, ?fixedLength:Int):Array<T>
	{
		if (defaultValue == null)
			defaultValue = [];

		var array:Array<T> = readProperty(value, defaultValue);
		if (fixedLength != null && array.length != fixedLength)
		{
			array = defaultValue;
		}
		else if (maxLength != null)
		{
			while (array.length > maxLength)
			{
				array.pop();
			}
		}
		return array;
	}

	/**
	 * Returns an integer array from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is an empty array.
	 * @param maxLength 	Optional parameter to set the maximum length of the returned array. The array will have the last elements removed until its the maximum length. Has no effect if `fixedLength` is set.
	 * @param fixedLength	Optional parameter to set the fixed length of the returned array. If the array has less or more elements than this, the default value is returned. This overrides `maxLength`.
	 * @param minValue 		If set, values in the array will not go below this parameter.
	 * @param maxValue 		If set, values in the array will not go above this parameter.
	 */
	function readIntArray(value:Array<Int>, ?defaultValue:Array<Int>, ?maxLength:Int, ?fixedLength:Int, ?minValue:Int, ?maxValue:Int):Array<Int>
	{
		var array:Array<Int> = readTypedArray(value, defaultValue, maxLength, fixedLength);

		if (minValue != null || maxValue != null)
		{
			for (int in array)
			{
				if (minValue != null && int < minValue)
					int = minValue;
				if (maxValue != null && int > maxValue)
					int = maxValue;
			}
		}

		return array;
	}

	/**
	 * Returns a float array from a JSON file.
	 * @param value 		The property from the JSON file.
	 * @param defaultValue 	A value to return if the property doesn't exist on the JSON file. The default is an empty array.
	 * @param maxLength 	Optional parameter to set the maximum length of the returned array. The array will have the last elements removed until its the maximum length. Has no effect if `fixedLength` is set.
	 * @param fixedLength	Optional parameter to set the fixed length of the returned array. If the array has less or more elements than this, the default value is returned. This overrides `maxLength`.
	 * @param minValue 		If set, values in the array will not go below this parameter.
	 * @param maxValue 		If set, values in the array will not go above this parameter.
	 * @param decimals 		If set, values in the array will be rounded in case there's more decimals than stated in this parameter.
	 */
	function readFloatArray(value:Array<Float>, ?defaultValue:Array<Float>, ?maxLength:Int, ?fixedLength:Int, ?minValue:Float, ?maxValue:Float,
			?decimals:Int):Array<Float>
	{
		var array:Array<Float> = readTypedArray(value, defaultValue, maxLength, fixedLength);

		if (minValue != null || maxValue != null || decimals != null)
		{
			for (float in array)
			{
				if (minValue != null && float < minValue)
					float = minValue;
				if (maxValue != null && float > maxValue)
					float = maxValue;
				if (decimals != null && FlxMath.getDecimals(float) > decimals)
					float = FlxMath.roundDecimal(float, decimals);
			}
		}

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
