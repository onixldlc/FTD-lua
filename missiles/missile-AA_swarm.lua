-- AA swarm missile — multi-target tracker with predictive guidance
mainframe = 2
max_missile = 48
proximity_distance = 1 --meter

target_list = {}
missiles_list = {}
actively_targeted_id = nil

-- velocity estimation settings
average_vel = 3

-- time tracking for HUD (no spam)
currS = 0
prevS = 0
second_has_passed = false

Game = nil
function Update(I)
    if Game == nil then
        Game = I
    end

    Game:ClearLogs()
    update_time()
    update_target_list()
    update_missile_list()
    update_missile_guidance()
end

-- ===============LOGICS STARTS===============
function update_time()
    currS = Mathf.Floor(Game:GetTime())
    if currS ~= prevS then
        second_has_passed = true
        prevS = currS
    else
        second_has_passed = false
    end
end

function update_target_list()
    target_count = Game:GetNumberOfTargets(mainframe)
    actively_targeted_id = nil
    if(target_count == 0) then
        Game:Log("No targets found")
        return
    else
        Game:Log("Found " .. target_count .. " targets")
    end

    for i = 0, target_count - 1 do
        target_info = Game:GetTargetInfo(mainframe, i)
        target_id = target_info.Id
        target_pos = target_info.Position

        -- preserve existing tracking state for this target, or create new
        existing = target_list[target_id]
        if existing == nil then
            existing = {
                sensor_pos = {},
                sensor_vel = {},
                sensor_time = {},
                last_vel = Vector3(0, 0, 0),
                current_vel = Vector3(0, 0, 0),
                accel = Vector3(0, 0, 0),
            }
        end

        -- update accurate velocity/accel for this target
        vel, accel = get_accurate_target_info(target_pos, existing)

        target_list[target_id] = {
            pos = target_pos,
            vel = vel,
            accel = accel,
            info = target_info,
            -- carry tracking state forward
            sensor_pos = existing.sensor_pos,
            sensor_vel = existing.sensor_vel,
            sensor_time = existing.sensor_time,
            last_vel = existing.last_vel,
            current_vel = existing.current_vel,
        }

        if(target_info.PlayerTargetChoice) then
            actively_targeted_id = target_id
        end
    end

    if actively_targeted_id ~= nil then
        Game:LogToHud("User selected target " .. actively_targeted_id)
    end
end

function update_missile_list()
    for transceiver_id = 0, Game:GetLuaTransceiverCount() - 1 do
        missile_count = Game:GetLuaControlledMissileCount(transceiver_id)
        for missile_id = 0, missile_count - 1 do
            missile_info = Game:GetLuaControlledMissileInfo(transceiver_id, missile_id)
            missile_uid = "M" .. missile_info.Id
            if(missiles_list[missile_uid] ~= nil) then
                goto continue
            else
                missile_target_id = actively_targeted_id
                data = { target = missile_target_id, info = missile_info }
                missiles_list[missile_uid] = data
            end
            ::continue::
        end
    end
end

function update_missile_guidance()
    for transceiver_id = 0, Game:GetLuaTransceiverCount() - 1 do
        for missile_id = 0, Game:GetLuaControlledMissileCount(transceiver_id) - 1 do
            missile_info = Game:GetLuaControlledMissileInfo(transceiver_id, missile_id)
            missile_uid = "M" .. missile_info.Id
            missile_data = missiles_list[missile_uid]

            target_id = missile_data.target
            if (target_list[target_id] == nil) then
                Game:DetonateLuaControlledMissile(transceiver_id, missile_id)
                goto continue
            end

            target_data = target_list[target_id]
            target_pos = target_data.pos
            target_vel = target_data.vel
            target_accel = target_data.accel

            missile_pos = missile_info.Position
            missile_vel = missile_info.Velocity

            intercept_point, t = solve_intercept(target_pos, target_vel, target_accel, missile_pos, missile_vel)
            check_proximity_fuze(missile_pos, target_pos, transceiver_id, missile_id)

            Game:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, intercept_point.x, intercept_point.y, intercept_point.z)
            ::continue::
        end
    end
end
-- ================LOGICS ENDS================


-- ===============GUIDANCE STARTS===============
function solve_intercept(target_pos, target_vel, target_accel, missile_pos, missile_vel)
    local vel_diff = missile_vel - target_vel
    local distance = missile_pos - target_pos

    local t = distance.magnitude / vel_diff.magnitude

    local intercept_point = target_pos + (target_vel * t)
    return intercept_point, t
end

function get_accurate_target_info(target_pos, state)
    if #state.sensor_pos < 2 then
        table.insert(state.sensor_pos, target_pos)
        table.insert(state.sensor_time, Game:GetTime())
    end

    if #state.sensor_pos == 2 then
        local dt = state.sensor_time[2] - state.sensor_time[1]
        if dt <= 0 then dt = 0.025 end  -- safety fallback

        local pos_diff = state.sensor_pos[2] - state.sensor_pos[1]

        local vx = pos_diff.x / dt
        local vy = pos_diff.y / dt
        local vz = pos_diff.z / dt

        table.insert(state.sensor_vel, { x = vx, y = vy, z = vz })

        if #state.sensor_vel > average_vel then
            state.current_vel = get_average_velocity(state)
            state.accel = get_acceleration(state.current_vel, state.last_vel, state.sensor_time)
            state.last_vel = state.current_vel
        end
    end

    if #state.sensor_pos > 1 then
        table.remove(state.sensor_pos, 1)
        table.remove(state.sensor_time, 1)
    end

    return state.last_vel, state.accel
end

function get_average_velocity(state)
    local avg_vx = 0
    local avg_vy = 0
    local avg_vz = 0
    for i = 1, average_vel do
        avg_vx = avg_vx + state.sensor_vel[i].x
        avg_vy = avg_vy + state.sensor_vel[i].y
        avg_vz = avg_vz + state.sensor_vel[i].z
    end
    local vel_vec = Vector3(avg_vx / average_vel, avg_vy / average_vel, avg_vz / average_vel)
    state.sensor_vel = {}
    return vel_vec
end

function get_acceleration(current_vel, last_vel, sensor_time)
    local dt = sensor_time[2] - sensor_time[1]
    if dt <= 0 then dt = 0.025 end
    local ax = (current_vel.x - last_vel.x) / dt
    local ay = (current_vel.y - last_vel.y) / dt
    local az = (current_vel.z - last_vel.z) / dt
    return Vector3(ax, ay, az)
end

function check_proximity_fuze(missile_pos, target_pos, transceiver_id, missile_id)
    local distance = (missile_pos - target_pos).magnitude
    if distance <= proximity_distance then
        Game:DetonateLuaControlledMissile(transceiver_id, missile_id)
    end
end
-- ===============GUIDANCE ENDS===============


-- ===============UTILS STARTS===============
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then s = s .. '[' .. k .. '] = ' end
            s = s .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
-- ===============UTILS ENDS===============
