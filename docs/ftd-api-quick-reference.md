# FTD Lua API — Quick Reference

> Compact method listing. See `ftd-api-reference.md` for full details.

---

## Logging
| Method | Returns |
|---|---|
| `I:Log(message)` | — |
| `I:ClearLogs()` | — |
| `I:LogToHud(message)` | — |

## Fleet Awareness
| Field / Method | Returns |
|---|---|
| `I.FleetIndex` | int |
| `I.Fleet` | FleetInfo |
| `I.IsFlagship` | bool |

**FleetInfo:** `ID` (int), `Name` (string), `Flagship` (FriendlyInfo), `Members` (FriendlyInfo[])

## Resources
| Field | Returns |
|---|---|
| `I.ResourceZones` | ResourceZoneInfo[] |
| `I.Resources` | ResourceInfo |

**ResourceZoneInfo:** `Id`, `Name`, `Position`, `Radius`, `Resources`
**ResourceInfo:** `CrystalTotal/Max`, `MetalTotal/Max`, `NaturalTotal/Max`, `OilTotal/Max`, `ScrapTotal/Max`

## AI
| Method | Returns |
|---|---|
| `I:GetAIMovementMode(index)` | string (`Off/Manual/Automatic/Fleet`) |
| `I:GetAIFiringMode(index)` | string (`Off/On`) |

## Propulsion
| Method | Returns |
|---|---|
| `I:TellAIThatWeAreTakingControl()` | — |
| `I:AddPropulsionRequest(type, drive)` | — |
| `I:SetPropulsionRequest(type, drive)` | — |
| `I:GetPropulsionRequest(type)` | float |
| `I:RequestComplexControllerStimulus(stim)` | — |
| `I:MoveFortress(direction)` | — |
| `I:RequestCustomAxis(axisName, drive)` | — |
| `I:GetCustomAxis(axisName)` | float |

**Propulsion types:** 0=Main, 1=Secondary, 2=Tertiary, 3=Roll, 4=Pitch, 5=Yaw, 6=Forwards, 7=Up, 8=Right, 9–13=A–E

## Target Info
| Method | Returns |
|---|---|
| `I:GetNumberOfMainframes()` | int |
| `I:GetNumberOfTargets(mainframeIndex)` | int |
| `I:GetTargetInfo(mainframeIndex, targetIndex)` | TargetInfo |
| `I:GetTargetPositionInfo(mainframeIndex, targetIndex)` | TargetPositionInfo |
| `I:GetTargetPositionInfoForPosition(mainframeIndex, x, y, z)` | TargetPositionInfo |

**TargetInfo:** `Valid`, `Priority`, `Score`, `AimPointPosition`, `Team`, `Protected`, `Position`, `Velocity`, `PlayerTargetChoice`, `Id`
**TargetPositionInfo:** `Valid`, `Azimuth`, `Elevation`, `ElevationForAltitudeComponentOnly`, `Range`, `Direction`, `GroundDistance`, `AltitudeAboveSeaLevel`, `Position`, `Velocity`

## Misc
| Method | Returns |
|---|---|
| `I:GetTerrainAltitudeForPosition(x, y, z)` | float |
| `I:GetTerrainAltitudeForLocalPosition(x, y, z)` | float |
| `I:GetGravityForAltitude(alt)` | Vector3 |
| `I:GetTime()` | float |
| `I:GetTimeSinceSpawn()` | float |
| `I:GetGameTime()` | float |
| `I:GetWindDirectionAndMagnitude()` | Vector3 |

## Self Awareness
| Method | Returns |
|---|---|
| `I:GetConstructPosition()` | Vector3 |
| `I:GetConstructForwardVector()` | Vector3 |
| `I:GetConstructRightVector()` | Vector3 |
| `I:GetConstructUpVector()` | Vector3 |
| `I:GetConstructMaxDimensions()` | Vector3 |
| `I:GetConstructMinDimensions()` | Vector3 |
| `I:GetConstructRoll()` | float (degrees) |
| `I:GetConstructPitch()` | float (degrees) |
| `I:GetConstructYaw()` | float (degrees) |
| `I:GetConstructCenterOfMass()` | Vector3 |
| `I:GetConstructLocalCenterOfMass()` | Vector3 |
| `I:GetAiPosition(mainframeIndex)` | Vector3 |
| `I:GetVelocityMagnitude()` | float (m/s) |
| `I:GetForwardsVelocityMagnitude()` | float (m/s) |
| `I:GetVelocityVector()` | Vector3 (m/s) |
| `I:GetVelocityVectorNormalized()` | Vector3 |
| `I:GetAngularVelocity()` | Vector3 (world) |
| `I:GetLocalAngularVelocity()` | Vector3 (x=pitch, y=yaw, z=roll) |
| `I:GetAmmoFraction()` | float (0–1) |
| `I:GetFuelFraction()` | float (0–1) |
| `I:GetSparesFraction()` | float (0–1) |
| `I:GetEnergyFraction()` | float (0–1) |
| `I:GetPowerFraction()` | float (0–1) |
| `I:GetElectricPowerFraction()` | float (0–1) |
| `I:GetHealthFraction()` | float (0–1) |
| `I:IsDocked()` | bool |
| `I:GetHealthFractionDifference(time)` | float (0–1) |
| `I:GetBlueprintName()` | string |
| `I:GetUniqueId()` | int |

