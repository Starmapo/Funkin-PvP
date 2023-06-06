package ui.editors;

import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITypedButton;
import flixel.addons.ui.interfaces.IResizable;
import flixel.util.FlxColor;

class EditorPanel extends FlxUITabMenu
{
	static var TAB_HEIGHT:Int = 18;

	var maxRows:Int;

	public function new(?tabs:Array<{name:String, label:String}>, maxRows:Int = 0)
	{
		super(null, null, tabs);
		this.maxRows = maxRows;
		for (tab in _tabs)
		{
			var tab:FlxUIButton = cast tab;
			tab.label.setBorderStyle(OUTLINE, FlxColor.BLACK);
		}
		scrollFactor.set();
	}

	override function resize(W:Float, H:Float):Void
	{
		var ir:IResizable;
		if ((_back is IResizable))
		{
			distributeTabs(W);
			ir = cast _back;
			ir.resize(W, H - getTabsHeight());
		}
		else
			distributeTabs();
	}

	override function distributeTabs(W:Float = -1):Void
	{
		var xx:Float = 0;
		var yy:Float = 0;

		var tab_width:Float = 0;

		if (W == -1)
			W = _back.width;

		var rows = (maxRows > 0 && _tabs.length > maxRows) ? maxRows : _tabs.length;
		var last_tab_width = tab_width;
		if (maxRows > 0 && _tabs.length % rows != 0)
			last_tab_width = W / (_tabs.length % rows);
		var diff_size:Float = 0;
		if (_stretch_tabs)
		{
			tab_width = W / rows;
			var tot_size:Float = (Std.int(tab_width) * rows);
			if (tot_size < W)
				diff_size = (W - tot_size);
		}

		if (maxRows > 0)
			yy = -TAB_HEIGHT * (rows % maxRows);

		_tabs.sort(sortTabs);

		var i:Int = 0;
		var firstHeight:Float = 0;

		var tab:FlxUITypedButton<FlxSprite>;
		for (t in _tabs)
		{
			tab = cast t;

			tab.x = x + xx;
			tab.y = y + yy;

			if (_tab_offset != null)
			{
				tab.x += _tab_offset.x;
				tab.y += _tab_offset.y;
			}

			if (_stretch_tabs)
			{
				var theWidth = tab_width;
				if (maxRows > 0 && i >= maxRows * Math.floor(_tabs.length / maxRows))
					theWidth = last_tab_width;
				var theHeight:Float = tab.height;
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
					tab.resize(theWidth + 1, theHeight);
					xx += (Std.int(theWidth) + 1);
					diff_size -= 1;
				}
				else
				{
					tab.resize(theWidth, theHeight);
					xx += Std.int(theWidth);
				}
			}
			else
			{
				if (_tab_spacing != null)
					xx += tab.width + _tab_spacing;
				else
					xx += tab.width;
			}
			if (i == 0)
				firstHeight = tab.get_height(); // if we are stretching we will make everything match the height of the first tab
			i++;
			if (maxRows > 0 && i % maxRows == 0)
			{
				xx = 0;
				yy += TAB_HEIGHT;
			}
		}

		if (_tabs != null && _tabs.length > 0 && _tabs[_tabs.length - 1] != null)
		{
			_back.y = _tabs[_tabs.length - 1].y + _tabs[_tabs.length - 1].height - 2;
			if (_tab_offset != null)
				_back.y -= _tab_offset.y;
		}

		calcBounds();
	}

	public function createTab(name:String)
	{
		var tab = new FlxUI(null, this);
		tab.name = name;
		return tab;
	}

	function getTabsHeight():Float
	{
		if (numTabs == 0)
			return 0;
		else if (maxRows > 0)
			return TAB_HEIGHT + (TAB_HEIGHT * Math.floor((numTabs - 1) / maxRows));
		else
			return TAB_HEIGHT;
	}
}
