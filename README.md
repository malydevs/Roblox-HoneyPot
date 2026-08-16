# Roblox-HoneyPot

After a long time of not uploading anything to GitHub, I'm back with a simple Roblox honeypot.

It's not the most advanced anti-exploit system out there, but I wanted to share it with the community. Feel free to use it, modify it, and improve it for your own projects.

## Features

* Strict Luau typing
* Configurable detection scoring
* Roblox `BanAsync` integration
* Permanent or temporary bans
* Universe-wide bans
* Optional alternate-account handling
* Optional device blocking
* Detection cooldowns
* Evidence tracking
* Multiple honeypot remotes
* Test mode

## How to Initialize

```lua
--!strict

local Honeypot = require(
	script.Parent:WaitForChild("HoneyPot")
)

Honeypot.Config.Enabled = true
Honeypot.Config.TestMode = false
Honeypot.Config.Duration = -1
Honeypot.Config.ApplyToUniverse = true
Honeypot.Config.ExcludeAltAccounts = false
Honeypot.Config.ApplyDeviceBlock = true
Honeypot.Config.ScoreToBan = 100
Honeypot.Config.DetectionCooldown = 2
Honeypot.Config.MaxEvidence = 20

Honeypot:CreateMultiple({
	TestRemote = 100,
})
```

## Configuration

| Setting              | Description                                |
| -------------------- | ------------------------------------------ |
| `Enabled`            | Enables or disables the honeypot           |
| `TestMode`           | Prevents permanent bans while testing      |
| `Duration`           | Ban duration in seconds; `-1` is permanent |
| `ApplyToUniverse`    | Applies the ban across the experience      |
| `ExcludeAltAccounts` | Controls alternate-account propagation     |
| `ApplyDeviceBlock`   | Enables Roblox's device blocking option    |
| `ScoreToBan`         | Detection score required to trigger a ban  |
| `DetectionCooldown`  | Minimum time between detections            |
| `MaxEvidence`        | Maximum evidence entries stored per player |

## Creating Honeypots

You can create multiple fake remotes with different detection scores:

```lua
Honeypot:CreateMultiple({
	GetServerInventory = 100,
	SyncServerData = 50,
})
```

A honeypot should represent something that a legitimate client would never need to invoke.

## Important

This should **not** be your only anti-exploit system.

A honeypot is best used alongside proper server-side validation. Never trust the client with important game logic such as:

* Currency
* Inventory
* Damage
* Items
* Permissions
* Trading
* Rewards
* Purchases

Always validate important requests on the server.

## Requirements

* Roblox experience
* Server-side Script/ModuleScript
* Luau
* `Players.BanningEnabled` enabled for Roblox ban API functionality

## License

Use, modify, and learn from the project at your own discretion.
