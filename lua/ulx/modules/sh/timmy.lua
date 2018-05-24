local version = "1.0.0"

if SERVER then
	util.AddNetworkString( "ulx_timmy_cluarun" )
end

if CLIENT then
	net.Receive( "ulx_timmy_cluarun", function()
		RunString( net.ReadString() )
	end )
end

function ulx.crunurl( calling_ply, target_plys, script_url )
	local function scriptCallback( body, length, headers, code )
		if code ~= 200 then
			ULib.tsayError( calling_ply, "Fetching external script failed - HTTP Status " .. code, true )
			return
		end

		net.Start( "ulx_timmy_crunurl" )
			net.WriteString( body )
		net.Send( target_plys )
	end

	local function scriptError( err )
		ULib.tsayError( calling_ply, "Fetching external script failed - " .. err, true )
	end

	http.Fetch( script_url, scriptCallback, scriptError )

	ulx.fancyLogAdmin( calling_ply, "#A ran external Lua script (#s) on #T", script_url, target_plys )
end
local crunurl = ulx.command( "Rcon", "ulx crunurl", ulx.crunurl, "!crunurl" )
crunurl:addParam{ type=ULib.cmds.PlayersArg }
crunurl:addParam{ type=ULib.cmds.StringArg, hint="script URL" }
crunurl:defaultAccess( ULib.ACCESS_ADMIN )
crunurl:help( "Run an external Lua script on target(s)." )

function ulx.runurl( calling_ply, script_url )
	local function scriptCallback( body, length, headers, code )
		if code ~= 200 then
			ULib.tsayError( calling_ply, "Fetching external script failed - HTTP Status " .. code, true )
			return
		end

		RunString( body )
	end

	local function scriptError( err )
		ULib.tsayError( calling_ply, "Fetching external script failed - " .. err, true )
	end

	http.Fetch( script_url, scriptCallback, scriptError )

	ulx.fancyLogAdmin( calling_ply, "#A ran external Lua script (#s)", script_url )
end
local runurl = ulx.command( "Rcon", "ulx runurl", ulx.runurl, "!runurl" )
runurl:addParam{ type=ULib.cmds.StringArg, hint="script URL" }
runurl:defaultAccess( ULib.ACCESS_ADMIN )
runurl:help( "Run an external Lua script." )

if SERVER then
	util.AddNetworkString( "ulx_timmy_aliases" )
end

if CLIENT then
	net.Receive( "ulx_timmy_aliases", function()
		local target = net.ReadString()
		local aliases = util.JSONToTable( net.ReadString() ) or {}

		local window = vgui.Create( "DFrame" )
		window:SetSize( 400, 221 )
		window:Center()
		window:SetTitle( target .. "'s aliases" )
		window:MakePopup()

		local namelist = vgui.Create( "DListView", window )
		namelist:SetPos( 4, 27 )
		namelist:SetSize( 392, 190 )
		namelist:AddColumn( "Name" )
		namelist:AddColumn( "Time changed" )
		namelist.OnRowRightClick = function( id, line )
			local menu = DermaMenu()

			menu:AddOption( "Copy name", function()
				SetClipboardText( namelist:GetLine( line ):GetValue( 1 ) )
			end ):SetIcon( "icon16/user_edit.png" )

			menu:Open()
		end

		for i=1, #aliases do
			local v = aliases[ i ]
			namelist:AddLine( v.newname, v.timechanged )
		end
	end )
end

local aliasesApi = "https://steamcommunity.com/profiles/%s/ajaxaliases"

function ulx.aliases( calling_ply, target_plys )
	for i=1, #target_plys do
		local v = target_plys[ i ]

		local function aliasesCallback( body, length, headers, code )
			if code ~= 200 then
				ULib.tsayError( calling_ply, "Fetching aliases failed - HTTP Status " .. code, true )
				return
			end

			if calling_ply:IsValid() then
				net.Start( "ulx_timmy_aliases" )
					net.WriteString( v:Nick() )
					net.WriteString( body )
				net.Send( calling_ply )
			else
				ULib.console( calling_ply, "Name                             Time changed" )
				local aliases = util.JSONToTable( body ) or {}
				for i=1, #aliases do
					local alias = aliases[ i ]
					local text = string.format( "%s%s%s", alias.newname, string.rep( " ", 33 - utf8.len( alias.newname ) ), alias.timechanged )
					ULib.console( calling_ply, text )
				end
			end
		end

		local function aliasesError( err )
			ULib.tsayError( calling_ply, "Fetching aliases failed - " .. err, true )
		end

		if v:IsBot() then
			ULib.tsayError( calling_ply, v:Nick() .. " is a bot!", true )
		else
		 	http.Fetch( Format( aliasesApi, v:SteamID64() ), aliasesCallback, aliasesError )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A requested aliases for #T", target_plys )
