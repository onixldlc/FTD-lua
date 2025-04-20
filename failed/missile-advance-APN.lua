--------------------------------------------------------------------------------
-- AUGMENTED PROPORTIONAL NAVIGATION SCRIPT
-- With Measurement Mode for auto-tuning of N and N_a
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- USER TUNABLES
--------------------------------------------------------------------------------
local MEASUREMENT_MODE  = true        -- Set true to measure your missile's turn rate, then compute N, N_a
local TURN_ANGLE        = math.rad(90)-- Angle to measure (radians)
local WARMUP_TIME       = 1.0         -- Let the missile accelerate for this many seconds
local TIMEOUT_TIME      = 15.0        -- Abort measurement if not done by then
local FALLBACK_N        = 3.0         -- If we haven't measured yet, fallback PN
local FALLBACK_NA       = 1.0         -- If we haven't measured yet, fallback N_a

-- In normal (non-measure) mode, we do "augmented PN" with the measured or fallback values
-- For the example, we'll just aim at a 'dummy' target. Replace with your real target logic.

--------------------------------------------------------------------------------
-- SCRIPT STATE
--------------------------------------------------------------------------------

-- Data for measurement
local measuringMissileId      = nil
local measurementStartVector  = nil
local measurementStartedTime  = 0
local measurementDone         = false
local measurementLogDone      = false

local measuredTurnRateDegSec  = nil -- e.g. 20 deg/s
local measuredSpeed           = nil -- e.g. 120 m/s

-- Gains we compute after measurement
local measuredN               = nil
local measuredNa              = nil

-- We'll store each missile's last LOS direction for the "PN" portion
local lastLosDirByMissileId   = {}

-- We'll also store the target's velocity from the previous frame to guess acceleration
local lastTargetVel = Vector3(0,0,0)
local lastUpdateTime = 0

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS: Vector Ops
--------------------------------------------------------------------------------
function Vec3Mag(v)
  return math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
end

function Vec3Dot(a, b)
  return a.x*b.x + a.y*b.y + a.z*b.z
end

function Vec3Sub(a, b)
  return Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
end

