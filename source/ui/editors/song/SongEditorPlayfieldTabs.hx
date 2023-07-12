package ui.editors.song;

import flixel.FlxSprite;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUITypedButton;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxStringUtil;
import states.editors.SongEditorState;

class SongEditorPlayfieldTabs extends FlxTypedSpriteGroup<FlxUIButton>
{
	var state:SongEditorState;
	var tabs:Array<FlxUIButton> = [];
	
	public function new(state:SongEditorState)
	{
		super();
		this.state = state;
		
		var names = ['Notes', 'Other'];
		for (name in names)
		{
			var fb = new FlxUIButton(0, 0, name);
			
			fb.up_color = 0xffffff;
			fb.down_color = 0xffffff;
			fb.over_color = 0xffffff;
			fb.up_toggle_color = 0xffffff;
			fb.down_toggle_color = 0xffffff;
			fb.over_toggle_color = 0xffffff;
			
			fb.label.color = 0xFFFFFF;
			fb.label.setBorderStyle(OUTLINE);
			
			fb.name = name;
			
			var graphic_names:Array<FlxGraphicAsset> = [
				Paths.getImage('editors/tab_back'),
				Paths.getImage('editors/tab_back'),
				Paths.getImage('editors/tab_back'),
				Paths.getImage('editors/tab'),
				Paths.getImage('editors/tab'),
				Paths.getImage('editors/tab')
			];
			var slice9tab:Array<Int> = FlxStringUtil.toIntArray(FlxUIAssets.SLICE9_TAB);
			var slice9_names:Array<Array<Int>> = [slice9tab, slice9tab, slice9tab, slice9tab, slice9tab, slice9tab];
			fb.loadGraphicSlice9(graphic_names, 0, 0, slice9_names, FlxUI9SliceSprite.TILE_NONE, -1, true);
			fb.onUp.callback = onTabEvent.bind(fb.name);
			add(fb);
			tabs.push(fb);
		}
		scrollFactor.set();
		
		distributeTabs();
		onTabEvent('Notes');
	}
	
	public function stackTabs():Void
	{
		var tab:FlxUIButton = null;
		for (t in tabs)
		{
			tab = cast t;
			if (tab.toggled)
				group.remove(tab, true);
		}
		
		for (t in tabs)
		{
			tab = cast t;
			if (tab.toggled)
				group.add(tab);
		}
	}
	
	override function destroy()
	{
		super.destroy();
		state = null;
		tabs = null;
	}
	
	function distributeTabs(W:Float = -1):Void
	{
		if (W == -1)
			W = 320;
			
		var xx:Float = 0;
		var tab_width:Float = W / length;
		
		var diff_size:Float = 0;
		var tot_size:Float = (Std.int(tab_width) * length);
		if (tot_size < W)
			diff_size = (W - tot_size);
			
		var i:Int = 0;
		var firstHeight:Float = 0;
		
		var tab:FlxUIButton;
		for (t in members)
		{
			tab = cast t;
			
			tab.x = x + xx;
			tab.y = y;
			
			var theHeight:Float = tab.get_height();
			if (i != 0)
			{
				// when stretching, if resize_ratios are set, tabs can wind up with wrong heights since they might have different widths.
				// to solve this we cancel resize_ratios for all tabs except the first and make sure all subsequent tabs match the height
				// of the first tab
				theHeight = firstHeight;
				tab.resize_ratio = -1;
			}
			if (diff_size > 0)
			{
				tab.resize(tab_width + 1, theHeight);
				xx += (Std.int(tab_width) + 1);
				diff_size -= 1;
			}
			else
			{
				tab.resize(tab_width, theHeight);
				xx += Std.int(tab_width);
			}
			if (i == 0)
				firstHeight = tab.get_height(); // if we are stretching we will make everything match the height of the first tab
			i++;
		}
	}
	
	public function onTabEvent(name:String):Void
	{
		if (state.playfieldNotes != null)
		{
			state.playfieldNotes.exists = (name == 'Notes');
			state.playfieldOther.exists = (name == 'Other');
		}
		
		for (tab in members)
		{
			tab.toggled = false;
			tab.forceStateHandler(FlxUITypedButton.OUT_EVENT);
			if (tab.name == name)
				tab.toggled = true;
		}
		
		stackTabs();
	}
}
