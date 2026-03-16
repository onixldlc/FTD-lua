-- multistage-supersonic-missile
mainframe = 2
booster_sep_min_time = 3  -- seconds after launch before booster is allowed to separate
targets_lists = {}
-- keyed by missile.Id, value = { target_index, stage }
missile_data = {}

-- velocity tracking (position-delta method from missile-AA)
sensor_pos = {}
sensor_vel = {}
sensor_time = {}
average_vel = 3
last_vel = Vector3(0, 0, 0)
target_accel = Vector3(0, 0, 0)
current_vel = Vector3(0, 0, 0)

-- time tracking for HUD (no spam)
currS = 0
prevS = 0
second_has_passed = false

Game=nil
function Update(I)
    if Game == nil then
        Game = I
    end
    
    I:ClearLogs()
    update_time()
    -- constantly update the target lists!
    targets_lists = get_target_list()
    -- clean up missile_data for missiles that no longer exist
    cleanup_missile_data()

    -- get primary target for velocity tracking (use first target for sensor)
    local primary_target = I:GetTargetInfo(mainframe, 0)
    if primary_target.Valid then
        target_vel_tracked, target_accel = getAccurateTargetInfo(primary_target.Position)
    end

    for transceiver_id = 0, I:GetLuaTransceiverCount() - 1 do
        for missile_id = 0, I:GetLuaControlledMissileCount(transceiver_id) - 1 do

            missile = I:GetLuaControlledMissileInfo(transceiver_id, missile_id)
            missile_uid = missile.Id
            missile_pos = missile.Position
            missile_vel = missile.Velocity

            -- first time we see this missile: figure out if it's a new launch or a separated stage
            -- high altitude + young TimeSinceLaunch = freshly separated payload = stage 2
            if missile_data[missile_uid] == nil then
                if missile_pos.y > 500 and missile.TimeSinceLaunch < 1 then
                    missile_data[missile_uid] = { target_index = assign_missile_target(), stage = 2 }
                else
                    missile_data[missile_uid] = { target_index = assign_missile_target(), stage = 1 }
                end
            end

            local data = missile_data[missile_uid]
            local stage = data.stage

            target = I:GetTargetInfo(mainframe, data.target_index)
            target_pos = target.Position

            if stage == 1 then goto stage1 end
            if stage == 2 then goto stage2 end
            if stage == 3 then goto stage3 end
            goto continue

            -- =============== STAGE 1: climb to altitude ===============
            ::stage1::
            if missile_pos.y < 1000 then
                I:Log("Alt: " .. missile_pos.y)
                I:Log("Speed(m/s): " .. missile_vel.magnitude .. " m/s")
                I:Log("Speed(km/h): " .. missile_vel.magnitude * 3.6 .. " km/h")
                I:Log("Phase: initial height gain")
                I:Log("Missile " .. missile_uid .. " [S1]:")
                if second_has_passed then
                    I:LogToHud("M" .. missile_uid .. " [S1] alt:" .. Mathf.Round(missile_pos.y) .. " spd:" .. Mathf.Round(missile_vel.magnitude) .. "m/s")
                end
                -- aim straight up above the missile so the booster climbs instead of chasing the target
                I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, missile_pos.x, 5000, missile_pos.z)
                goto continue
            end
            if missile_pos.y < 2000 then
                I:Log("Alt: " .. missile_pos.y)
                I:Log("Speed(m/s): " .. missile_vel.magnitude .. " m/s")
                I:Log("Speed(km/h): " .. missile_vel.magnitude * 3.6 .. " km/h")
                I:Log("Phase: acquiring target")
                I:Log("Missile " .. missile_uid .. " [S1]:")
                if second_has_passed then
                    I:LogToHud("M" .. missile_uid .. " [S1] alt:" .. Mathf.Round(missile_pos.y) .. " spd:" .. Mathf.Round(missile_vel.magnitude) .. "m/s")
                end
                I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, target_pos.x, 5000, target_pos.z)
                goto continue
            end
            if missile_pos.y < 2600 then
                I:Log("Alt: " .. missile_pos.y)
                I:Log("Speed(m/s): " .. missile_vel.magnitude .. " m/s")
                I:Log("Speed(km/h): " .. missile_vel.magnitude * 3.6 .. " km/h")
                I:Log("Phase: dropping payload")
                I:Log("Missile " .. missile_uid .. " [S1]:")
                if second_has_passed then
                    I:LogToHud("M" .. missile_uid .. " [S1] alt:" .. Mathf.Round(missile_pos.y) .. " spd:" .. Mathf.Round(missile_vel.magnitude) .. "m/s")
                end
                -- aim high above the target so the booster maintains altitude for clean separation
                I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, target_pos.x, 3000, target_pos.z)
                goto continue
            end
            -- above 2600: booster sep (only if missile has been flying long enough)
            if missile.TimeSinceLaunch < booster_sep_min_time then
                I:Log("Alt: " .. missile_pos.y)
                I:Log("Speed(m/s): " .. missile_vel.magnitude .. " m/s")
                I:Log("Phase: waiting for sep (" .. Mathf.Round(missile.TimeSinceLaunch, 1) .. "s / " .. booster_sep_min_time .. "s)")
                I:Log("Missile " .. missile_uid .. " [S1]:")
                -- keep the booster flying high toward the target area while waiting for separation
                I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, target_pos.x, 3000, target_pos.z)
                goto continue
            end
            I:Log("Phase: booster sep")
            I:Log("Missile " .. missile_uid .. " [S1]:")
            if second_has_passed then
                I:LogToHud("M" .. missile_uid .. " [S1] BOOSTER SEP")
            end
            missile_data[missile_uid] = nil
            I:DetonateLuaControlledMissile(transceiver_id, missile_id)
            goto continue

            -- =============== STAGE 2: supersonic dive ===============
            ::stage2::
            target_vel = target_vel_tracked
            intercept_pos, time_to_intercept = solveForMissileIntercept(target_pos, target_vel, target_accel, missile_pos, missile_vel)
            dist_to_target = vecDiff(missile_pos, target_pos).magnitude

            I:Log("Dist to target: " .. Mathf.Round(dist_to_target) .. "m")
            I:Log("ETA: " .. Mathf.Round(time_to_intercept, 1) .. "s")
            I:Log("Alt: " .. missile_pos.y)
            I:Log("Speed(m/s): " .. missile_vel.magnitude .. " m/s")
            I:Log("Speed(km/h): " .. missile_vel.magnitude * 3.6 .. " km/h")
            I:Log("Phase: supersonic dive")
            I:Log("Missile " .. missile_uid .. " [S2]:")
            if second_has_passed then
                I:LogToHud("M" .. missile_uid .. " [S2] alt:" .. Mathf.Round(missile_pos.y) .. " dist:" .. Mathf.Round(dist_to_target) .. "m spd:" .. Mathf.Round(missile_vel.magnitude) .. "m/s ETA:" .. Mathf.Round(time_to_intercept, 1) .. "s")
            end
            I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, intercept_pos.x, intercept_pos.y, intercept_pos.z)
            goto continue

            -- =============== STAGE 3: terminal ===============
            ::stage3::
            -- TODO: supersonic missile, aim directly at target with remote guidance, but do track the speed
            goto continue

            ::continue::
        end
    end