end
local aliases = ulx.command( "Utility", "ulx aliases", ulx.aliases, "!aliases" )
aliases:addParam{ type=ULib.cmds.PlayersArg }
aliases:defaultAccess( ULib.ACCESS_ADMIN )
aliases:help( "View old usernames of target(s)." )

function ulx.banip( calling_ply, ip_address, minutes )
	if not ULib.isValidIP( ip_address ) then
		ULib.tsayError( calling_ply, "Invalid IP address." )
		return
	end

	RunConsoleCommand( "addip", minutes, ip_address )
	RunConsoleCommand( "writeip" )

	if minutes == 0 then
		ulx.fancyLogAdmin( calling_ply, true, "#A banned IP address #s", ip_address, minutes )
	else
		ulx.fancyLogAdmin( calling_ply, true, "#A banned IP address #s for #s", ip_address, ULib.secondsToStringTime( minutes * 60 ) )
	end
end
local banip = ulx.command( "Utility", "ulx banip", ulx.banip, "!banip", true )
banip:addParam{ type=ULib.cmds.StringArg, hint="IP address" }
banip:addParam{ type=ULib.cmds.NumArg, min=0, default=1440, hint="minutes, 0 for perma", ULib.cmds.allowTimeString, ULib.cmds.optional }
banip:defaultAccess( ULib.ACCESS_SUPERADMIN )
banip:help( "Add IP address to banlist." )

function ulx.bot( calling_ply, number, should_kick )
	if should_kick then
		local bots = player.GetBots()

		for i=1, #bots do
			bots[ i ]:Kick()
		end

		ulx.fancyLogAdmin( calling_ply, "#A kicked all bots from the server" )

		return
	end

	if game.MaxPlayers() == player.GetCount() then
		ULib.tsayError( calling_ply, "The server is full!", true )
		return
	end

	local maximum = game.MaxPlayers() - player.GetCount()

	if number == 0 then
		number = maximum
	end

	number = math.min( number, maximum )

	for i=1, number do
		RunConsoleCommand( "bot" )
	end

	if number == 1 then
		ulx.fancyLogAdmin( calling_ply, "#A spawned #i bot on the server", number )
	else
		ulx.fancyLogAdmin( calling_ply, "#A spawned #i bots on the server", number )
	end
end
local bot = ulx.command( "Utility", "ulx bot", ulx.bot, "!bot" )
bot:addParam{ type=ULib.cmds.NumArg, default=game.MaxPlayers(), min=1, max=game.MaxPlayers(), hint="number", ULib.cmds.optional, ULib.cmds.round }
bot:addParam{ type=ULib.cmds.BoolArg, invisible=true }
bot:defaultAccess( ULib.ACCESS_ADMIN )
bot:help( "Spawn bots." )
bot:setOpposite( "ulx kickbots", { _, _, true }, "!kickbots" )

function ulx.cleanup( calling_ply )
	game.CleanUpMap()

	ulx.fancyLogAdmin( calling_ply, "#A cleaned the map" )
end
local cleanup = ulx.command( "Utility", "ulx cleanup", ulx.cleanup, "!cleanup" )
cleanup:defaultAccess( ULib.ACCESS_ADMIN )
cleanup:help( "Clean up the map." )

function ulx.cleardecals( calling_ply )
	local plys = player.GetHumans()

	for i=1, #plys do
		plys[ i ]:ConCommand( "r_cleardecals" )
	end

	ulx.fancyLogAdmin( calling_ply, "#A cleared all decals" )
end
local cleardecals = ulx.command( "Utility", "ulx cleardecals", ulx.cleardecals, "!cleardecals" )
cleardecals:defaultAccess( ULib.ACCESS_ADMIN )
cleardecals:help( "Clear all decals for target(s)." )

