# From The Depths — Lua API Reference

> **Helper documentation for building FTD Lua modules.**
> This is an ongoing reference — more sections will be added as docs are captured.

---

## ⚠️ IMPORTANT NOTE FOR AI MODELS ⚠️

> **If you are an AI model (e.g. GitHub Copilot, ChatGPT, etc.) helping build FTD Lua modules using this reference:**
>
> 1. **If you don't know something — ASK the user.** Do not guess or hallucinate API calls.
> 2. **Ask the user if documentation exists** for a module/function before assuming it does or doesn't.
> 3. **NEVER fill in function names, parameters, or return types randomly.** Incorrect API calls will break things silently in-game and debugging Lua inside FTD is extremely painful — there is no proper debugger, only `I:Log()` and trial-and-error.
> 4. **Code management in this game is a struggle.** The in-game Lua editor has no version control, no undo history, and limited space. A bad paste or wrong function call can ruin hours of work.
> 5. **When in doubt, leave a `-- TODO:` comment** and flag it to the user rather than writing potentially broken code.
>
> **TL;DR: It's better to ask a "dumb" question than to ship broken code into FTD.**

---

## Table of Contents

- [Basics](#basics)
- [Lua Syntax Reminders](#lua-syntax-reminders)
- [Logging / Debugging](#logging--debugging)
- [Libraries](#libraries)
- [Fleet Awareness](#fleet-awareness)
- [Resources](#resources)
- [AI](#ai)
- [Propulsion](#propulsion)
- [Target Info](#target-info)
- [Misc](#misc)
- [Self Awareness](#self-awareness)
- [Weapons](#weapons)
- [Missile Warning](#missile-warning)
- [Missile Guidance](#missile-guidance)
- [Spin Blocks and Pistons](#spin-blocks-and-pistons)
- [SubConstructs](#subconstructs)
- [Friendlies](#friendlies)

---

## Basics

The basic code file needs a function called `Update` that takes an input called `I`.

```lua
function Update(I)
    -- put your code here
end
```

- `I` is the interface to the game and contains all the function calls from the API.
- The code in `Update` will be executed **every single physics step** (the game runs at **40 physics steps per in-game second of time**).
- `--` creates a comment line; commented lines are never executed by the game.

### Hello World Example

```lua
function Update(I)
    I:Log('Hello')
end
```

---

## Lua Syntax Reminders

### String Concatenation

Done with `..` — numbers are automatically converted to strings.

```lua
-- 'Hello' .. ' Player' → 'Hello Player'
```

### For Loops

```lua
for ii = 0, 10, 1 do
    -- your code here (step size of 1 is the default)
end
```

### Calling Functions

The colon (`:`) is used for calling functions on the interface.
All calls to the interface start with `I:`.

```lua
I:RequestWaterForwards(5)
```

### Comments

```lua
-- this is a comment in Lua
```

### Global Variables

Declare a variable **outside** your `Update` function and it will be persistent from call to call.

```lua
count = 0
function Update(I)
    count = count + 1
    I:Log(count)
end
```

### If Statements

```lua
if a > 0 then
    -- your code here
end
```

---

## Logging / Debugging

### `I:Log(message)`

| | |
|---|---|
| **Inputs** | `message` [string] — the message you want to write to the log |
| **Outputs** | N/A |
| **Notes** | Writes a message to the log. Visible when editing the Lua box and appears in the *Errors / Log* panel. The last **100** log messages are maintained. |

### `I:ClearLogs()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | N/A |
| **Notes** | Clears your log. Pretty harmless! |

### `I:LogToHud(message)`

| | |
|---|---|
| **Inputs** | `message` [string] — the message you want to write to the HUD |
| **Outputs** | N/A |
| **Notes** | Writes a message to the HUD. HUD messages are visible during normal play and when on the map. |

---

## Libraries

### Mathf

The `Mathf` library is full of Unity math functions. Each function is **statically called** (dot notation, not colon).

```lua
Mathf.Min(1, 2)   -- ✅ correct
Mathf:Min(1, 2)   -- ❌ wrong
```

### Vector3

Unity's `Vector3` library is fully exposed.

```lua
local v = Vector3(x, y, z)         -- create a new Vector3
local angle = Vector3.Angle(v1, v2) -- example static call
```

> Refer to the [Unity Vector3 docs](https://docs.unity3d.com/ScriptReference/Vector3.html) for the full API.

### Quaternion

Unity's `Quaternion` library is fully exposed.

> Refer to the [Unity Quaternion docs](https://docs.unity3d.com/ScriptReference/Quaternion.html) for the full API.

---

## Fleet Awareness

The Fleet Awareness API provides scripts basic information about the fleet the craft is in.

### `I.FleetIndex` *(read only)*

| | |
|---|---|
| **Outputs** | [int] Position of the ship in the fleet, starting from 0 |
| **Notes** | Returns the index of the ship in the fleet. Starts at 0. |

### `I.Fleet` *(read only)*

| | |
|---|---|
| **Outputs** | [FleetInfo] Information about the fleet |
| **Notes** | Returns the current state of the fleet. |

### `I.IsFlagship` *(read only)*

| | |
|---|---|
| **Outputs** | [bool] Is the craft the fleet flagship? |
| **Notes** | Used to determine whether the ship is a flagship of a fleet. |

### FleetInfo (data type)

| Field | Type | Description |
|---|---|---|
| `ID` | int | Unique ID of the fleet |
| `Name` | string | Name of the fleet |
| `Flagship` | FriendlyInfo | Information about the flagship of the fleet |
| `Members` | FriendlyInfo[] | A table of information regarding the fleet's members. **MAY CONTAIN NILS!** |

---

## Resources

Scripts can use the following fields to get information about known resource zones. *(May change in the future to require a detector.)*

### `I.ResourceZones` *(read only)*

| | |
|---|---|
| **Outputs** | [ResourceZoneInfo[]] List of ResourceZones |
| **Notes** | Returns a Lua table containing a list of known resource zones. |

### `I.Resources` *(read only)*

| | |
|---|---|
| **Outputs** | [ResourceInfo] Ship resource data |
| **Notes** | Returns information about a ship's available resources. |

### ResourceZoneInfo (data type)

| Field | Type | Description |
|---|---|---|
| `Id` | int | Unique ID of the Resource Zone |
| `Name` | string | Name of the Resource Zone |
| `Position` | Vector3 | Position of the Resource Zone |
| `Radius` | float | Radius of the Resource Zone |
| `Resources` | ResourceInfo | Available resources of the Resource Zone |

### ResourceInfo (data type)

| Field | Type | Description |
|---|---|---|
| `CrystalTotal` | float | Total Crystal resources |
| `CrystalMax` | float | Max Crystal resources |
| `MetalTotal` | float | Total Metal resources |
| `MetalMax` | float | Max Metal resources |
| `NaturalTotal` | float | Total Natural resources |
| `NaturalMax` | float | Max Natural resources |
| `OilTotal` | float | Total Oil resources |
| `OilMax` | float | Max Oil resources |
| `ScrapTotal` | float | Total Scrap resources |
| `ScrapMax` | float | Max Scrap resources |

---

## AI

### `I:GetAIMovementMode(index)`

| | |
|---|---|
| **Inputs** | `index` [int] — index of the AI mainframe |
| **Outputs** | [string] movement mode. Possible modes: `Off`, `Manual`, `Automatic`, `Fleet` |
| **Notes** | Returns the movement mode of the AI mainframe specified by the index. |

### `I:GetAIFiringMode(index)`

| | |
|---|---|
| **Inputs** | `index` [int] — index of the AI mainframe |
| **Outputs** | [string] firing mode. Possible modes: `Off`, `On` |
| **Notes** | Returns the firing mode of the AI mainframe specified by the index. |

### `I.AIMode` *(read only)* — ⚠️ OBSOLETE

| | |
|---|---|
| **Outputs** | [string] Possible modes: `off`, `on` |
| **Notes** | Returns the mode of the AI mainframe. **Use `GetAIMovementMode` instead.** |

### `I.ConstructType` — ⚠️ OBSOLETE

| | |
|---|---|
| **Outputs** | [string] The type of construct. Possible types: `none` |
| **Notes** | AI's concept of what type of craft this ship is. |

---

## Propulsion

### Propulsion Type Enum

| Value | Axis |
|---|---|
| 0 | Main |
| 1 | Secondary |
| 2 | Tertiary |
| 3 | Roll |
| 4 | Pitch |
| 5 | Yaw |
| 6 | Forwards |
| 7 | Up |
| 8 | Right |
| 9 | A |
| 10 | B |
| 11 | C |
| 12 | D |
| 13 | E |

### `I:TellAIThatWeAreTakingControl()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | N/A |
| **Notes** | Will stop the AI from issuing propulsion commands for the next second, after which it will assume control again. This is exactly what happens when the player presses a control key on an AI controlled vehicle. |

### `I:AddPropulsionRequest(type, drive)`

| | |
|---|---|
| **Inputs** | `type` [int] — see propulsion type enum above | 
| | `drive` [float] — the amount to add to the axis |
| **Outputs** | N/A |
| **Notes** | Adds a propulsion request to the specified axis. This is **additive** to any other requests made to the axis in the same frame and is clamped between **-1 and 1**. |

### `I:SetPropulsionRequest(type, drive)`

| | |
|---|---|
| **Inputs** | `type` [int] — see propulsion type enum above |
| | `drive` [float] — the amount the axis is set to |
| **Outputs** | N/A |
| **Notes** | Sets the propulsion request to the specified axis. This **overwrites** any other requests made to the axis in the same frame and is clamped between **-1 and 1**. |

### `I:GetPropulsionRequest(type)`

| | |
|---|---|
| **Inputs** | `type` [int] — see propulsion type enum above |
| **Outputs** | N/A |
| **Notes** | Gets the sum of all requests made to the specified axis in the previous frame or reads the value that the drive is set to if the type is Main, Secondary or Tertiary. |

### `I:RequestComplexControllerStimulus(stim)`

| | |
|---|---|
| **Inputs** | `stim` [int] — see stimulus enum below |
| **Outputs** | N/A |
| **Notes** | Requests a stimuli as per the complex controller block. |

**Stimulus Enum:**

| Value | Key | | Value | Key |
|---|---|---|---|---|
| 0 | none | | 8 | O |
| 1 | T | | 9 | L |
| 2 | G | | 10 | up |
| 3 | Y | | 11 | down |
| 4 | H | | 12 | left |
| 5 | U | | 13 | right |
| 6 | J | | 14 | |
| 7 | I/K | | | |

### `I:MoveFortress(direction)`

| | |
|---|---|
| **Inputs** | `direction` [Vector3] — direction to move the fortress in. Limited to 1 meter. |
| **Outputs** | N/A |
| **Notes** | Move fortress in any direction. Limited to 1 meter. |

### `I:RequestCustomAxis(axisName, drive)`

| | |
|---|---|
| **Inputs** | `axisName` [string] — name of axis to create/use. Limited to 32 characters. |
| | `drive` [float] — value to add to the axis on this frame |
| **Outputs** | N/A |
| **Notes** | Creates or uses an axis with a custom name. Adds a value to the axis. Axes values are limited to between **-1 and 1**. Axes names are limited to 32 characters. |

### `I:GetCustomAxis(axisName)`

| | |
|---|---|
| **Inputs** | `axisName` [string] — name of axis to get value for |
| **Outputs** | [float] The value of the axis. 0 if axis not created yet. |
| **Notes** | Returns the value of the named axis that it had the previous frame, or 0 if axis not created yet. |

---

## Target Info

### `I:GetNumberOfMainframes()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [int] The number of mainframes on your vehicle |
| **Notes** | The mainframe count of your vehicle is useful for requesting targets. |

### `I:GetNumberOfTargets(mainframeIndex)`

| | |
|---|---|
| **Inputs** | `mainframeIndex` [int] — 0 being the first mainframe. Use `GetNumberOfMainframes()` to find out how many there are. |
| **Outputs** | [int] The number of targets in this particular mainframe. Returns 0 if such a mainframe does not exist. |
| **Notes** | The target count is important when calling `GetTarget(mainframeIndex, targetIndex)`. |

### `I:GetTargetInfo(mainframeIndex, targetIndex)`

| | |
|---|---|
| **Inputs** | `mainframeIndex` [int] — 0 being the first mainframe. |
| | `targetIndex` [int] — 0 being the first target. If target prioritisation card is in use, 0 is the highest priority target. |
| **Outputs** | A TargetInfo object |
| **Notes** | The TargetInfo object contains many interesting variables relating to the target. `Valid` will be false if the target has died but the AI has not yet cleared it. |

### TargetInfo (data type)

| Field | Type | Description |
|---|---|---|
| `Valid` | bool | True if a target was correctly returned |
| `Priority` | int | 0 is highest priority |
| `Score` | float | High is a good score — taken from target prioritisation card |
| `AimPointPosition` | Vector3 | Position in game world of aim point (current position of the block that's being aimed for) |
| `Team` | int | Team of target |
| `Protected` | bool | Is it salvage? Will be false for salvage. |
| `Position` | Vector3 | Position in game world of target object |
| `Velocity` | Vector3 | Velocity in game world in meters per second |
| `PlayerTargetChoice` | bool | Has the player set this as the target? |
| `Id` | int | The unique integer Id of the target |

### `I:GetTargetPositionInfo(mainframeIndex, targetIndex)`

| | |
|---|---|
| **Inputs** | `mainframeIndex` [int] — 0 being the first mainframe. |
| | `targetIndex` [int] — 0 being the first target. If target prioritisation card is in use, 0 is the highest priority target. |
| **Outputs** | A TargetPositionInfo object |
| **Notes** | The TargetPositionInfo object contains many interesting variables relating to the target. `Valid` will be false if the target has died but the AI has not yet cleared it. |

### `I:GetTargetPositionInfoForPosition(mainframeIndex, x, y, z)`

| | |
|---|---|
| **Inputs** | `mainframeIndex` [int] — 0 being the first mainframe. |
| | `x` [float] — east west in meters. |
| | `y` [float] — up down in meters (0 is sea level). |
| | `z` [float] — north south in meters. |
| **Outputs** | A TargetPositionInfo object. Velocity will be 0. |
| **Notes** | The TargetPositionInfo object contains many interesting variables relating to the target. |

### TargetPositionInfo (data type)

| Field | Type | Description |
|---|---|---|
| `Valid` | bool | True if target position info correctly returned |
| `Azimuth` | float | Degrees off nose of our vehicle where positive is clockwise |
| `Elevation` | float | Degrees off nose of our vehicle where positive is downwards. This often has dodgy values |
| `ElevationForAltitudeComponentOnly` | float | The elevation off nose of the target's altitude. Robustly calculated |
| `Range` | float | The range to the target |
| `Direction` | Vector3 | The direction to the target (absolute, not normalised) |
| `GroundDistance` | float | The distance along the ground (ignoring vertical component) to the target |
| `AltitudeAboveSeaLevel` | float | In metres |
| `Position` | Vector3 | Position of target |
| `Velocity` | Vector3 | Meters per second |

---

## Misc

### `I:GetTerrainAltitudeForPosition(x, y, z)`

| | |
|---|---|
| **Inputs** | `x` [float] — game world east west position in meters. |
| | `y` [float] — game world vertical (not important). |
| | `z` [float] — game world north south position in meters. |
| **Outputs** | [float] The terrain altitude in meters where 0 is sea level. |
| **Notes** | Returns altitude of the terrain at a position in the world. Can be overloaded with a single Vector3 rather than x,y,z components. |

### `I:GetTerrainAltitudeForLocalPosition(x, y, z)`

| | |
|---|---|
| **Inputs** | `x` [float] — right offset from construct position in meters. |
| | `y` [float] — up offset from construct position in meters. |
| | `z` [float] — forwards offset from construct position in meters. |
| **Outputs** | [float] The terrain altitude in meters where 0 is sea level. |
| **Notes** | Returns altitude of the terrain at a position relative to the construct. Can be overloaded with a single Vector3 rather than x,y,z components. |

### `I:GetGravityForAltitude(alt)`

| | |
|---|---|
| **Inputs** | `alt` [float] — altitude (0 is sea level) |
| **Outputs** | [Vector3] gravity vector |
| **Notes** | Returns gravity vector for an altitude. `gravity.y` is the component of interest. |

### `I:GetTime()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] The time in seconds. |
| **Notes** | Returns time with an arbitrary offset (i.e. the time will seldom be 0). |

### `I:GetTimeSinceSpawn()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] The time in seconds since the construct spawned. |
| **Notes** | Returns time since construct spawned in seconds. |

### `I:GetGameTime()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] The time since the Instance started in seconds. |
| **Notes** | Returns time since the instance started in seconds. |

### `I:GetWindDirectionAndMagnitude()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] Vector representing the direction and the magnitude of the wind. |
| **Notes** | Get the direction and magnitude of the current wind. |

---

## Self Awareness

### Position & Orientation

#### `I:GetConstructPosition()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] The position (Vector3 has members x, y, and z). |
| **Notes** | Returns the position of the construct. The construct's position is essentially the position of the first ever block placed, or the centre of the starting raft that it was built from. |

#### `I:GetConstructForwardVector()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] The forward pointing vector of the construct (length 1) |
| **Notes** | Return the forward pointing vector of the construct. |

#### `I:GetConstructRightVector()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] The right pointing vector of the construct (length 1) |
| **Notes** | Return the right pointing vector of the construct. |

#### `I:GetConstructUpVector()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] The up pointing vector of the construct (length 1) |
| **Notes** | Return the up pointing vector of the construct. |

### Dimensions

#### `I:GetConstructMaxDimensions()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] The size of the vehicle right, up and forwards of its origin |
| **Notes** | Returns the 'positive' size of the vehicle (right, up, forwards) relative to its origin (`GetConstructPosition()`). The coordinates are in local space. This minus `GetConstructMinDimensions()` provides the full size of the vehicle. |

#### `I:GetConstructMinDimensions()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] The size of the vehicle left, down and back of its origin |
| **Notes** | Returns the 'negative' size of the vehicle (left, down, back) relative to its origin (`GetConstructPosition()`). The coordinates are in local space. |

### Rotation Angles

#### `I:GetConstructRoll()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] The roll angle in degrees |
| **Notes** | Return the roll angle in degrees. |

#### `I:GetConstructPitch()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] The pitch angle in degrees |
| **Notes** | Return the pitch angle in degrees. |

#### `I:GetConstructYaw()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] The yaw angle in degrees |
| **Notes** | Return the yaw angle in degrees. |

### Centre of Mass

#### `I:GetConstructCenterOfMass()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] The position (Vector3 has members x, y, and z). |
| **Notes** | Returns the position of the construct's centre of mass in the world. |

#### `I:GetConstructLocalCenterOfMass()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] The local position (Vector3 has members x, y, and z). |
| **Notes** | Returns the position of the construct's centre of mass in the vehicle. It is typically rounded to 50cm increments to make balancing more achievable, but this can be changed in the 'V' menu. |

### AI Mainframe Position

#### `I:GetAiPosition(mainframeIndex)`

| | |
|---|---|
| **Inputs** | `mainframeIndex` [int] — 0 is the first mainframe. |
| **Outputs** | [Vector3] The position (Vector3 has members x, y, and z). |
| **Notes** | Returns the position of the mainframe in the world. Returns `Vector3(0,0,0)` if no such mainframe exists. |

### Velocity

#### `I:GetVelocityMagnitude()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] Magnitude of your velocity in meters per second. |
| **Notes** | Returns the magnitude of your velocity in meters per second. |

#### `I:GetForwardsVelocityMagnitude()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] Magnitude of your forwards velocity in meters per second. |
| **Notes** | Returns the magnitude of your velocity in the forwards direction in meters per second. A negative value means you're going predominantly backwards. |

#### `I:GetVelocityVector()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] Your construct's velocity vector in meters per second |
| **Notes** | Returns your construct's velocity vector in world space in meters per second. x is east west, y is up down and z is north south. |

#### `I:GetVelocityVectorNormalized()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] Your construct's velocity vector in meters per second — normalized to have a length of 1. |
| **Notes** | Returns your construct's velocity vector in world space in meters per second. x is east west, y is up down and z is north south. It's normalized to have a length of 1. |

### Angular Velocity

#### `I:GetAngularVelocity()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] Your construct's angular velocity in world space |
| **Notes** | Returns your angular velocity. x is speed of turn around the east→west axis, y is around the vertical axis and z is around the north south axis. You're probably going to want the next function instead of this one... |

#### `I:GetLocalAngularVelocity()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [Vector3] Your construct's angular velocity in local space |
| **Notes** | Returns your angular velocity. x is pitch, y yaw and z roll. |

### Resource Fractions

#### `I:GetAmmoFraction()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] Fraction 0 to 1. 1 if no ammo storage is available. |
| **Notes** | Returns the fraction of ammo your construct has left. |

#### `I:GetFuelFraction()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] Fraction 0 to 1. 1 if no fuel storage is available. |
| **Notes** | Returns the fraction of fuel your construct has left. |

#### `I:GetSparesFraction()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] Fraction 0 to 1. 1 if no spares storage is available. |
| **Notes** | Returns the fraction of spares your construct has left. |

#### `I:GetEnergyFraction()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] Fraction 0 to 1. 1 if no batteries are available. |
| **Notes** | Returns the fraction of energy your construct has left. |

#### `I:GetPowerFraction()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] Fraction 0 to 1. |
| **Notes** | Returns the fraction of power your construct has left. |

#### `I:GetElectricPowerFraction()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] Fraction 0 to 1. |
| **Notes** | Returns the fraction of electric power your construct has left. |

### Health & Status

#### `I:GetHealthFraction()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [float] Fraction 0 to 1. 1 if full health. |
| **Notes** | Returns the fraction of health your construct has (including turrets etc). |

#### `I:IsDocked()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [bool] Docked? true for yes. |
| **Notes** | Returns true if the vehicle is docked. |

#### `I:GetHealthFractionDifference(time)`

| | |
|---|---|
| **Inputs** | `time` [float] — the time you want the difference measured over. Will be limited to between 1 and 30. |
| **Outputs** | [float] Health difference as a fraction (0 to 1) |
| **Notes** | Returns health difference over a specified measurement time. |

### Identity

#### `I:GetBlueprintName()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [string] Name of the blueprint. |
| **Notes** | Returns the name of this blueprint. |

#### `I:GetUniqueId()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [int] The unique id. |
| **Notes** | Returns the unique id of this construct. No other construct has the same id. |

---

## Weapons

### `I:GetWeaponCount()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [int] The number of weapons on the hull — doesn't include weapons on turrets but does include the turrets themselves. |
| **Notes** | Knowing the number is useful for when you want to call `GetWeaponInfo(i)` to find out weapon information. |

### `I:GetWeaponInfo(weaponIndex)`

| | |
|---|---|
| **Inputs** | `weaponIndex` [int] — the index of the weapon you want information on. 0 is the first weapon. |
| **Outputs** | [WeaponInfo] information on the weapon. `weaponInfo.Valid` is false if you ask for an invalid weaponIndex. |
| **Notes** | Gets weapon information for a specific weapon. Useful to figure out what sort of weapon is present. |

### WeaponInfo (data type)

| Field | Type | Description |
|---|---|---|
| `Valid` | bool | False means this WeaponInfo packet is useless. Move onto the next valid one. |
| `LocalPosition` | Vector3 | The local position in the vehicle of the weapon. x is right, y is up and z is forwards. |
| `GlobalPosition` | Vector3 | The global position of the weapon. x is East, y is Up and Z is North. |
| `LocalFirePoint` | Vector3 | The local position in the vehicle where the projectile or laser will be created. |
| `GlobalFirePoint` | Vector3 | The global position in the world where the projectile or laser will be created. |
| `Speed` | float | The speed in meters per second of the weapon — approximately correct for most weapon types. |
| `CurrentDirection` | Vector3 | The direction in global coordinate system that the weapon is facing. |
| `WeaponType` | int | The type of the weapon. `0` = cannon, `1` = missile, `2` = laser, `3` = harpoon, `4` = turret, `5` = missilecontrol, `6` = fireControlComputer |
| `WeaponSlot` | int | The weapon slot of the weapon itself. 0 → 5. |
| `WeaponSlotMask` | int | The weapon slot bit mask. The rightmost bit represents 'ALL' and is always on, and the second bit represents slot 1, etc. (e.g. `100111` will respond to All, 1, 2, and 5) |
| `PlayerCurrentlyControllingIt` | bool | True if the player is controlling this weapon at the moment. |

### Weapon Type Enum

| Value | Type |
|---|---|
| 0 | cannon |
| 1 | missile |
| 2 | laser |
| 3 | harpoon |
| 4 | turret |
| 5 | missilecontrol |
| 6 | fireControlComputer |

### `I:GetWeaponConstraints(weaponIndex)`

| | |
|---|---|
| **Inputs** | `weaponIndex` [int] — the index of the weapon you want the constraints of. 0 is the first weapon. |
| **Outputs** | [WeaponConstraints] information on the field-of-fire constraints of the weapon. |
| **Notes** | Gets field-of-fire constraints information for a specific weapon. |

### WeaponConstraints (data type)

| Field | Type | Description |
|---|---|---|
| `Valid` | bool | False means this packet is useless. Move onto the next valid one. |
| `MinAzimuth` | float | The minimum azimuth angle in degrees. |
| `MaxAzimuth` | float | The maximum azimuth angle in degrees. |
| `MinElevation` | float | The minimum elevation angle in degrees. |
| `MaxElevation` | float | The maximum elevation angle in degrees. |
| `FlipAzimuth` | bool | True if the 'Flip azimuth constraints' toggle is selected. |
| `InParentConstructSpace` | bool | True if the 'Set the restrictions in the parent construct space' toggle is selected. |

### `I:GetWeaponBlockInfo(weaponIndex)`

| | |
|---|---|
| **Inputs** | `weaponIndex` [int] — the index of the weapon you want information on. 0 is the first weapon. |
| **Outputs** | [BlockInfo] the block information of the main component of the weapon. See 'Components' for information on BlockInfo. |
| **Notes** | Gets the block information for a specific weapon. |

### `I:AimWeaponInDirection(weaponIndex, x, y, z, weaponSlot)`

| | |
|---|---|
| **Inputs** | `weaponIndex` [int] — 0 is the first weapon. |
| | `x,y,z` [floats] — the world coordinate scheme direction components to point in. They don't need to be normalised. |
| | `weaponSlot` [int] — 0 for all, otherwise 1 to 5. |
| **Outputs** | [int] the number of weapons that can fire in this direction. 0 for none. |
| **Notes** | Aims a weapon in a specific direction. For a turret this will aim all weapons on the turret as well as the turret itself. |

### `I:FireWeapon(weaponIndex, weaponSlot)`

| | |
|---|---|
| **Inputs** | `weaponIndex` [int] — 0 is the first weapon. |
| | `weaponSlot` [int] — 0 will control all weapons. |
| **Outputs** | [bool] has any weapon fired? Will be true if so. |
| **Notes** | Fires a specific weapon. It's important for most weapons that you aim them first as they won't fire if they can't fire in the direction they are aimed. |

### SubConstruct Weapon Functions

These are the **current recommended** functions for controlling weapons on turrets/spinners (replacing the obsolete TurretOrSpinner variants).

#### `I:GetWeaponCountOnSubConstruct(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — this identifier never changes in the blueprint. Use the SubConstructs-related functions to get it. |
| **Outputs** | [int] the number of weapons on this turret or spinner, not including the turret itself. |
| **Notes** | Return the number of weapons on the turret or spinner. If you wanted to control the turret itself then note that it is treated as a hull mounted weapon. |

#### `I:GetWeaponInfoOnSubConstruct(SubConstructIdentifier, weaponIndex)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — persistent identifier. |
| | `weaponIndex` [int] — the index of the weapon. 0 is the first one. |
| **Outputs** | [WeaponInfo] a WeaponInfo object. Note that changes to this structure in LUA do not affect the weapon itself. |
| **Notes** | Get weapon info of a weapon on a turret or spinner. |

#### `I:GetWeaponConstraintsOnSubConstruct(SubConstructIdentifier, weaponIndex)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — persistent identifier. |
| | `weaponIndex` [int] — the index of the weapon. 0 is the first one. |
| **Outputs** | [WeaponConstraints] information on the field-of-fire constraints of the weapon. |
| **Notes** | Gets field-of-fire constraints information for a specific weapon. |

#### `I:GetWeaponBlockInfoOnSubConstruct(SubConstructIdentifier, weaponIndex)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — persistent identifier. |
| | `weaponIndex` [int] — the index of the weapon. 0 is the first one. |
| **Outputs** | [BlockInfo] the block information of the main component of the weapon. See 'Components' for information on BlockInfo. |
| **Notes** | Gets the block information for a specific weapon. |

#### `I:AimWeaponInDirectionOnSubConstruct(SubConstructIdentifier, weaponIndex, x, y, z, weaponSlot)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the SubConstruct identifier. For the other parameters, see `AimWeaponInDirection`. |
| **Outputs** | as per `AimWeaponInDirection` |
| **Notes** | Aims a specific weapon on the turret without aiming the turret. |

#### `I:FireWeaponOnSubConstruct(SubConstructIdentifier, weaponIndex, weaponSlot)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the SubConstruct identifier. For the other parameters, see `FireWeapon`. |
| **Outputs** | [bool] has any weapon fired? Will be true if so. |
| **Notes** | Fires a specific weapon. It's important for most weapons that you aim them first as they won't fire if they can't fire in the direction they are aimed. |

### Obsolete Turret/Spinner Weapon Functions

> ⚠️ The following functions are **obsolete**. Use the `*OnSubConstruct` variants above instead.

- `I:GetTurretSpinnerCount()` → use SubConstructs API
- `I:GetWeaponCountOnTurretOrSpinner(turretSpinnerIndex)` → use `GetWeaponCountOnSubConstruct`
- `I:GetWeaponInfoOnTurretOrSpinner(turretSpinnerIndex, weaponIndex)` → use `GetWeaponInfoOnSubConstruct`
- `I:AimWeaponInDirectionOnTurretOrSpinner(...)` → use `AimWeaponInDirectionOnSubConstruct`
- `I:FireWeaponOnTurretOrSpinner(...)` → use `FireWeaponOnSubConstruct`

---

## Missile Warning

### `I:GetNumberOfWarnings()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [int] The number of missiles being warned on. |
| **Notes** | Return the number of missiles the construct has warnings for. |

### `I:GetMissileWarning(missileIndex)`

| | |
|---|---|
| **Inputs** | `missileIndex` [int] — the index of the missile. |
| **Outputs** | [MissileWarningInfo] information on the missile. `missileWarningInfo.Valid` = false if you didn't request an existing missile index. |
| **Notes** | Request information on a specific missile warning. |

### MissileWarningInfo (data type)

| Field | Type | Description |
|---|---|---|
| `Valid` | bool | False if the warning is junk due to incorrect indices. |
| `Position` | Vector3 | The position of the missile. |
| `Velocity` | Vector3 | The velocity of the missile in meters per second. |
| `Range` | float | The distance from centre of mass of your construct to the missile. |
| `Azimuth` | float | The azimuth angle between your construct's forward direction and the missile (degrees). |
| `Elevation` | float | The elevation angle between your construct's forward direction and the missile (degrees). |
| `TimeSinceLaunch` | float | The time since missile launch. |
| `Id` | int | The unique Id of the missile. |

---

## Missile Guidance

Connect **LUA Transceivers** to your missile blocks to allow missiles from those missile blocks to be sent LUA Guidance points.

### `I:GetLuaTransceiverCount()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [int] The number of LuaTransceivers. |
| **Notes** | Return the number of LuaTransceivers. Each transceiver can have a number of missiles which are controllable. |

### `I:GetLuaControlledMissileCount(luaTransceiverIndex)`

| | |
|---|---|
| **Inputs** | `luaTransceiverIndex` [int] — the index of the LuaTransceiver where 0 is the first one. |
| **Outputs** | [int] The number of missiles associated with that LuaTransceiver. |
| **Notes** | Returns the number of missiles which that luaTransceiver has communications link to. |

### `I:GetLuaTransceiverInfo(luaTransceiverIndex)`

| | |
|---|---|
| **Inputs** | `luaTransceiverIndex` [int] — the index of the LuaTransceiver where 0 is the first one. |
| **Outputs** | [BlockInfo] a BlockInfo object for the LuaTransceiver's Launchpad. |
| **Notes** | Returns a BlockInfo object for the LuaTransceiver's Launchpad. If no Launch pad exists it'll return it for the LuaTransceiver. See the Components tab for the BlockInfo structure. |

### `I:GetLuaControlledMissileInfo(luaTransceiverIndex, missileIndex)`

| | |
|---|---|
| **Inputs** | `luaTransceiverIndex` [int] — 0 is the first one. |
| | `missileIndex` [int] — 0 is the first missile. |
| **Outputs** | [MissileWarningInfo] Get a MissileWarningInfo object for your missile. |
| **Notes** | Returns a MissileWarningInfo structure for your missile. You can tell where it is and how fast it is going from this. See the Missile Warning tab for the MissileWarningInfo structure. |

### `I:SetLuaControlledMissileAimPoint(luaTransceiverIndex, missileIndex, x, y, z)`

| | |
|---|---|
| **Inputs** | `luaTransceiverIndex` [int] — as above. |
| | `missileIndex` [int] — as above. |
| | `x,y,z` [floats] — global coordinates of the aim point. |
| **Outputs** | N/A |
| **Notes** | Sets the aim point. No guidance modules will help achieve this aim point so do your own predictive guidance. Needs a **lua receiver component ON the missile** to work. |

### `I:DetonateLuaControlledMissile(luaTransceiverIndex, missileIndex)`

| | |
|---|---|
| **Inputs** | `luaTransceiverIndex` [int] — as above. |
| | `missileIndex` [int] — as above. |
| **Outputs** | N/A |
| **Notes** | Explodes the missile. Needs a **lua receiver component ON the missile** to work. |

### `I:IsLuaControlledMissileAnInterceptor(luaTransceiverIndex, missileIndex)`

| | |
|---|---|
| **Inputs** | `luaTransceiverIndex` [int] — 0 is the first one. |
| | `missileIndex` [int] — 0 is the first one. |
| **Outputs** | [bool] true means the missile has an interceptor module, otherwise false is returned. If the missile has no lua receiver, false will be returned. |
| **Notes** | Find out if the missile has an interceptor capability. |

### `I:SetLuaControlledMissileInterceptorTarget(luaTransceiverIndex, missileIndex, targetIndex)`

| | |
|---|---|
| **Inputs** | `luaTransceiverIndex` [int] — 0 is the first one. |
| | `missileIndex` [int] — 0 is the first one. |
| | `targetIndex` [int] — 0 is the first missile which that mainframe has a warning for. |
| **Outputs** | N/A |
| **Notes** | Set the target of an interceptor missile to be a specific missile for which a warning exists. This is enough to get the interceptor missile to behave normally but if you want to actually guide it yourself use `SetLuaControlledMissileInterceptorStandardGuidanceOnOff` to turn the guidance off. |

### `I:SetLuaControlledMissileInterceptorStandardGuidanceOnOff(luaTransceiver, missileIndex, onOff)`

| | |
|---|---|
| **Inputs** | `luaTransceiver` [int] — 0 is the first one. |
| | `missileIndex` [int] — 0 is the first one. |
| | `onOff` [bool] — true will use standard missile guidance to aim at the interceptors target, false will rely on `SetLuaControlledMissileAimPoint` for aiming coordinates. |
| **Outputs** | N/A |
| **Notes** | Turns standard guidance for the missile on and off. Turn it off if you're going to guide the missile in yourself. |

---

## Spin Blocks and Pistons

Spin blocks and pistons have their own interface because they use **SubConstruct identifiers**.

### Spinners

#### `I:SetSpinBlockSpeedFactor(SubConstructIdentifier, speedFactor)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| | `speedFactor` [float] — 0 to 1, the fractional power output. |
| **Outputs** | N/A |
| **Notes** | Set the speed factor. In continuous mode spinners this allows some blades to spin slower than others, in insta-spin blades this is related to the speed they are spinning at (1 is max speed, 0 is no speed), and in rotation spinners this does nothing. |

#### `I:SetSpinBlockPowerDrive(SubConstructIdentifier, drive)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| | `drive` [float] — the relative power use of the spinner (0 to 10). |
| **Outputs** | N/A |
| **Notes** | Sets the power drive. This allows heliblades to produce more force. Requires engine power. 0 removes engine use. 10 is maximum power use. |

#### `I:SetSpinBlockRotationAngle(SubConstructIdentifier, angle)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| | `angle` [float] — angle in degrees to turn to. |
| **Outputs** | N/A |
| **Notes** | Sets the angle of rotation. Changes the spinner into Rotate mode. 'Rotatebackwards' is not available through this interface but you shouldn't need it. |

#### `I:SetSpinBlockContinuousSpeed(SubConstructIdentifier, speed)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| | `speed` [float] — speed to rotate at. 30 is the maximum so values from -30 to 30 work. |
| **Outputs** | N/A |
| **Notes** | Sets the speed of rotation. Changes the spinner into continuous mode. 'ContinuousReverse' mode is not available through this interface so set the speed negative to facilitate reverse spinning. |

#### `I:SetSpinBlockInstaSpin(SubConstructIdentifier, magnitudeAndDirection)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| | `magnitudeAndDirection` [float] — -1 means spin backwards full speed, 1 is spin forwards full speed. |
| **Outputs** | N/A |
| **Notes** | Spins the blades in a direction and speed determined by magnitudeAndDirection. Will set the spinner into instaspin forwards mode and will affect speed factor variable of the spinner. |

### Pistons

#### `I:GetPistonExtension(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [float] the extension distance of the piston in meters. |
| **Notes** | Get the extension of the piston, -1 if not found. |

---

## SubConstructs

SubConstructs (turrets and spin blocks) have their own interface dedicated to work with stacked SubConstructs. They all have a **unique persistent index** which will never be modified in the blueprint (that index starts at 1).

### `I:GetAllSubconstructsCount()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [int] The total number of SubConstructs on the vehicle. |
| **Notes** | Returns the number of SubConstructs on the vehicle, including SubConstructs on SubConstructs. |

### `I:GetSubConstructIdentifier(index)`

| | |
|---|---|
| **Inputs** | `index` [int] — 0 is the first SubConstruct. |
| **Outputs** | [int] The persistent identifier of the SubConstruct. |
| **Notes** | Returns the identifier of the SubConstruct. The indices start at 0 and are in no particular order. |

### `I:GetSubconstructsChildrenCount(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [int] All the number of SubConstructs directly placed on the given SubConstruct. |
| **Notes** | Returns the number of SubConstructs on the given SubConstruct. |

### `I:GetSubConstructChildIdentifier(SubConstructIdentifier, index)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the parent SubConstruct. |
| | `index` [int] — 0 is the first child SubConstruct. |
| **Outputs** | [int] The persistent identifier of the child SubConstruct. |
| **Notes** | Returns the identifier of the child SubConstruct placed on the parent SubConstruct. The indices start at 0 and are in no particular order. |

### `I:GetParent(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [int] The persistent index of the parent SubConstruct of the given SubConstruct. |
| **Notes** | Returns the persistent index of the parent SubConstruct of the given SubConstruct, `0` for the MainConstruct, `-1` if not found. |

### `I:IsTurret(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [bool] true if the SubConstruct is a turret, false otherwise. |
| **Notes** | Indicates if the SubConstruct is a turret or not. |

### `I:IsSpinBlock(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [bool] true if the SubConstruct is a spin block, false otherwise. |
| **Notes** | Indicates if the SubConstruct is a spin block or not. |

### `I:IsPiston(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [bool] true if the SubConstruct is a piston, false otherwise. |
| **Notes** | Indicates if the SubConstruct is a piston or not. |

### `I:IsAlive(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [bool] true if the SubConstruct is not completely destroyed. |
| **Notes** | Indicates if the SubConstruct is destroyed or not. |

### `I:IsSubConstructOnHull(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [bool] true if the SubConstruct is on the hull. |
| **Notes** | Indicates if the SubConstruct is on the hull or not. |

### `I:GetSubConstructInfo(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [BlockInfo] a BlockInfo object for the SubConstruct active block (the SpinBlock block, the piston or the turret block). |
| **Notes** | Returns a BlockInfo object for the active block of the SubConstruct, and invalid BlockInfo if the SubConstruct hasn't been found. |

### `I:GetSubConstructIdleRotation(SubConstructIdentifier)`

| | |
|---|---|
| **Inputs** | `SubConstructIdentifier` [int] — the persistent identifier of the SubConstruct. |
| **Outputs** | [Quaternion] The rotation of the subconstruct relative to its parent as it was first placed. |
| **Notes** | Returns a Quaternion representing the orientation of the block in its parent SubConstruct as it was when it was placed. |

---

## Friendlies

The following API will provide you with the positions of friendly vehicles.

### `I:GetFriendlyCount()`

| | |
|---|---|
| **Inputs** | N/A |
| **Outputs** | [int] The number of friendlies spawned into the world. |
| **Notes** | Returns the number of friendly constructs. |

### `I:GetFriendlyInfo(index)`

| | |
|---|---|
| **Inputs** | `index` [int] — 0 is the first construct. |
| **Outputs** | [FriendlyInfo] the FriendlyInfo object. |
| **Notes** | Returns a friendly info object for a friendly vehicle. |

### `I:GetFriendlyInfoById(Id)`

| | |
|---|---|
| **Inputs** | `Id` [int] — the Id you want. |
| **Outputs** | [FriendlyInfo] the FriendlyInfo object. |
| **Notes** | Returns a friendly info object for an Id. |

### FriendlyInfo (data type)

| Field | Type | Description |
|---|---|---|
| `Valid` | bool | False if the Friendly Info could not be retrieved. |
| `Rotation` | Quaternion | The rotation of the friendly construct. |
| `ReferencePosition` | Vector3 | The position of the construct (world East Up North frame) from which PositiveSize and NegativeSize are referenced. |
| `PositiveSize` | Vector3 | The extent of the construct in the right, up, forwards direction relative to ReferencePosition. |
| `NegativeSize` | Vector3 | The extent of the construct in the left, down, back direction relative to ReferencePosition. |
| `CenterOfMass` | Vector3 | The centre of mass of the construct in world East Up North frame. |
| `Velocity` | Vector3 | The velocity of the construct in world East Up North frame. |
| `UpVector` | Vector3 | The up vector in world East Up North frame. |
| `RightVector` | Vector3 | The right vector in world East Up North frame. |
| `ForwardVector` | Vector3 | The forward vector in world East Up North frame. |
| `HealthFraction` | float | The fraction of health (including turrets etc). |
| `SparesFraction` | float | The spares fraction. Returns 1 if no spares storage present. |
| `AmmoFraction` | float | The ammo fraction. Returns 1 if no ammo storage present. |
| `FuelFraction` | float | The fuel fraction. Returns 1 if no fuel storage present. |
| `EnergyFraction` | float | The energy fraction. Returns 1 if no batteries present. |
| `PowerFraction` | float | The power fraction. Returns 1 if no fuel storage present. |
| `ElectricPowerFraction` | float | The electric power fraction. Returns 1 if no fuel storage present. |
| `AxisAlignedBoundingBoxMinimum` | Vector3 | The world East Up North minimum extent of the construct. |
| `AxisAlignedBoundingBoxMaximum` | Vector3 | The world East Up North maximum extent of the construct. |
| `BlueprintName` | string | The name. |
| `Id` | int | The unique Id of the construct. |

---

## Quick Reference Cheat Sheet

```text
┌──────────────────────────────────────────────────────────────────┐
│  LOGGING                                                         │
│    I:Log(msg)                        → log panel (last 100)      │
│    I:LogToHud(msg)                   → HUD overlay               │
│    I:ClearLogs()                     → clear log                 │
├──────────────────────────────────────────────────────────────────┤
│  FLEET                                                           │
│    I.FleetIndex                      → int (0-based)             │
│    I.Fleet                           → FleetInfo                 │
│    I.IsFlagship                      → bool                      │
├──────────────────────────────────────────────────────────────────┤
│  RESOURCES                                                       │
│    I.ResourceZones                   → ResourceZoneInfo[]        │
│    I.Resources                       → ResourceInfo              │
├──────────────────────────────────────────────────────────────────┤
│  AI                                                              │
│    I:GetAIMovementMode(idx)          → string                    │
│    I:GetAIFiringMode(idx)            → string                    │
├──────────────────────────────────────────────────────────────────┤
│  PROPULSION                                                      │
│    I:TellAIThatWeAreTakingControl()                              │
│    I:Add/SetPropulsionRequest(type, drive)                       │
│    I:RequestCustomAxis(name, drive)                              │
│    I:GetCustomAxis(name)             → float                     │
├──────────────────────────────────────────────────────────────────┤
│  TARGET INFO                                                     │
│    I:GetNumberOfMainframes()         → int                       │
│    I:GetNumberOfTargets(mf)          → int                       │
│    I:GetTargetInfo(mf, ti)           → TargetInfo                │
│    I:GetTargetPositionInfo(mf, ti)   → TargetPositionInfo        │
├──────────────────────────────────────────────────────────────────┤
│  MISC                                                            │
│    I:GetTime/TimeSinceSpawn/GameTime → float                     │
│    I:GetGravityForAltitude(alt)      → Vector3                   │
│    I:GetWindDirectionAndMagnitude()  → Vector3                   │
├──────────────────────────────────────────────────────────────────┤
│  SELF AWARENESS                                                  │
│    I:GetConstructPosition()          → Vector3                   │
│    I:GetConstruct[Forward/Right/Up]Vector() → Vector3 (unit)     │
│    I:GetConstructRoll/Pitch/Yaw()    → float (degrees)           │
│    I:GetVelocityVector()             → Vector3 (m/s)             │
│    I:GetLocalAngularVelocity()       → Vector3 (pitch,yaw,roll)  │
│    I:Get[Ammo/Fuel/Health]Fraction() → float (0-1)               │
├──────────────────────────────────────────────────────────────────┤
│  WEAPONS                                                         │
│    I:GetWeaponCount()                → int                       │
│    I:GetWeaponInfo(idx)              → WeaponInfo                │
│    I:AimWeaponInDirection(idx,x,y,z,slot) → int                  │
│    I:FireWeapon(idx, slot)           → bool                      │
│    I:Get*OnSubConstruct(scId, ...)   → SubConstruct variants     │
├──────────────────────────────────────────────────────────────────┤
│  MISSILE WARNING                                                 │
│    I:GetNumberOfWarnings()           → int                       │
│    I:GetMissileWarning(idx)          → MissileWarningInfo        │
├──────────────────────────────────────────────────────────────────┤
│  MISSILE GUIDANCE                                                │
│    I:GetLuaTransceiverCount()        → int                       │
│    I:GetLuaControlledMissileCount(t) → int                       │
│    I:GetLuaControlledMissileInfo(t,m)→ MissileWarningInfo        │
│    I:SetLuaControlledMissileAimPoint(t,m,x,y,z)                  │
│    I:DetonateLuaControlledMissile(t,m)                           │
├──────────────────────────────────────────────────────────────────┤
│  SPIN BLOCKS & PISTONS                                           │
│    I:SetSpinBlockRotationAngle(sc, angle)                        │
│    I:SetSpinBlockContinuousSpeed(sc, speed)                      │
│    I:SetSpinBlockInstaSpin(sc, mag)                              │
│    I:GetPistonExtension(sc)          → float                     │
├──────────────────────────────────────────────────────────────────┤
│  SUBCONSTRUCTS                                                   │
│    I:GetAllSubconstructsCount()      → int                       │
│    I:GetSubConstructIdentifier(idx)  → int                       │
│    I:IsTurret/IsSpinBlock/IsPiston(sc) → bool                    │
│    I:IsAlive(sc)                     → bool                      │
├──────────────────────────────────────────────────────────────────┤
│  FRIENDLIES                                                      │
│    I:GetFriendlyCount()              → int                       │
│    I:GetFriendlyInfo(idx)            → FriendlyInfo              │
│    I:GetFriendlyInfoById(id)         → FriendlyInfo              │
├──────────────────────────────────────────────────────────────────┤
│  LIBRARIES                                                       │
│    Mathf.Func()                      → static calls              │
│    Vector3(x,y,z)                    → constructor               │
│    Quaternion                        → Unity Quaternion           │
└──────────────────────────────────────────────────────────────────┘
```

---

> 📌 **Sections not yet documented:** Components (full detail), Spin Blocks & Pistons (GetPistonVelocity etc. — more screenshots needed).