function Vec3Add(a, b)
  return Vector3(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vec3Scale(a, s)
  return Vector3(a.x*s, a.y*s, a.z*s)
end

function Vec3Normalize(a)
  local mag = Vec3Mag(a)
  if mag < 1e-8 then
    return Vector3(0,0,0)
  end
  return Vector3(a.x/mag, a.y/mag, a.z/mag)
end

--------------------------------------------------------------------------------
-- MEASUREMENT MODE LOGIC
--------------------------------------------------------------------------------
-- We:
--  1) Let missile warm up WARMUP_TIME
--  2) Command a big turn (e.g. behind itself)
--  3) Once we pass TURN_ANGLE, we measure average turn rate => deg/s
--  4) We store final speed => e.g. 120 m/s
--  5) Then we compute suggested N, N_a
--------------------------------------------------------------------------------
function MeasurementModeUpdate(I, transceiver, missileIndex, missileInfo)
  local missileId = missileInfo.Id
  local currentTime = missileInfo.TimeSinceLaunch

  if measuringMissileId == nil then
    -- We haven't locked on a missile yet
    measuringMissileId = missileId
    measurementDone = false
    measurementStartedTime = 0
    measurementStartVector = nil
    I:LogToHud("APN Measurement: using missile " .. missileId .. " for measurement.")
  end

  if missileId ~= measuringMissileId then
    -- Another missile => we blow it up to keep the test clean
    I:DetonateLuaControlledMissile(transceiver, missileIndex)
    return
  end

  if measurementDone then
    -- We are done measuring => blow up or let it fly
    I:DetonateLuaControlledMissile(transceiver, missileIndex)
    return
  end

  local speed = Vec3Mag(missileInfo.Velocity)
  if currentTime < WARMUP_TIME then
    -- Let the missile accelerate
    -- Just aim it somewhere "up"
    I:SetLuaControlledMissileAimPoint(transceiver, missileIndex,
      missileInfo.Position.x + 999999,
      missileInfo.Position.y + 999999,
      missileInfo.Position.z + 999999)
    I:LogToHud(string.format("Warming up missile %d (%.2fs / %.2fs)",
      missileId, currentTime, WARMUP_TIME))
    return
  end

  if measurementStartVector == nil then
    -- Start measuring turn now
    measurementStartVector = Vec3Normalize(missileInfo.Velocity)
    measurementStartedTime = currentTime
    I:LogToHud(string.format("Starting turn test, speed=%.1f m/s", speed))
    -- Command the missile to turn ~180° by aiming behind
    local behind = Vec3Sub(missileInfo.Position, measurementStartVector)
    I:SetLuaControlledMissileAimPoint(transceiver, missileIndex,
      behind.x, behind.y, behind.z)
    return
  end

  -- We are in the middle of turning
  local angleSoFar = 0
  local velNorm = Vec3Normalize(missileInfo.Velocity)
  local dot = Vec3Dot(velNorm, measurementStartVector)
  -- Sometimes dot can be slightly > 1 or < -1 from float errors => clamp it
  if dot > 1 then dot = 1 elseif dot < -1 then dot = -1 end
  angleSoFar = math.acos(dot)

  if angleSoFar >= TURN_ANGLE then
    -- done
    local turnTime = currentTime - measurementStartedTime
    local degTurn = math.deg(TURN_ANGLE)
    local turnRate = degTurn / turnTime  -- deg/s
    measuredTurnRateDegSec = turnRate
    measuredSpeed = speed

    measurementDone = true
    I:LogToHud(string.format("Measurement done: turned %.1f° in %.2fs => %.1f deg/s, final speed=%.1f",
      degTurn, turnTime, turnRate, speed))

    -- Blow up the missile so it won't keep messing around
    I:DetonateLuaControlledMissile(transceiver, missileIndex)
  else
    -- still turning...
    local turnTimeSoFar = currentTime - measurementStartedTime
    I:LogToHud(string.format("Measuring turn: angle=%.1f° / %.1f°, time=%.2fs",
      math.deg(angleSoFar), math.deg(TURN_ANGLE), turnTimeSoFar))
  end

  if (currentTime - measurementStartedTime) > TIMEOUT_TIME then
    I:LogToHud("Measurement TIMEOUT - aborting!")
    measurementDone = true
    I:DetonateLuaControlledMissile(transceiver, missileIndex)
  end
end

--------------------------------------------------------------------------------
-- AUTO-COMPUTE N, N_a
--------------------------------------------------------------------------------
-- We'll do a naive approach:
--   N  = 2 + 0.1 * (turnRateDegSec), 
--   N_a= 0.5 * N
-- Maybe also factor speed. Tweak to your liking.
--------------------------------------------------------------------------------
function ComputeAugmentedPNGains(turnRateDegSec, speed)
  -- For a 20 deg/s missile => N = 4, N_a = 2
  local base   = 2.0
  local scale  = 0.1
  local Ncalc  = base + (turnRateDegSec * scale)

  -- If super high speed, reduce the base a bit to avoid overshoot
  if speed > 120 then
    Ncalc = Ncalc - 0.5
  end

  if Ncalc < 2.0 then
    Ncalc = 2.0
  end

  -- For N_a, let's do half of N as a guess
  local Na = 0.5 * Ncalc

  return Ncalc, Na
end