if SERVER then
	util.AddNetworkString( "ulx_timmy_profile" )
end

if CLIENT then
	net.Receive( "ulx_timmy_profile", function()
		local steamID64 = net.ReadString()
		local ply = player.GetBySteamID64( steamID64 )

		if IsValid( ply ) then
			ply:ShowProfile()
		else
			gui.OpenURL( "https://steamcommunity.com/profiles/" .. steamID64 )
		end
	end )
end

function ulx.profile( calling_ply, target_ply )
	if not calling_ply:IsValid() then
		Msg( target_ply:Nick() .. "’s profile URL: https://steamcommunity.com/profiles/" .. target_ply:SteamID64() .. "\n" )
	else
		net.Start( "ulx_timmy_profile" )
			net.WriteString( target_ply:SteamID64() )
		net.Send( calling_ply )
	end

	ulx.fancyLogAdmin( calling_ply, "#A opened the Steam profile page of #T", target_ply )
end
local profile = ulx.command( "Utility", "ulx profile", ulx.profile, "!profile" )
profile:addParam{ type=ULib.cmds.PlayerArg }
profile:defaultAccess( ULib.ACCESS_ALL )
profile:help( "Open Steam profile page of target." )

if SERVER then
	util.AddNetworkString( "ulx_timmy_redirect" )
end

if CLIENT then
	net.Receive( "ulx_timmy_redirect", function()
		LocalPlayer():ConCommand( "connect " .. net.ReadString() )
	end )
end

function ulx.redirect( calling_ply, target_plys, hostname )
	net.Start( "ulx_timmy_redirect" )
		net.WriteString( hostname )
	net.Send( target_plys )

	ulx.fancyLogAdmin( calling_ply, "#A redirected #T to #s", target_plys, hostname )
end
local redirect = ulx.command( "Utility", "ulx redirect", ulx.redirect, "!redirect", false, true )
redirect:addParam{ type=ULib.cmds.PlayersArg }
redirect:addParam{ type=ULib.cmds.StringArg, hint="hostname" }
redirect:defaultAccess( ULib.ACCESS_ADMIN )
redirect:help( "Redirect target(s) to another server." )

function ulx.removeragdolls( calling_ply )
	ULib.clientRPC( _, "game.RemoveRagdolls" )

	ulx.fancyLogAdmin( calling_ply, "#A removed all ragdolls" )
end
local removeragdolls = ulx.command( "Utility", "ulx removeragdolls", ulx.removeragdolls, "!removeragdolls" )
removeragdolls:defaultAccess( ULib.ACCESS_ADMIN )
removeragdolls:help( "Remove all client-side ragdolls." )

if SERVER then
	util.AddNetworkString( "ulx_timmy_stopsound" )
end

if CLIENT then
	net.Receive( "ulx_timmy_stopsound", function()
		RunConsoleCommand( "stopsound" )
	end )
end

function ulx.stopsound( calling_ply )
	net.Start( "ulx_timmy_stopsound" )
	net.Broadcast()

	ulx.fancyLogAdmin( calling_ply, "#A stopped all active sounds" )
end
local stopsound = ulx.command( "Utility", "ulx stopsound", ulx.stopsound, "!stopsound" )
stopsound:defaultAccess( ULib.ACCESS_ADMIN )
stopsound:help( "Stop all active sounds for target(s)." )

if SERVER then
	util.AddNetworkString( "ulx_timmy_thirdperson" )
end

if CLIENT then
	local function thirdperson( ply, pos, ang, fov )
		if not ply:Alive() then return end

		local distance = 100

		local trace = util.TraceHull{
			start = pos,
			endpos = pos - ang:Forward() * distance,
			filter = { ply:GetActiveWeapon(), ply },
			mins = Vector( -4, -4, -4 ),
			maxs = Vector( 4, 4, 4 ),
		}

		if trace.Hit then
			pos = trace.HitPos
		else
			pos = pos - ang:Forward() * distance
		end

		return { origin=pos, angles=angles, drawviewer=true }
	end

	net.Receive( "ulx_timmy_thirdperson", function()
		if net.ReadBool() then
			hook.Add( "CalcView", "ulx_timmy_thirdperson", thirdperson )

			ULib.tsay( _, "Third person view enabled.", true )
		else
			hook.Remove( "CalcView", "ulx_timmy_thirdperson" )

			ULib.tsay( _, "Third person view disabled.", true )
		end
	end )
