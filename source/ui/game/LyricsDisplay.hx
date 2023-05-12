package ui.game;

import data.song.LyricStep;
import data.song.Song;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class LyricsDisplay extends FlxText
{
	public var song:Song;
	public var lyrics(default, set):String;
	public var lines:Array<LyricsLine> = [];

	var time:Float = 0;
	var lastIndex:Int = -1;

	public function new(song:Song, lyrics:String)
	{
		super(0, 130, FlxG.width / 2);
		this.song = song;

		setFormat('PhantomMuff 1.5', 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		screenCenter(X);
		scrollFactor.set();

		this.lyrics = lyrics;
	}

	public function updateLyrics(time:Float)
	{
		this.time = time;
		var i = lines.length - 1;
		while (i >= 0)
		{
			if (lines[i].steps.length > 0 && lines[i].steps[0].startTime <= time)
			{
				updateWithLyric(lines[i]);
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
			if (!lyric.contains(' ') && !lyric.contains('/'))
				line.splitWords.push(lyric);
			else
			{
				var i = 0;
				var lastSplit = 0;
				while (i < lyric.length)
				{
					var char = lyric.charAt(i);
					if (char == ' ' || char == '/')
					{
						var len = i - lastSplit;
						if (char == ' ')
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
		updateLyrics(time);
	}

	override function destroy()
	{
		super.destroy();
		song = null;
		lines = null;
	}

	function updateWithLyric(lyric:LyricsLine)
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
				len += lyric.splitWords[i].length;
		}

		var lyricText = lyric.splitWords.join('');
		if (text != lyricText || stepIndex != lastIndex)
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
