package data;

import haxe.io.Path;
import haxe.xml.Access;
import sprites.AnimatedSprite.AnimData;
import sprites.DancingSprite;
import sprites.game.Character;
import states.PlayState;

using StringTools;

class StageFile
{
	public var sprites:Map<String, DancingSprite> = new Map();

	var state:PlayState;

	public function new(state:PlayState, stage:String)
	{
		this.state = state;

		var nameInfo = CoolUtil.getNameInfo(stage);
		var mod = nameInfo.mod;
		var path = Paths.getPath('data/stages/' + nameInfo.name + '.xml', mod);
		if (!Paths.exists(path))
		{
			addMissingChars();
			return;
		}

		var xml = new Access(Xml.parse(Paths.getContent(path)).firstElement());
		if (xml.has.zoom)
		{
			var zoom = Std.parseFloat(xml.att.zoom);
			if (!Math.isNaN(zoom))
				state.defaultCamZoom = zoom;
		}
		var folder = '';
		if (xml.has.folder)
		{
			folder = Path.normalize(xml.att.folder);
			if (!folder.endsWith('/'))
				folder += '/';
		}

		var elements:Array<Access> = [];
		for (node in xml.elements)
			pushNode(node, elements);

		for (node in elements)
		{
			var spr = switch (node.name)
			{
				case "sprite", "spr":
					if (!node.has.name)
						continue;
					var spr = createSprite(node, folder, mod);
					state.add(spr);
					spr;
				case "boyfriend", "bf":
					var char = setupChar(state.bf, node);
					state.add(char);
					char;
				case "opponent", "dad":
					var char = setupChar(state.opponent, node);
					state.add(char);
					char;
				case "girlfriend", "gf":
					var char = setupChar(state.gf, node);
					state.add(char);
					char;
				default: null;
			}
			if (spr != null)
			{
				for (n in node.nodes.property)
					applyProperty(spr, n, node.att.name);
			}
		}

		addMissingChars();
	}

	function createSprite(node:Access, folder:String, mod:String)
	{
		var spr = new DancingSprite();
		spr.antialiasing = true;
		if (node.has.image)
		{
			var image = folder + node.att.image;
			var path = Paths.getPath('images/' + image + '.png', mod);
			if (Paths.exists(path))
			{
				var s = path.substr(0, path.length - 4);
				if (Paths.isSpritesheet(s, mod))
					spr.frames = Paths.getSpritesheet(s, mod);
				else
				{
					var graphic = Paths.getImage(path, mod);
					if (node.has.tileWidth)
					{
						var tileWidth = Std.parseInt(node.att.tileWidth);
						var tileHeight = node.has.tileHeight ? Std.parseInt(node.att.tileHeight) : tileWidth;
						spr.loadGraphic(graphic, true, tileWidth, tileHeight);
					}
					else
					{
						spr.loadGraphic(graphic);
						spr.active = false;
					}
				}
				for (anim in node.nodes.anim)
				{
					if (!anim.has.name)
						continue;

					var animData:AnimData = {name: anim.att.name, indices: [], offset: []};
					if (anim.has.atlasName)
						animData.atlasName = anim.att.atlasName;
					if (anim.has.indices)
					{
						animData.indices = [];
						var indices = anim.att.indices.split(',');
						for (i in indices)
						{
							if (i.length > 0)
							{
								var n = Std.parseInt(i);
								if (n != null && n >= 0)
									animData.indices.push(n);
							}
						}
					}
					if (anim.has.fps)
					{
						var fps = Std.parseFloat(anim.att.fps);
						if (!Math.isNaN(fps))
							animData.fps = fps;
					}
					if (anim.has.loop)
						animData.loop = anim.att.loop == "true";
					if (anim.has.flipX)
						animData.flipX = anim.att.flipX == "true";
					if (anim.has.flipY)
						animData.flipY = anim.att.flipY == "true";
					if (anim.has.x)
					{
						var x = Std.parseFloat(anim.att.x);
						if (!Math.isNaN(x))
							animData.offset[0] = x;
					}
					if (anim.has.y)
					{
						var y = Std.parseFloat(anim.att.y);
						if (!Math.isNaN(y))
							animData.offset[1] = y;
					}
					var baseAnim = false;
					if (anim.has.baseAnim)
						baseAnim = anim.att.baseAnim == "true";

					spr.addAnim(animData, baseAnim);
				}
			}
		}
		if (node.has.x)
		{
			var x = Std.parseFloat(node.att.x);
			if (!Math.isNaN(x))
				spr.x = x;
		}
		if (node.has.y)
		{
			var y = Std.parseFloat(node.att.y);
			if (!Math.isNaN(y))
				spr.y = y;
		}
		if (node.has.scroll)
		{
			var scroll = Std.parseFloat(node.att.scroll);
			if (!Math.isNaN(scroll))
				spr.scrollFactor.set(scroll, scroll);
		}
		else
		{
			if (node.has.scrollX)
			{
				var scrollX = Std.parseFloat(node.att.scrollX);
				if (!Math.isNaN(scrollX))
					spr.scrollFactor.x = scrollX;
			}
			if (node.has.scrollY)
			{
				var scrollY = Std.parseFloat(node.att.scrollY);
				if (!Math.isNaN(scrollY))
					spr.scrollFactor.y = scrollY;
			}
		}
		if (node.has.scale)
		{
			var scale = Std.parseFloat(node.att.scale);
			if (!Math.isNaN(scale))
				spr.scale.set(scale, scale);
		}
		else
		{
			if (node.has.scaleX)
			{
				var scaleX = Std.parseFloat(node.att.scaleX);
				if (!Math.isNaN(scaleX))
					spr.scale.x = scaleX;
			}
			if (node.has.scaleY)
			{
				var scaleY = Std.parseFloat(node.att.scaleY);
				if (!Math.isNaN(scaleY))
					spr.scale.y = scaleY;
			}
		}
		if (node.has.antialiasing)
			spr.antialiasing = node.att.antialiasing == "true";
		var updateHitbox = true;
		if (node.has.updateHitbox)
			updateHitbox = node.att.updateHitbox == "true";
		if (updateHitbox)
			spr.updateHitbox();
		sprites.set(node.att.name, spr);
		return spr;
	}