## Weapons
| Method | Returns |
|---|---|
| `I:GetWeaponCount()` | int |
| `I:GetWeaponInfo(weaponIndex)` | WeaponInfo |
| `I:GetWeaponConstraints(weaponIndex)` | WeaponConstraints |
| `I:GetWeaponBlockInfo(weaponIndex)` | BlockInfo |
| `I:AimWeaponInDirection(weaponIndex, x, y, z, weaponSlot)` | int |
| `I:FireWeapon(weaponIndex, weaponSlot)` | bool |

**WeaponInfo:** `Valid`, `LocalPosition`, `GlobalPosition`, `LocalFirePoint`, `GlobalFirePoint`, `Speed`, `CurrentDirection`, `WeaponType`, `WeaponSlot`, `WeaponSlotMask`, `PlayerCurrentlyControllingIt`
**WeaponType enum:** 0=cannon, 1=missile, 2=laser, 3=harpoon, 4=turret, 5=missilecontrol, 6=fireControlComputer
**WeaponConstraints:** `Valid`, `MinAzimuth`, `MaxAzimuth`, `MinElevation`, `MaxElevation`, `FlipAzimuth`, `InParentConstructSpace`

### Weapons on SubConstructs
| Method | Returns |
|---|---|
| `I:GetWeaponCountOnSubConstruct(scId)` | int |
| `I:GetWeaponInfoOnSubConstruct(scId, weaponIndex)` | WeaponInfo |
| `I:GetWeaponConstraintsOnSubConstruct(scId, weaponIndex)` | WeaponConstraints |
| `I:GetWeaponBlockInfoOnSubConstruct(scId, weaponIndex)` | BlockInfo |
| `I:AimWeaponInDirectionOnSubConstruct(scId, weaponIndex, x, y, z, weaponSlot)` | int |
| `I:FireWeaponOnSubConstruct(scId, weaponIndex, weaponSlot)` | bool |

## Missile Warning
| Method | Returns |
|---|---|
| `I:GetNumberOfWarnings()` | int |
| `I:GetMissileWarning(missileIndex)` | MissileWarningInfo |

**MissileWarningInfo:** `Valid`, `Position`, `Velocity`, `Range`, `Azimuth`, `Elevation`, `TimeSinceLaunch`, `Id`

## Missile Guidance
| Method | Returns |
|---|---|
| `I:GetLuaTransceiverCount()` | int |
| `I:GetLuaControlledMissileCount(transceiverIndex)` | int |
| `I:GetLuaTransceiverInfo(transceiverIndex)` | BlockInfo |
| `I:GetLuaControlledMissileInfo(transceiverIndex, missileIndex)` | MissileWarningInfo |
| `I:SetLuaControlledMissileAimPoint(transceiverIndex, missileIndex, x, y, z)` | — |
| `I:DetonateLuaControlledMissile(transceiverIndex, missileIndex)` | — |
| `I:IsLuaControlledMissileAnInterceptor(transceiverIndex, missileIndex)` | bool |
| `I:SetLuaControlledMissileInterceptorTarget(transceiverIndex, missileIndex, targetIndex)` | — |
| `I:SetLuaControlledMissileInterceptorStandardGuidanceOnOff(transceiverIndex, missileIndex, onOff)` | — |

## Spin Blocks & Pistons
| Method | Returns |
|---|---|
| `I:SetSpinBlockSpeedFactor(scId, speedFactor)` | — |
| `I:SetSpinBlockPowerDrive(scId, drive)` | — |
| `I:SetSpinBlockRotationAngle(scId, angle)` | — |
| `I:SetSpinBlockContinuousSpeed(scId, speed)` | — |
| `I:SetSpinBlockInstaSpin(scId, magnitudeAndDirection)` | — |
| `I:GetPistonExtension(scId)` | float |

## SubConstructs
| Method | Returns |
|---|---|
| `I:GetAllSubconstructsCount()` | int |
| `I:GetSubConstructIdentifier(index)` | int |
| `I:GetSubconstructsChildrenCount(scId)` | int |
| `I:GetSubConstructChildIdentifier(scId, index)` | int |
| `I:GetParent(scId)` | int (0=main, -1=not found) |
| `I:IsTurret(scId)` | bool |
| `I:IsSpinBlock(scId)` | bool |
| `I:IsPiston(scId)` | bool |
| `I:IsAlive(scId)` | bool |
| `I:IsSubConstructOnHull(scId)` | bool |
| `I:GetSubConstructInfo(scId)` | BlockInfo |
| `I:GetSubConstructIdleRotation(scId)` | Quaternion |

## Friendlies
| Method | Returns |
|---|---|
| `I:GetFriendlyCount()` | int |
| `I:GetFriendlyInfo(index)` | FriendlyInfo |
| `I:GetFriendlyInfoById(Id)` | FriendlyInfo |

**FriendlyInfo:** `Valid`, `Rotation`, `ReferencePosition`, `PositiveSize`, `NegativeSize`, `CenterOfMass`, `Velocity`, `UpVector`, `RightVector`, `ForwardVector`, `HealthFraction`, `SparesFraction`, `AmmoFraction`, `FuelFraction`, `EnergyFraction`, `PowerFraction`, `ElectricPowerFraction`, `AxisAlignedBoundingBoxMinimum`, `AxisAlignedBoundingBoxMaximum`, `BlueprintName`, `Id`

## Libraries
- **Mathf** — `Mathf.Func()` (static, dot notation)
- **Vector3** — `Vector3(x,y,z)`, plus all Unity Vector3 methods
- **Quaternion** — Full Unity Quaternion API