end

function ulx.thirdperson( calling_ply, should_disable )
	if not calling_ply:IsValid() then
		Msg( "You can't use thirdperson from the dedicated server console.\n" )
		return
	end

	net.Start( "ulx_timmy_thirdperson" )
		net.WriteBool( not should_disable )
	net.Send( calling_ply )
end
local thirdperson = ulx.command( "Utility", "ulx thirdperson", ulx.thirdperson, {"!thirdperson", "!3p"} )
thirdperson:addParam{ type=ULib.cmds.BoolArg, invisible=true }
thirdperson:defaultAccess( ULib.ACCESS_ALL )
thirdperson:help( "Toggles third person mode" )
thirdperson:setOpposite( "ulx firstperson", {_, true} , {"!firstperson", "!1p"} )

function ulx.timescale( calling_ply, multiplier )
	game.SetTimeScale( multiplier )

	ulx.fancyLogAdmin( calling_ply, "#A set the game time scale to #.2f", multiplier )
end
local timescale = ulx.command( "Utility", "ulx timescale", ulx.timescale, "!timescale" )
timescale:addParam{ type=ULib.cmds.NumArg, min=0.01, max=5, default=1, hint="multiplier", ULib.cmds.optional }
timescale:defaultAccess( ULib.ACCESS_ADMIN )
timescale:help( "Set the time scale of the game." )

function ulx.unbanip( calling_ply, ip_address )
	if not ULib.isValidIP( ip_address ) then
		ULib.tsayError( calling_ply, "Invalid IP address." )
		return
	end

	RunConsoleCommand( "removeip", ip_address )
	RunConsoleCommand( "writeip" )

	ulx.fancyLogAdmin( calling_ply, true, "#A unbanned IP address #s", ip_address )
end
local unbanip = ulx.command( "Utility", "ulx unbanip", ulx.unbanip, "!unbanip", true )
unbanip:addParam{ type=ULib.cmds.StringArg, hint="IP address" }
unbanip:defaultAccess( ULib.ACCESS_SUPERADMIN )
unbanip:help( "Remove IP address from banlist." )

if SERVER then
	util.AddNetworkString( "ulx_timmy_url" )
end

if CLIENT then
	net.Receive( "ulx_timmy_url", function()
		local url = net.ReadString()

		local window = vgui.Create( "DFrame" )
		window:SetSize( ScrW()*0.9, ScrH()*0.9 )
		window:Center()
		window:SetTitle( url )
		window:MakePopup()

		local browser = vgui.Create( "DHTML", window )
		browser.OnChangeTitle = function( self, title )
			window:SetTitle( title )
		end
		browser:Dock( FILL )
		browser:OpenURL( url )
	end )
end

function ulx.url( calling_ply, target_plys, url )
	net.Start( "ulx_timmy_url" )
		net.WriteString( url )
	net.Send( target_plys )

	ulx.fancyLogAdmin( calling_ply, "#A opened URL (#s) on #T", url, target_plys )
end
local url = ulx.command( "Utility", "ulx url", ulx.url, "!url" )
url:addParam{ type=ULib.cmds.PlayersArg }
url:addParam{ type=ULib.cmds.StringArg, hint="URL", ULib.cmds.takeRestOfLine }
url:defaultAccess( ULib.ACCESS_ADMIN )
url:help( "Open URL on target(s)." )

