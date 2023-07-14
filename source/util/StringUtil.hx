package util;

import flixel.util.FlxSort;

using StringTools;

class StringUtil
{
	/**
		Adds `s` to `text`, creating a new line if `text` isn't empty.
	**/
	public static function addMultilineText(text:String, s:String):String
	{
		if (text == null || text.length < 1)
			return s;
		if (s == null || s.length < 1)
			return text;
		text += '\n' + s;
		return text;
	}
	
	/**
		Returns if `s` contains any of the strings in `values`.
	**/
	public static function containsAny(s:String, values:Array<String>):Bool
	{
		if (values != null)
		{
			for (value in values)
			{
				if (s.contains(value))
					return true;
			}
		}
		return false;
	}
	
	/**
		Returns if `s` ends with any of the strings in `values`.
	**/
	public static function endsWithAny(s:String, values:Array<String>):Bool
	{
		if (values != null)
		{
			for (value in values)
			{
				if (s.endsWith(value))
					return true;
			}
		}
		return false;
	}
	
	/**
		Formats a number to an ordinal number.

		If the number is 0 or less, it won't be formatted.
	**/
	public static function formatOrdinal(num:Int):String
	{
		if (num <= 0)
			return Std.string(num);
			
		switch (num % 100)
		{
			case 11, 12, 13:
				return num + "th";
		}
		
		return switch (num % 10)
		{
			case 1:
				num + "st";
			case 2:
				num + "nd";
			case 3:
				num + "rd";
			default:
				num + "th";
		}
	}
	
	/**
		Sorts two strings alphabetically.

		@param	order	The order to use for sorting. You can use `FlxSort.ASCENDING` (default) or `FlxSort.DESCENDING`.
	**/
	public static function sortAlphabetically(a:String, b:String, order:Int = FlxSort.ASCENDING):Int
	{
		if (a == null)
			a = '';
		if (b == null)
			b = '';
			
		a = a.toLowerCase();
		b = b.toLowerCase();
		
		if (a < b)
			return order;
		if (a > b)
			return -order;
		return 0;
	}
}
