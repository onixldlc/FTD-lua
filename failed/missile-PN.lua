--[[ 
Direct Intercept Guidance - Constant Velocity Prediction
By ChatGPT (2025-04-27)

Solves a real-time intercept equation each frame to aim the missile
where the target WILL be, assuming the target moves at constant velocity
and the missile flies at a roughly constant speed.

Features:
- Quadratic solution for intercept time
- Detailed debugging logs on the HUD
- Per-missile tracking

Usage:
1) Attach this script in a Lua block that controls your missiles.
2) Ensure no other guidance modules conflict (e.g. remove IR, Beam Rider).
3) Fire missiles at a moving target. The missile should "lead" 
   the target if a valid intercept solution exists.
4) Tweak or extend if your target accelerates (this code won't handle
   target acceleration perfectly).
]]

------------------------------------------------------------------------------------------------
-- HELPER: Vector math
------------------------------------------------------------------------------------------------

function Vec3Add(a, b)
    return Vector3(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vec3Sub(a, b)
    return Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
end

function Vec3Scale(a, s)
    return Vector3(a.x * s, a.y * s, a.z * s)
end

function Vec3Dot(a, b)
    return a.x*b.x + a.y*b.y + a.z*b.z
end

function Vec3Mag(a)
    return math.sqrt(a.x*a.x + a.y*a.y + a.z*a.z)
end

function Vec3Normalize(a)
    local mag = Vec3Mag(a)
    if mag < 1e-8 then
        return Vector3(0,0,0)
    end
    return Vector3(a.x/mag, a.y/mag, a.z/mag)
end

------------------------------------------------------------------------------------------------
-- SOLVE INTERCEPT TIME
-- Returns the SMALLEST POSITIVE t if it exists, otherwise nil
------------------------------------------------------------------------------------------------
function SolveInterceptTime(missilePos, missileSpeed, targetPos, targetVel)
    -- Relative position R = (targetPos - missilePos)
    local R = Vec3Sub(targetPos, missilePos)
    local Rx, Ry, Rz = R.x, R.y, R.z
    
    -- Target velocity vT
    local vTx, vTy, vTz = targetVel.x, targetVel.y, targetVel.z
    
    local vT2 = vTx*vTx + vTy*vTy + vTz*vTz  -- magnitude^2 of target velocity
    local vM2 = missileSpeed * missileSpeed
    
    -- Quadratic form: a t^2 + b t + c = 0
    -- a = (vT·vT) - vM^2
    local a = vT2 - vM2

    -- b = 2(R·vT)
    local b = 2.0 * (Rx*vTx + Ry*vTy + Rz*vTz)

    -- c = (R·R)
    local c = (Rx*Rx + Ry*Ry + Rz*Rz)

    -- If a is nearly 0, then it's effectively a linear equation: b t + c = 0
    if math.abs(a) < 1e-8 then
        -- linear: t = -c / b
        if math.abs(b) < 1e-8 then
            return nil -- no solution
        end
        local t_lin = -c / b
        if t_lin > 0 then
            return t_lin
        else
            return nil
        end
    end
    
    -- Discriminant: b^2 - 4ac
    local disc = b*b - 4*a*c
    if disc < 0 then
        return nil  -- No real solutions => no intercept
    end

    local sqrt_disc = math.sqrt(disc)
    local t1 = (-b + sqrt_disc) / (2*a)
    local t2 = (-b - sqrt_disc) / (2*a)

    -- We want the smallest positive root
    local t_min = nil
    if t1 > 0 and t2 > 0 then
        t_min = math.min(t1, t2)
    elseif t1 > 0 then
        t_min = t1
    elseif t2 > 0 then
        t_min = t2
    end

    return t_min
end

------------------------------------------------------------------------------------------------
-- MAIN UPDATE
-- 1) Get the target
-- 2) For each missile, solve intercept time => aim at predicted future position
------------------------------------------------------------------------------------------------

-- We'll store the last missile speed we detect, if needed for logs.
-- But in FtD, you might read from missileInfo.Velocity each tick.
function Update(I)
    -- We'll assume 40Hz updates, but we don't necessarily need dt for direct intercept.
    local dt = 1/40

    -- Get the "main" target from the first mainframe
    local targetInfo = I:GetTargetInfo(0, 0)
    if not targetInfo.Valid then
        I:LogToHud("No valid target!")
        return
    end
    
    local targetPos = targetInfo.AimPointPosition
    local targetVel = targetInfo.Velocity
    local targetSpeed = Vec3Mag(targetVel)

    I:LogToHud(string.format("Target Speed: %.1f m/s", targetSpeed))

    local transCount = I:GetLuaTransceiverCount()
    for t = 0, transCount-1 do
        local missileCount = I:GetLuaControlledMissileCount(t)
        for m = 0, missileCount-1 do
            local missileInfo = I:GetLuaControlledMissileInfo(t, m)
            
            local missilePos = missileInfo.Position
            local missileVel = missileInfo.Velocity
            local missileSpeed = Vec3Mag(missileVel)
            local missileId = missileInfo.Id

            if missileSpeed < 1.0 then
                -- If the missile is basically not moving, aim at target's current position
                I:SetLuaControlledMissileAimPoint(t, m, targetPos.x, targetPos.y, targetPos.z)
                I:LogToHud(string.format("Missile %d not moving; aiming at current target pos", missileId))
            else
                -- Solve intercept time
                local tIntercept = SolveInterceptTime(missilePos, missileSpeed, targetPos, targetVel)

                if tIntercept == nil then
                    -- No real positive solution => aim at current position
                    I:SetLuaControlledMissileAimPoint(t, m, targetPos.x, targetPos.y, targetPos.z)
                    I:LogToHud(string.format("Missile %d no intercept solution => aiming directly at target!", missileId))
                else
                    -- We have an intercept time => compute future position
                    local futureTarget = Vec3Add(targetPos, Vec3Scale(targetVel, tIntercept))

                    I:SetLuaControlledMissileAimPoint(t, m, futureTarget.x, futureTarget.y, futureTarget.z)
                    I:LogToHud(string.format(
                        "Missile %d intercept t=%.2fs => aiming at (%.1f, %.1f, %.1f)",
                        missileId, tIntercept, futureTarget.x, futureTarget.y, futureTarget.z
                    ))
                end
            end
        end
    end
end