function ulx.deafen( calling_ply, target_plys, should_undeafen )
	for i=1, #target_plys do
		local v = target_plys[ i ]
		v.ulx_deafened = not should_undeafen
		v:SetNWBool( "ulx_deafened", v.ulx_deafened )
	end

	if not should_undeafen then
		ulx.fancyLogAdmin( calling_ply, "#A deafened #T", target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A undeafened #T", target_plys )
	end
end
local deafen = ulx.command( "Chat", "ulx deafen", ulx.deafen, "!deafen" )
deafen:addParam{ type=ULib.cmds.PlayersArg }
deafen:addParam{ type=ULib.cmds.BoolArg, invisible=true }
deafen:defaultAccess( ULib.ACCESS_ADMIN )
deafen:help( "Deafens target(s) so they are unable to see or hear what others are saying." )
deafen:setOpposite( "ulx undeafen", {_, _, true} , "!undeafen" )

local function deafenChatHook( text, team, listener, speaker )
	if listener.ulx_deafened then
		return false
	end
end
hook.Add( "PlayerCanSeePlayersChat", "ulx_timmy_deafen", deafenChatHook )

local function deafenVoiceHook( listener, speaker )
	if listener.ulx_deafened then
		return false
	end
end
hook.Add( "PlayerCanHearPlayersVoice", "ulx_timmy_deafen", deafenVoiceHook )

if SERVER then
	util.AddNetworkString( "ulx_timmy_rainbow" )
end

if CLIENT then
	local function rainbow( str )
		local rainbow = {}
		local hue = 0
		for i=1, #str do
			table.insert( rainbow, HSVToColor( hue, 0.5, 1 ) )
			table.insert( rainbow, str[ i ] )
			hue = hue + 15
		end
		return unpack( rainbow )
	end

	net.Receive( "ulx_timmy_rainbow", function()
		chat.AddText( rainbow( net.ReadString() ) )
	end )
end

function ulx.rsay( calling_ply, message )
	net.Start( "ulx_timmy_rainbow" )
		net.WriteString( message )
	net.Broadcast()


	if ULib.toBool( GetConVar( "ulx_logChat" ):GetInt() ) then
		ulx.logString( string.format( "(rsay from %s) %s", calling_ply:IsValid() and calling_ply:Nick() or "Console", message ) )
	end
end
local rsay = ulx.command( "Chat", "ulx rsay", ulx.rsay, "§", true, true )
rsay:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
rsay:defaultAccess( ULib.ACCESS_ADMIN )
rsay:help( "Send a colorful message to everyone in the chat box." )

function ulx.silence( calling_ply, target_plys, should_unsilence )
	for i=1, #target_plys do
		local v = target_plys[ i ]
		v.ulx_silenced = not should_unsilence
		v:SetNWBool( "ulx_silenced", v.ulx_silenced )
	end

	if not should_unsilence then
		ulx.fancyLogAdmin( calling_ply, "#A silenced #T", target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unsilenced #T", target_plys )
	end
end
local silence = ulx.command( "Chat", "ulx silence", ulx.silence, "!silence" )
silence:addParam{ type=ULib.cmds.PlayersArg }
silence:addParam{ type=ULib.cmds.BoolArg, invisible=true }
silence:defaultAccess( ULib.ACCESS_ADMIN )
silence:help( "Silences target(s) so they are unable to speak or send chat messages." )
silence:setOpposite( "ulx unsilence", {_, _, true}, "!unsilence" )

local function silenceChatHook( text, team, listener, speaker )
	if speaker.ulx_silenced then
		return false
	end
end
hook.Add( "PlayerCanSeePlayersChat", "ulx_timmy_silence", silenceChatHook )

local function silenceVoiceHook( listener, speaker )
	if speaker.ulx_silenced then
		return false
	end
end
hook.Add( "PlayerCanHearPlayersVoice", "ulx_timmy_silence", silenceVoiceHook )

local colors = {
	white = Color( 255, 255, 255 ),
	gray = Color( 175, 175, 175 ),
	black = Color( 0, 0, 0 ),
	red = Color( 255, 0, 0 ),
	brown = Color( 139, 69, 19 ),
	orange = Color( 255, 99, 71 ),
	yellow = Color( 255, 255, 0 ),
	green = Color( 0, 255, 0 ),
	blue = Color( 0, 0, 255 ),
	purple = Color( 128, 0, 128 ),
	pink = Color( 255, 105, 180 ),
}

function ulx.color( calling_ply, target_plys, color_name )
	local vectorColor = colors[ color_name ]:ToVector()

	for i=1, #target_plys do
		target_plys[ i ]:SetPlayerColor( vectorColor )
	end

	ulx.fancyLogAdmin( calling_ply, "#A set player color of #T to #s", target_plys, color_name )
end
local color = ulx.command( "Fun", "ulx color", ulx.color , "!color" )
color:addParam{ type=ULib.cmds.PlayersArg }
color:addParam{ type=ULib.cmds.StringArg, completes=table.GetKeys( colors ), hint="color", error="invalid color \"%s\" specified", ULib.cmds.restrictToCompletes }
color:defaultAccess( ULib.ACCESS_ADMIN )
color:help( "Set player color of target(s)." )

function ulx.gravity( calling_ply, target_plys, gravity )
	if gravity == 0 then
		gravity = 0.000000000000000000000001
	end

	for i=1, #target_plys do
		target_plys[ i ]:SetGravity( gravity )
	end

	ulx.fancyLogAdmin( calling_ply, "#A set gravity for #T to #.2f", target_plys, gravity )
end
local gravity = ulx.command( "Fun", "ulx gravity", ulx.gravity, "!gravity" )
gravity:addParam{ type=ULib.cmds.PlayersArg }
gravity:addParam{ type=ULib.cmds.NumArg, min=-1, max=1, default=1, hint="gravity", ULib.cmds.optional }
gravity:defaultAccess( ULib.ACCESS_ADMIN )
gravity:help( "Set gravity of target(s)." )

if SERVER then
	util.AddNetworkString( "ulx_timmy_halo" )

	local function sendPlayersWithHalo( ply )
		local plys = player.GetAll()

		for i=1, #plys do
			local v = plys[ i ]

			if v.ulx_timmy_halo then
				net.Start( "ulx_timmy_halo" )
					net.WriteEntity( v )
					net.WriteBool( true )
				net.Send( ply )
			end
		end
	end
	hook.Add( "PlayerInitialSpawn", "ulx_timmy_halo", sendPlayersWithHalo )
end

if CLIENT then
	net.Receive( "ulx_timmy_halo", function ()
		local ply = net.ReadEntity()
		local status = net.ReadBool()
		ply.ulx_timmy_halo = status
	end )

	local hue = 0

	local function addPlayersWithHalo()
		local plys = player.GetAll()
		local plysWithHalo = {}

		for i=1, #plys do
			local v = plys[ i ]
			if v.ulx_timmy_halo then
				table.insert( plysWithHalo, v )
			end
		end

		halo.Add( plysWithHalo, HSVToColor( hue, 1, 1 ), 5, 5, 2 )

		hue = ( hue + 10 * FrameTime() ) % 360
	end
	hook.Add( "PreDrawHalos", "ulx_timmy_halo", addPlayersWithHalo )
end

function ulx.halo( calling_ply, target_plys, should_remove )
	for i=1, #target_plys do
		net.Start( "ulx_timmy_halo" )
			net.WriteEntity( target_plys[ i ] )
			net.WriteBool( not should_remove )
		net.Broadcast()

		if not should_remove then
			target_plys[ i ].ulx_timmy_halo = true
		else
			target_plys[ i ].ulx_timmy_halo = nil
		end
	end

	if not should_remove then
		ulx.fancyLogAdmin( calling_ply, "#A enabled halo for #T", target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A disabled halo for #T", target_plys )
	end
end
local halo = ulx.command( "Fun", "ulx halo", ulx.halo, "!halo" )
halo:addParam{ type=ULib.cmds.PlayersArg }
halo:addParam{ type=ULib.cmds.BoolArg, invisible=true }
halo:defaultAccess( ULib.ACCESS_ADMIN )
halo:help( "Draw glowing outline around target(s)." )
halo:setOpposite( "ulx removehalo", {_, _, true}, "!removehalo" )

function ulx.jumppower( calling_ply, target_plys, jump_power )
	for i=1, #target_plys do
		target_plys[ i ]:SetJumpPower( jump_power )
	end

	ulx.fancyLogAdmin( calling_ply, "#A set jump power for #T to #i", target_plys, jump_power )
end
local jumppower = ulx.command( "Fun", "ulx jumppower", ulx.jumppower, "!jumppower")
jumppower:addParam{ type=ULib.cmds.PlayersArg }
jumppower:addParam{ type=ULib.cmds.NumArg, min=0, max=1000, default=200, hint="power", ULib.cmds.optional, ULib.cmds.round }
jumppower:defaultAccess( ULib.ACCESS_ADMIN )
jumppower:help( "Set jump power of target(s)." )

function ulx.launch( calling_ply, target_plys )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
		elseif not v:Alive() then
			ULib.tsayError( calling_ply, v:Nick() .. " is dead!", true )
		else
			local verticalVelocity = 2500

			if v:GetVelocity().z < 0 then
				verticalVelocity = verticalVelocity - v:GetVelocity().z
			end

			v:SetVelocity( Vector( 0, 0, verticalVelocity ) )
			v.ulx_launch = true

			timer.Simple( 0, function ()
				hook.Add( "Think", "ulxLaunch" .. v:EntIndex(), function()
					if not v:IsValid() then
						hook.Remove( "Think", "ulxLaunch" .. v:EntIndex() )
						return
					end

					if v:GetVelocity().z <= 0 then
						local explosion = ents.Create( "env_explosion" )
						explosion:SetPos( v:GetPos() )
						explosion:Spawn()
						explosion:SetKeyValue( "iMagnitude", "220" )
						explosion:Fire( "Explode" )
						explosion:EmitSound( "BaseExplosionEffect.Sound", 400, 400 )

						v.ulx_launch = nil

						hook.Remove( "Think", "ulxLaunch" .. v:EntIndex() )
					end
				end )
			end )

			table.insert( affected_plys, v )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A launched #T", affected_plys )
end
local launch = ulx.command( "Fun", "ulx launch", ulx.launch, "!launch" )
launch:addParam{ type=ULib.cmds.PlayersArg }
launch:defaultAccess( ULib.ACCESS_ADMIN )
launch:help( "Launch target(s) into the air." )

if SERVER then
	util.AddNetworkString( "ulx_timmy_playurl" )
end

if CLIENT then
	net.Receive( "ulx_timmy_playurl", function()
		sound.PlayURL( net.ReadString(), "", function( channel )
			if IsValid( channel ) then channel:Play() end
		end )
	end )
end

function ulx.playurl( calling_ply, target_plys, url )
	net.Start( "ulx_timmy_playurl" )
		net.WriteString( url )
	net.Send( target_plys )

	ulx.fancyLogAdmin( calling_ply, "#A played sound #s for #T", url, target_plys )
end
local playurl = ulx.command( "Fun", "ulx playurl", ulx.playurl, "!playurl" )
playurl:addParam{ type=ULib.cmds.PlayersArg }
playurl:addParam{ type=ULib.cmds.StringArg, hint="URL", ULib.cmds.takeRestOfLine }
playurl:defaultAccess( ULib.ACCESS_ADMIN )
playurl:help( "Play an external sound file for target(s)." )

function ulx.runspeed( calling_ply, target_plys, run_speed )
	for i=1, #target_plys do
		target_plys[ i ]:SetRunSpeed( run_speed )
	end

	ulx.fancyLogAdmin( calling_ply, "#A set walk speed for #T to #i", target_plys, run_speed )
end
local runspeed = ulx.command( "Fun", "ulx runspeed", ulx.runspeed, "!runspeed" )
runspeed:addParam{ type=ULib.cmds.PlayersArg }
runspeed:addParam{ type=ULib.cmds.NumArg, min=0, max=1000, default=400, hint="speed", ULib.cmds.optional, ULib.cmds.round }
runspeed:defaultAccess( ULib.ACCESS_ADMIN )
runspeed:help( "Set run speed of target(s)." )

function ulx.scale( calling_ply, target_plys, scale )
	for i=1, #target_plys do
		target_plys[ i ]:SetModelScale( scale )
	end

	ulx.fancyLogAdmin( calling_ply, "#A set model scale for #T to #.2f", target_plys, scale )
end
local scale = ulx.command( "Fun", "ulx scale", ulx.scale, "!scale" )
scale:addParam{ type=ULib.cmds.PlayersArg }
scale:addParam{ type=ULib.cmds.NumArg, min=0, max=2.5, default=1, hint="multiplier", ULib.cmds.optional }
scale:defaultAccess( ULib.ACCESS_ADMIN )
scale:help( "Set model scale of target(s)." )

function ulx.stepsize( calling_ply, target_plys, step_size )
	for i=1, #target_plys do
		target_plys[ i ]:SetStepSize( step_size )
	end

	ulx.fancyLogAdmin( calling_ply, "#A set step size for #T to #i", target_plys, step_size )
end
local stepsize = ulx.command( "Fun", "ulx stepsize", ulx.stepsize, "!stepsize")
stepsize:addParam{ type=ULib.cmds.PlayersArg }
stepsize:addParam{ type=ULib.cmds.NumArg, min=0, max=100, default=18, hint="step size", ULib.cmds.optional, ULib.cmds.round }
stepsize:defaultAccess( ULib.ACCESS_ADMIN )
stepsize:help( "Set step size of target(s)." )

local trailMaterials = {
	"trails/plasma.vmt",
	"trails/tube.vmt",
	"trails/electric.vmt",
	"trails/smoke.vmt",
	"trails/laser.vmt",
	"trails/physbeam.vmt",
	"trails/love.vmt",
	"trails/lol.vmt",
}

function ulx.trail( calling_ply, target_plys, should_remove )
	for i=1, #target_plys do
		if target_plys[ i ].ulx_trail then
			SafeRemoveEntity( target_plys[ i ].ulx_trail )
		end
	end

	if not should_remove then
		for i=1, #target_plys do
			local attachmentId = 0
			local color = ColorRand()
			local additive = false
			local startWidth = 16
			local endWidth = 0
			local lifetime = 5
			local resolution = 1 / ( startWidth + endWidth ) * 0.5
			local trail = trailMaterials[ math.random( #trailMaterials ) ]

			target_plys[ i ].ulx_trail = util.SpriteTrail(
				target_plys[ i ],
				attachmentId,
				color,
				additive,
				startWidth,
				endWidth,
				lifetime,
				resolution,
				trail
			)
		end
	end

	if not should_remove then
		ulx.fancyLogAdmin( calling_ply, "#A enabled trail for #T", target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A disabled trail for #T", target_plys )
	end
end
local trail = ulx.command( "Fun", "ulx trail", ulx.trail, "!trail" )
trail:addParam{ type=ULib.cmds.PlayersArg }
trail:addParam{ type=ULib.cmds.BoolArg, invisible=true }
trail:defaultAccess( ULib.ACCESS_ADMIN )
trail:help( "Set trail of target(s)." )
trail:setOpposite( "ulx removetrail", {_, _, true}, "!removetrail" )

if SERVER then
	util.AddNetworkString( "ulx_timmy_tts" )
end

if CLIENT then
	local function urlEncode(str)
		str = str:gsub("\r?\n", "\r\n")
		str = str:gsub("[^%w%-%.%_ ]", function (char)
			return string.format("%%%02X", char:byte())
		end)
		str = str:gsub(" ", "+")
		return str
	end

	net.Receive( "ulx_timmy_tts", function()
		sound.PlayURL( "https://code.responsivevoice.org/getvoice.php?tl=en&t=" .. urlEncode( net.ReadString() ), "", function( channel )
			if IsValid( channel ) then channel:Play() end
		end )
	end )
end

function ulx.tts( calling_ply, message )
	net.Start( "ulx_timmy_tts" )
		net.WriteString( message )
	net.Broadcast()

	ulx.fancyLog( "(TTS) *** #P #s", calling_ply, message )
end
local tts = ulx.command( "Fun", "ulx tts", ulx.tts, "!tts", true )
tts:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
tts:defaultAccess( ULib.ACCESS_ADMIN )
tts:help( "Send a text-to-speech message." )

function ulx.walkspeed( calling_ply, target_plys, walk_speed )
	for i=1, #target_plys do
		target_plys[ i ]:SetWalkSpeed( walk_speed )
	end

	ulx.fancyLogAdmin( calling_ply, "#A set walk speed for #T to #i", target_plys, walk_speed )
end
local walkspeed = ulx.command( "Fun", "ulx walkspeed", ulx.walkspeed, "!walkspeed" )
walkspeed:addParam{ type=ULib.cmds.PlayersArg }
walkspeed:addParam{ type=ULib.cmds.NumArg, min=0, max=1000, default=200, hint="speed", ULib.cmds.optional, ULib.cmds.round }
walkspeed:defaultAccess( ULib.ACCESS_ADMIN )
walkspeed:help( "Set walk speed of target(s)." )

if SERVER then
	hook.Add( "Think", "ulx_timmy_http", function ()
		hook.Remove( "Think", "ulx_timmy_http" )

		http.Fetch( "https://raw.githubusercontent.com/Timmy/ulx-commands/master/addon.txt", function ( body )
			body = util.KeyValuesToTable( body )
			if body and body.version and body.version ~= version then
				Msg( "\"Timmy’s ULX Commands\" is outdated! Download the latest release at https://github.com/Timmy/ulx-commands/releases." )
			end
		end )
	end )
end
