package util;

import Sys.sleep;

using StringTools;

#if discord_rpc
import discord_rpc.DiscordRpc;
#end

class DiscordClient
{
	static var changedPresence:Bool = false;
	
	public function new()
	{
		#if discord_rpc
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "1108176564488773673",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");
		
		while (true)
		{
			DiscordRpc.process();
			sleep(2);
		}
		
		DiscordRpc.shutdown();
		#end
	}
	
	public static function shutdown()
	{
		#if discord_rpc
		DiscordRpc.shutdown();
		#end
	}
	
	public static function initialize()
	{
		#if discord_rpc
		sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		trace("Discord Client initialized");
		#end
	}
	
	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
	{
		#if discord_rpc
		var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;
		
		if (endTimestamp > 0)
			endTimestamp = startTimestamp + endTimestamp;
			
		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'icon',
			largeImageText: "Friday Night Funkin' PvP",
			smallImageKey: smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp: Std.int(startTimestamp / 1000),
			endTimestamp: Std.int(endTimestamp / 1000)
		});
		
		changedPresence = true;
		#end
	}
	
	#if discord_rpc
	static function onReady()
	{
		if (!changedPresence)
			changePresence(null, "Starting Up");
	}
	
	static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}
	
	static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}
	#end
}
