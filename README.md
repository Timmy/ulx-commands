# Timmy’s ULX Commands

A bunch of extra commands for the ULX admin mod for Garry’s Mod.

## Requirements

This addon is a ULX module. It requires the latest version of [ULib](https://github.com/TeamUlysses/ulib) and [ULX](https://github.com/TeamUlysses/ulx).

## Installation

### Steam Workshop

**https://steamcommunity.com/sharedfiles/filedetails/?id=1191491121**

Running a **listen server**? Subscribe to "Timmy's ULX Commands" on the Steam Workshop.

Running a **dedicated server**? Add "Timmy's ULX Commands" to your Steam Workshop Collection. See [“Workshop for Dedicated Servers” on the Garry’s Mod wiki](https://wiki.garrysmod.com/page/Workshop_for_Dedicated_Servers) for more details.

### Legacy addon

> **Warning:** Installing as a legacy addon means that you will have to perform updates manually.

1. Download the source code for the latest release at https://github.com/Timmy/ulx-commands/releases/latest.
2. Extract the archive in your `addons` directory. The file structure should look like this:
	- `<garrysmod>/addons/ulx-commands/addon.txt`
3. Restart your server.

## Commands

```
Rcon
	- ulx crunurl <players> <script URL> - Run an external Lua script on target(s). (say: !crunurl)
	- ulx runurl <script URL> - Run an external Lua script. (say: !runurl)

Utility
	- ulx aliases <players> - View aliases of target(s). (say: !aliases)
	- ulx banip <IP address> [<minutes, 0 for perma: 0<=x, default 1440>] - Add IP address tbanlist. (say: !banip)
	- ulx bot [<number: 1<=x<=32, default 32>] - Spawn bots. (say: !bot) (opposite: ulx kickbots)
	- ulx cleanup - Clean up the map. (say: !cleanup)
	- ulx cleardecals - Clear all decals for target(s). (say: !cleardecals)
	- ulx profile <player> - Open Steam profile page of target. (say: !profile)
	- ulx redirect <players> <hostname> - Redirect target(s) to another server. (say: !redirect)
	- ulx removeragdolls - Remove all client-side ragdolls. (say: !removeragdolls)
	- ulx stopsound - Stop all active sounds for target(s). (say: !stopsound)
	- ulx thirdperson - Toggles third person mode (say: !thirdperson) - (opposite: ulx firstperson)
	- ulx timescale [<multiplier: 0.01<=x<=5, default 1>] - Set the time scale of the game. (say: !timescale)
	- ulx url <players> {URL} - Open URL on target(s). (say: !url)

Chat
	- ulx deafen <players> - Deafens target(s) so they are unable to see or hear what others are saying. (say: !deafen) (opposite: ulx undeafen)
	- ulx rsay {message} - Send a colorful message to everyone in the chat box. (say: §)
	- ulx silence <players> - Silences target(s) so they are unable to speak or send chat messages. (say: !silence) (opposite: ulx unsilence)

Fun
	- ulx color <players> <color> - Set player color of target(s). (say: !color)
	- ulx gravity <players> [<gravity: -1<=x<=1, default 1>] - Set gravity of target(s). (say: !gravity)
	- ulx halo <players> - Draw glowing outline around target(s). (say: !halo) (opposite: ulx removehalo)
	- ulx jumppower <players> [<power: 0<=x<=1000, default 200>] - Set jump power of target(s). (say: !jumppower)
	- ulx launch <players> - Launch target(s) into the air. (say: !launch)
	- ulx playurl <players> {URL} - Play an external sound file for target(s). (say: !playurl)
	- ulx runspeed <players> [<speed: 0<=x<=1000, default 400>] - Set run speed of target(s). (say: !runspeed)
	- ulx scale <players> [<multiplier: 0<=x<=2.5, default 1>] - Set model scale of target(s). (say: !scale)
	- ulx stepsize <players> [<step size: 0<=x<=100, default 18>] - Set step size of target(s). (say: !stepsize)
	- ulx trail <players> - Set trail of target(s). (say: !trail) (opposite: ulx removetrail)
	- ulx tts {message} - Send a text-to-speech message. (say: !tts)
	- ulx walkspeed <players> [<speed: 0<=x<=1000, default 200>] - Set walk speed of target(s). (say: !walkspeed)
```

## Changelog

See the [CHANGELOG](CHANGELOG.md) file for information regarding changes between releases.
