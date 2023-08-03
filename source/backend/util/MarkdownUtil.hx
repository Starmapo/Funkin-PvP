package backend.util;

import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class MarkdownUtil
{
	static final HEADING_1:String = "{header1}";
	static final HEADING_2:String = "{header2}";
	static final HEADING_3:String = "{header3}";
	static final LIST_1:String = "{list1}";
	static final LIST_2:String = "{list2}";
	static final LIST_3:String = "{list3}";
	static final LIST_4:String = "{list4}";
	static final QUOTE:String = "{quote}";
	static final BOLD:String = "{bold}";
	static final ITALIC:String = "{italic}";
	static final BOLD_ITALIC:String = "{bold-italic}";
	
	@:access(flixel.text.FlxText)
	public static function applyMarkdown(spr:FlxText, text:String)
	{
		if (text == null)
			return;
			
		spr.textField.htmlText = parseMarkdown(text);
		
		final pairs = [
			createHeadingMarkerPair(HEADING_1, Std.int(spr.size * 2)),
			createHeadingMarkerPair(HEADING_2, Std.int(spr.size * 1.5)),
			createHeadingMarkerPair(HEADING_3, Std.int(spr.size * 1.25)),
			createListMarkerPair(LIST_1, Std.int(spr.size * 2)),
			createListMarkerPair(LIST_2, Std.int(spr.size * 4)),
			createListMarkerPair(LIST_3, Std.int(spr.size * 6)),
			createListMarkerPair(LIST_4, Std.int(spr.size * 8)),
			createAdvancedMarkerPair(QUOTE, 0xFF999FA6),
			createAdvancedMarkerPair(BOLD_ITALIC, null, true, true),
			createAdvancedMarkerPair(BOLD, null, true),
			createAdvancedMarkerPair(ITALIC, null, null, true)
		];
		
		spr.applyMarkup(spr.textField.text, pairs);
	}
	
	static function parseMarkdown(text:String)
	{
		final delimiter = '\n';
		
		final splitText = text.split(delimiter);
		for (i in 0...splitText.length)
		{
			final t = splitText[i];
			splitText[i] = parseMarkdownLine(t);
		}
		
		return Markdown.markdownToHtml(splitText.join(delimiter));
	}
	
	static function parseMarkdownLine(text:String)
	{
		text = convertBeginning(text, "### ", HEADING_3);
		text = convertBeginning(text, "## ", HEADING_2);
		text = convertBeginning(text, "# ", HEADING_1);
		
		text = convertBeginning(text, "- ", LIST_1 + "&nbsp;&nbsp;• ", LIST_1);
		text = convertBeginning(text, "    - ", LIST_2 + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• ", LIST_2);
		text = convertBeginning(text, "        - ", LIST_3 + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• ", LIST_3);
		text = convertBeginning(text, "            - ", LIST_4 + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• ",
			LIST_4);
			
		text = convertBeginning(text, "> ", QUOTE);
		
		text = convertAll(text, "***", BOLD_ITALIC);
		text = convertAll(text, "**", BOLD);
		text = convertAll(text, "*", ITALIC);
		text = convertAll(text, "__", BOLD);
		text = convertAll(text, "_", ITALIC);
		
		text = convertAll(text, "~~", "");
		text = convertAll(text, "<sub>", "");
		text = convertAll(text, "</sub>", "");
		text = convertAll(text, "<sup>", "");
		text = convertAll(text, "</sup>", "");
		
		return text;
	}
	
	static function convertBeginning(text:String, start:String, marker:String, ?endMarker:String)
	{
		if (endMarker == null)
			endMarker = marker;
			
		if (text.startsWith(start))
			text = marker + text.substr(start.length) + endMarker;
			
		return text;
	}
	
	static function convertAll(text:String, sub:String, marker:String)
	{
		return text.replace(sub, marker);
	}
	
	@:access(flixel.text.FlxTextFormat)
	static function createAdvancedMarkerPair(marker:String, ?fontColor:FlxColor, ?bold:Bool, ?italic:Bool, ?borderColor:FlxColor, ?size:Int, ?underline:Bool,
			?blockIndent:Int, ?bullet:Bool)
	{
		final format = new FlxTextFormat(fontColor, bold, italic, borderColor);
		format.format.size = size;
		format.format.underline = underline;
		format.format.blockIndent = blockIndent;
		format.format.bullet = bullet;
		return new FlxTextFormatMarkerPair(format, marker);
	}
	
	static function createHeadingMarkerPair(marker:String, ?size:Int)
	{
		return createAdvancedMarkerPair(marker, null, null, null, null, size, true);
	}
	
	static function createListMarkerPair(marker:String, ?blockIndent:Int)
	{
		return createAdvancedMarkerPair(marker, null, null, null, null, null, null, blockIndent, true);
	}
}
