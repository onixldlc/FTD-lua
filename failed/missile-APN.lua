-- We'll store data for each missile AND for the target to measure velocity changes
lastTargetVel = Vector3(0,0,0)
lastUpdateTime = 0

-- Also store the last LOS direction for standard PN
lastLosByMissileId = {}

function Vector3Magnitude(v)
    return math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
end

function Vector3Subtract(a, b)
    return Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
end

function Vector3Add(a, b)
    return Vector3(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vector3Scale(a, s)
    return Vector3(a.x*s, a.y*s, a.z*s)
end

function Vector3Dot(a, b)
    return a.x*b.x + a.y*b.y + a.z*b.z
end

function Vector3Normalize(a)
    local mag = Vector3Magnitude(a)
    if mag < 1e-8 then
        return Vector3(0,0,0)
    end
    return Vector3(a.x/mag, a.y/mag, a.z/mag)
end

-- We'll do an approximate APN. 
--    PN gain = N
--    Acceleration gain = N_a
function ComputeAugmentedPNAimPoint(missilePos, missileVel, targetPos, targetVel, targetAccel, oldLosDir, dt, N, N_a)
    -- Current LOS vector
    local losVec = Vector3Subtract(targetPos, missilePos)
    local losDir = Vector3Normalize(losVec)
    
    -- If no oldLosDir, fallback to direct aim
    if oldLosDir == nil then
        return targetPos, losDir
    end
    
    -- LOS direction change
    local dLos = Vector3Subtract(losDir, oldLosDir)

    -- We'll approximate standard PN offset: offset_pn = N * (missileSpeed * magnitude(dLos)).
    local missileSpeed = Vector3Magnitude(missileVel)
    local speedFactor = missileSpeed
    
    -- For the acceleration part, we want the component of targetAccel perpendicular to LOS. 
    -- APN logic: offset_accel = N_a * (component of a_t perpendicular to LOS) * (dt * some scaling)
    -- We'll treat dt*some_scaling as "how far to lead in that direction."
    
    -- First, project targetAccel onto LOS to separate parallel vs. perpendicular
    local accelDotLOS = Vector3Dot(targetAccel, losDir)
    local accelParallel = Vector3Scale(losDir, accelDotLOS)
    local accelPerp = Vector3Subtract(targetAccel, accelParallel)

    -- The magnitude of that acceleration component
    local accelPerpMag = Vector3Magnitude(accelPerp)
    
    -- We'll turn that into an offset:
    -- offset_accel = N_a * accelPerp * dt^2, for instance (since accel ~ m/s^2 => position shift ~ a * t^2/2).
    -- We'll skip the 1/2 factor for simplicity or incorporate it into N_a if we want. 
    local offset_accel = Vector3Scale(accelPerp, N_a * dt*dt)

    -- Similarly, offset_pn is from the PN logic: 
    -- We approximate offset_pn = N * speedFactor * magnitude(dLos).
    local dLosMag = Vector3Magnitude(dLos)
    local offset_pn_mag = N * speedFactor * dLosMag
    
    -- We'll direct that offset in the direction of dLos itself (which is effectively the direction the LOS is rotating).
    -- dLos is a vector from oldLosDir to newLosDir, so let's normalize it if it's not zero. 
    local dLosDir = Vector3Normalize(dLos)
    local offset_pn = Vector3Scale(dLosDir, offset_pn_mag)

    -- Combined offset
    local offset = Vector3Add(offset_pn, offset_accel)

    -- Final aim point
    local aimPoint = Vector3Add(targetPos, offset)

    return aimPoint, losDir
end

function Update(I)
    local dt = 1.0 / 40.0  -- we assume 40Hz. If you want to measure real dt, do (I:GetTime() - lastUpdateTime)

    local targetInfo = I:GetTargetInfo(0,0)
    if not targetInfo.Valid then
        return
    end

    local targetPos = targetInfo.AimPointPosition
    local targetVel = targetInfo.Velocity

    -- Approximate target accel
    -- a_t = (v_t(k+1) - v_t(k)) / dt
    local targetAccel = Vector3Scale(Vector3Subtract(targetVel, lastTargetVel), 1.0/dt)
    
    -- Store for next frame
    lastTargetVel = targetVel
    lastUpdateTime = I:GetTime()

    -- Let's pick some "overkill" gains
    local N = 5.0    -- standard PN navigation constant, a bit on the high side
    local N_a = 2.0  -- how heavily we respond to target acceleration

    for transceiver = 0, I:GetLuaTransceiverCount() - 1 do
        local missileCount = I:GetLuaControlledMissileCount(transceiver)
        for m = 0, missileCount - 1 do
            local info = I:GetLuaControlledMissileInfo(transceiver, m)
            local missileId = info.Id

            local missilePos = info.Position
            local missileVel = info.Velocity
            local missileSpeed = Vector3Magnitude(missileVel)

            if missileSpeed < 1.0 then
                -- If basically not moving, just aim at target
                I:SetLuaControlledMissileAimPoint(transceiver, m, targetPos.x, targetPos.y, targetPos.z)
            else
                local oldLosDir = lastLosByMissileId[missileId]

                local aimPoint, newLosDir = ComputeAugmentedPNAimPoint(
                    missilePos, missileVel,
                    targetPos, targetVel, targetAccel,
                    oldLosDir,
                    dt,
                    N, N_a
                )

                if Vector3Magnitude(newLosDir) < 1e-8 then
                    aimPoint = targetPos
                end

                lastLosByMissileId[missileId] = newLosDir

                I:SetLuaControlledMissileAimPoint(transceiver, m, aimPoint.x, aimPoint.y, aimPoint.z)
            end
        end
    end
end
