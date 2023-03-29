package ui.editors.song;

import flixel.FlxSprite;
import sprites.AnimatedSprite;
import states.editors.SongEditorState;

class SongEditorCamFocusDisplay extends AnimatedSprite
{
	var state:SongEditorState;

	public function new(x:Float = 0, y:Float = 0, state:SongEditorState)
	{
		super(x, y);
		this.state = state;
		loadGraphic(Paths.getImage('editors/song/camFocus'), true, 150, 75);
		for (i in 0...3)
			animation.add(Std.string(i), [i], 0, false);
		updateDisplay();
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		updateDisplay();
	}

	public function updateDisplay()
	{
		var anim:String = null;
		var camFocus = state.song.getCameraFocusAt(state.inst.time);
		if (camFocus == null)
			anim = '0';
		else
			anim = Std.string(camFocus.char);
		if (anim != null && animation.name != anim)
			playAnim(anim);
	}
}
