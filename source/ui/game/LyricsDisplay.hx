package ui.game;

import data.song.LyricStep;
import data.song.Song;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.StringUtil;

using StringTools;

class LyricsDisplay extends FlxText
{
	static var splitChars:Array<String> = [' ', '/', '-'];
	static var keepChars:Array<String> = [' ', '-'];
	
	public static inline function getLyricText(text:String)
	{
		return text.replace('\\s', ' ').replace('\\h', '-');
	}
	
	public var song:Song;
	public var lyrics(default, set):String;
	public var lines:Array<LyricsLine> = [];
	
	var time:Float = 0;
	var lastIndex:Int = -1;
	
	public function new(song:Song, lyrics:String, fieldWidth:Float = 0)
	{
		if (fieldWidth <= 0)
			fieldWidth = FlxG.width / 2;
		super(0, 200, fieldWidth);
		this.song = song;
		
		setFormat('PhantomMuff 1.5', 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		screenCenter(X);
		scrollFactor.set();
		
		this.lyrics = lyrics;
	}
	
	public function updateLyrics(time:Float, force:Bool = false)
	{
		this.time = time;
		var i = lines.length - 1;
		while (i >= 0)
		{
			if (lines[i].steps.length > 0 && lines[i].steps[0].startTime <= time)
			{
				updateWithLyric(lines[i], force);
				break;
			}
			i--;
		}
		if (i == -1)
		{
			text = '';
			clearFormats();
		}
	}
	
	public function initialize()
	{
		lines.resize(0);
		var splitLyrics = lyrics.split('\n');
		var currentStep = 0;
		var addedSteps:Array<LyricStep> = [];
		for (lyric in splitLyrics)
		{
			lyric = lyric.trim();
			var line:LyricsLine = {
				splitWords: [],
				steps: []
			}
			if (!StringUtil.containsAny(lyric, splitChars))
				line.splitWords.push(lyric);
			else
			{
				var i = 0;
				var lastSplit = 0;
				while (i < lyric.length)
				{
					var char = lyric.charAt(i);
					if (splitChars.contains(char))
					{
						var len = i - lastSplit;
						if (keepChars.contains(char))
							len++;
						line.splitWords.push(lyric.substr(lastSplit, len));
						lastSplit = i + 1;
					}
					i++;
				}
				if (lastSplit != i)
					line.splitWords.push(lyric.substr(lastSplit));
			}
			for (i in 0...line.splitWords.length)
			{
				var step = song.lyricSteps[currentStep];
				if (step != null)
				{
					line.steps.push(step);
					addedSteps.push(step);
					currentStep++;
				}
			}
			lines.push(line);
		}
		var finalStep = song.lyricSteps[song.lyricSteps.length - 1];
		if (finalStep != null && !addedSteps.contains(finalStep))
			lines.push({
				splitWords: [''],
				steps: [finalStep]
			});
		updateLyrics(time, true);
	}
	
	override function update(elapsed:Float) {}
	
	override function destroy()
	{
		super.destroy();
		song = null;
		lines = null;
	}
	
	function updateWithLyric(lyric:LyricsLine, force:Bool = false)
	{
		var stepIndex = lyric.steps.length - 1;
		while (stepIndex >= 0)
		{
			if (lyric.steps[stepIndex].startTime <= time)
				break;
				
			stepIndex--;
		}
		
		var len = 0;
		if (stepIndex >= 0)
		{
			for (i in 0...stepIndex + 1)
				len += getLyricText(lyric.splitWords[i]).length;
		}
		
		var lyricText = getLyricText(lyric.splitWords.join(''));
		if (text != lyricText || stepIndex != lastIndex || force)
		{
			text = lyricText;
			clearFormats();
			if (len > 0)
				addFormat(new FlxTextFormat(FlxColor.YELLOW), 0, len);
		}
		lastIndex = stepIndex;
	}
	
	function set_lyrics(value:String)
	{
		if (lyrics != value)
		{
			lyrics = value;
			initialize();
		}
		return value;
	}
}

typedef LyricsLine =
{
	var splitWords:Array<String>;
	var steps:Array<LyricStep>;
}