--------------------------------------------------------------------------------
-- AUGMENTED PN LOGIC (Normal Mode)
--------------------------------------------------------------------------------
-- We'll track the target each frame, estimate target acceleration => do APN
--------------------------------------------------------------------------------
function ComputeAugmentedPNAimPoint(missilePos, missileVel,
                                    targetPos, targetVel, targetAccel,
                                    oldLosDir,
                                    dt, N, N_a)

  -- 1) Basic PN offset from line-of-sight rotation
  local losVec = Vec3Sub(targetPos, missilePos)
  local losDir = Vec3Normalize(losVec)

  if oldLosDir == nil then
    -- no old LOS => just aim direct
    return targetPos, losDir
  end

  local dLos = Vec3Sub(losDir, oldLosDir)
  local dLosMag = Vec3Mag(dLos)
  local dLosDir = Vec3Normalize(dLos)

  local missileSpeed = Vec3Mag(missileVel)

  -- PN offset
  local offsetPNMag = N * missileSpeed * dLosMag
  local offsetPN    = Vec3Scale(dLosDir, offsetPNMag)

  -- 2) Acceleration offset: we want the target's accel **perpendicular** to LOS
  --   offset_accel ~ N_a * (a_t_perp) * (dt^2) (heuristic)
  
  -- project targetAccel onto LOS
  local accelDotLOS  = Vec3Dot(targetAccel, losDir)
  local accelParallel= Vec3Scale(losDir, accelDotLOS)
  local accelPerp    = Vec3Sub(targetAccel, accelParallel)

  -- scale for dt^2 => "pos shift" ~ a * t^2
  local offsetAccel  = Vec3Scale(accelPerp, N_a * dt * dt)

  -- combined offset
  local offset = Vec3Add(offsetPN, offsetAccel)

  local aimPoint = Vec3Add(targetPos, offset)
  return aimPoint, losDir
end

--------------------------------------------------------------------------------
-- MAIN UPDATE
--------------------------------------------------------------------------------
function Update(I)
  local dt = 1.0 / 40.0  -- If you want real dt: I:GetTime() - lastUpdateTime
  local timeNow = I:GetTime()

  -- For demonstration, we'll pretend there's 1 main "target info"
  local targetInfo = I:GetTargetInfo(0,0)
  if not targetInfo.Valid then
    -- We'll just define a dummy target if none is valid
    targetInfo = {
      Position         = Vector3(999999,999999,999999),
      Velocity         = Vector3(0,0,0),
      AimPointPosition = Vector3(999999,999999,999999),
    }
  end

  -- estimate target acceleration
  local targetVel     = targetInfo.Velocity
  local targetAccel   = Vec3Scale(Vec3Sub(targetVel, lastTargetVel), 1.0/dt)
  lastTargetVel       = targetVel
  lastUpdateTime      = timeNow

  local transCount = I:GetLuaTransceiverCount()
  for t = 0, transCount-1 do
    local missileCount = I:GetLuaControlledMissileCount(t)
    for m = 0, missileCount-1 do
      local missileInfo = I:GetLuaControlledMissileInfo(t, m)

      if MEASUREMENT_MODE and not measurementDone then
        -- We'll do the turn test
        MeasurementModeUpdate(I, t, m, missileInfo)
      else
        -- Normal Augmented PN
        -- If measurement is done, we might have measuredN, measuredNa
        -- If not, fallback
        local N_use  = measuredN  or FALLBACK_N
        local Na_use = measuredNa or FALLBACK_NA

        -- We'll just aim at the target's AimPoint.  In real usage,
        -- you'd do your normal target selection or sea-skimming, etc.
        local targetPos = targetInfo.AimPointPosition

        local oldLosDir = lastLosDirByMissileId[missileInfo.Id]
        local aimPoint, newLosDir = ComputeAugmentedPNAimPoint(
          missileInfo.Position,
          missileInfo.Velocity,
          targetPos,
          targetVel,
          targetAccel,
          oldLosDir,
          dt,
          N_use,
          Na_use
        )

        if Vec3Mag(newLosDir) < 1e-8 then
          -- fallback
          aimPoint = targetPos
        end
        lastLosDirByMissileId[missileInfo.Id] = newLosDir

        I:SetLuaControlledMissileAimPoint(t, m, aimPoint.x, aimPoint.y, aimPoint.z)
      end
    end
  end

  -- If measurement is done and we haven't computed/logged the final gains, do so
  if MEASUREMENT_MODE and measurementDone and not measurementLogDone and measuredTurnRateDegSec ~= nil then
    -- We'll guess N, N_a
    local N_calc, Na_calc = ComputeAugmentedPNGains(measuredTurnRateDegSec, measuredSpeed)
    measuredN  = N_calc
    measuredNa = Na_calc

    I:LogToHud(string.format("APN Gains: N=%.2f, N_a=%.2f (turnRate=%.1f deg/s, speed=%.1f m/s)",
      measuredN, measuredNa, measuredTurnRateDegSec, measuredSpeed))

    measurementLogDone = true
  end
end