	function setupChar(char:Character, node:Access)
	{
		if (node != null)
		{
			if (node.has.x)
			{
				var x = Std.parseFloat(node.att.x);
				if (!Math.isNaN(x))
					char.charPosX = x;
			}
			if (node.has.y)
			{
				var y = Std.parseFloat(node.att.y);
				if (!Math.isNaN(y))
					char.charPosY = y;
			}
			if (node.has.flip)
				char.charFlipX = node.att.flip == 'true';
			if (node.has.scroll)
			{
				var scroll = Std.parseFloat(node.att.scroll);
				if (!Math.isNaN(scroll))
					char.scrollFactor.set(scroll, scroll);
			}
			else
			{
				if (node.has.scrollX)
				{
					var scrollX = Std.parseFloat(node.att.scrollX);
					if (!Math.isNaN(scrollX))
						char.scrollFactor.x = scrollX;
				}
				if (node.has.scrollY)
				{
					var scrollY = Std.parseFloat(node.att.scrollY);
					if (!Math.isNaN(scrollY))
						char.scrollFactor.y = scrollY;
				}
			}
		}
		return char;
	}

	function addMissingChars()
	{
		var chars = [state.gf, state.opponent, state.bf];
		for (char in chars)
		{
			if (!state.members.contains(char))
				state.add(char);
		}
	}

	function pushNode(node:Access, elements:Array<Access>)
	{
		if (node.name == 'high-quality')
		{
			if (!Settings.lowQuality)
			{
				for (e in node.elements)
					pushNode(e, elements);
			}
		}
		else if (node.name == 'low-quality')
		{
			if (Settings.lowQuality)
			{
				for (e in node.elements)
					pushNode(e, elements);
			}
		}
		else if (node.name == 'distractions')
		{
			if (Settings.distractions)
			{
				for (e in node.elements)
					pushNode(e, elements);
			}
		}
		else if (node.name == 'no-distractions')
		{
			if (!Settings.distractions)
			{
				for (e in node.elements)
					pushNode(e, elements);
			}
		}
		else
			elements.push(node);
	}

	function applyProperty(spr:Dynamic, node:Access, name:String)
	{
		if (!node.has.name || !node.has.type || !node.has.value)
			return;

		var split = node.att.name.split('.');
		// i have to mark this as dynamic for some reason?
		// haxe stop being weird
		var object:Dynamic = spr;
		while (split.length > 1)
		{
			var name = split.shift();
			if (name.contains('['))
			{
				var p = name.substr(0, name.indexOf('['));
				object = Reflect.getProperty(object, name);
				var array:Array<Dynamic> = object;
				while (name.contains('['))
				{
					var index = name.indexOf('[');
					var lastIndex = name.indexOf(']');
					var num = name.substr(index + 1, lastIndex - index - 1);
					if (num.length > 0)
					{
						var n = Std.parseInt(num);
						if (n >= 0)
						{
							object = array[n];
							if (name.contains('['))
								array = object;
						}
						else
							break;
					}
					else
						break;
				}
			}
			else
				object = Reflect.getProperty(object, name);
		}
		if (object != null)
		{
			var value:Dynamic = switch (node.att.type)
			{
				case "float", "number", "f": Std.parseFloat(node.att.value);
				case "integer", "int", "i": Std.parseInt(node.att.value);
				case "string", "str", "text", "s": node.att.value;
				case "boolean", "bool", "b": node.att.value == "true";
				default: null;
			}
			if (value == null)
				return;

			try
			{
				Reflect.setProperty(object, split[0], value);
			}
			catch (e)
			{
				state.notificationManager.showNotification("Failed to apply XML property: " + e, ERROR);
			}
		}
	}
}