end

-- ===============UTILS STARTS===============

function update_time()
    currS = Mathf.Floor(Game:GetTime())
    if currS ~= prevS then
        second_has_passed = true
        prevS = currS
    else
        second_has_passed = false
    end
end

function cleanup_missile_data()
    -- build a set of all currently alive missile Ids
    local alive = {}
    for t = 0, Game:GetLuaTransceiverCount() - 1 do
        for m = 0, Game:GetLuaControlledMissileCount(t) - 1 do
            local info = Game:GetLuaControlledMissileInfo(t, m)
            alive[info.Id] = true
        end
    end
    -- remove stale entries
    for uid, _ in pairs(missile_data) do
        if not alive[uid] then
            missile_data[uid] = nil
        end
    end
end

function solveForMissileIntercept(target_pos, target_vel, target_accel, missile_pos, missile_vel)
    local vel_diff = vecDiff(missile_vel, target_vel)
    local distance = vecDiff(missile_pos, target_pos)

    local t = distance.magnitude / vel_diff.magnitude

    local interceptPoint = target_pos + (target_vel * t)
    return interceptPoint, t
end

function getAcceleration(cur_vel, prev_vel)
    local dt = sensor_time[2] - sensor_time[1]
    local ax = (cur_vel.x - prev_vel.x) / dt
    local ay = (cur_vel.y - prev_vel.y) / dt
    local az = (cur_vel.z - prev_vel.z) / dt
    return Vector3(ax, ay, az)
end

function getAverageVelocity()
    local avg_vx = 0
    local avg_vy = 0
    local avg_vz = 0
    for i = 1, average_vel do
        avg_vx = avg_vx + sensor_vel[i].x
        avg_vy = avg_vy + sensor_vel[i].y
        avg_vz = avg_vz + sensor_vel[i].z
    end
    vel_vec = Vector3(avg_vx / average_vel, avg_vy / average_vel, avg_vz / average_vel)
    sensor_vel = {}
    return vel_vec
end

function getAccurateTargetInfo(tgt_pos)
    if #sensor_pos < 2 then
        table.insert(sensor_pos, tgt_pos)
        table.insert(sensor_time, Game:GetTime())
    end

    if #sensor_pos == 2 then
        local dt = sensor_time[2] - sensor_time[1]
        local pos_diff = vecDiff(sensor_pos[2], sensor_pos[1])

        local vx = pos_diff.x / dt
        local vy = pos_diff.y / dt
        local vz = pos_diff.z / dt

        table.insert(sensor_vel, {x = vx, y = vy, z = vz})

        if #sensor_vel > average_vel then
            current_vel = getAverageVelocity()
            target_accel = getAcceleration(current_vel, last_vel)
            last_vel = current_vel
        end
    end

    if #sensor_pos > 1 then
        table.remove(sensor_pos, 1)
        table.remove(sensor_time, 1)
    end
    return last_vel, target_accel
end

function vecDiff(a, b)
    return Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
end

-- ================UTILS ENDS================

function get_target_list()
    target_count = Game:GetNumberOfTargets(mainframe)
    targets = {}
    for i = 0, target_count - 1 do
        target_info = Game:GetTargetInfo(mainframe, i)
        -- wrap in a plain Lua table so we can store the index alongside
        table.insert(targets, { index = i, info = target_info })
    end
    return targets
end

function assign_missile_target()
    -- pick player choice target, or fall back to first valid
    local fallback = nil
    for _, entry in ipairs(targets_lists) do
        if not entry.info.Valid then goto next_target end
        if fallback == nil then fallback = entry.index end
        if entry.info.PlayerTargetChoice then
            return entry.index
        end
        ::next_target::
    end
    return fallback
end