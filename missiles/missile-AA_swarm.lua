-- AA swarm missile — multi-target tracker with predictive guidance
-- target prediction uses velocity rotation (turn rate) instead of accel
-- missile flight time accounts for its own turn arc
mainframe = 2
max_missile = 48
proximity_distance = 5 --meter
terminal_phase_distance = 100 --meter
terminal_guidance_distance = 500  -- meters — switch from velocity-only to turn-rate guidance

-- missile turn capability — tune to your missile design
missile_max_g = 500         -- max lateral G your missile can pull
                           -- typical small missile: 15-25G, large: 8-15G
intercept_iterations = 4   -- solver iterations (more = more accurate, costs CPU)
max_predict_time = 30      -- max seconds to predict ahead


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
                -- smoothed velocity tracking (position deltas)
                sensor_pos = {},
                sensor_vel = {},
                sensor_time = {},
                last_vel = Vector3(0, 0, 0),
                current_vel = Vector3(0, 0, 0),
                -- turn rate tracking (from smoothed velocity)
                prev_smooth_vel = nil,
                prev_smooth_time = nil,
                turn_rate = 0,
                turn_axis = Vector3(0, 1, 0),
            }
        end

        -- get smoothed velocity from position deltas (the good one)
        smooth_vel = get_accurate_target_velocity(target_pos, existing)

        -- derive turn rate from the smoothed velocity (not the noisy API one)
        update_target_turn_rate(smooth_vel, existing)

        target_list[target_id] = {
            pos = target_pos,
            vel = smooth_vel,               -- smoothed, m/s
            turn_rate = existing.turn_rate,  -- rad/s
            turn_axis = existing.turn_axis,  -- rotation axis
            info = target_info,
            -- carry tracking state forward
            sensor_pos = existing.sensor_pos,
            sensor_vel = existing.sensor_vel,
            sensor_time = existing.sensor_time,
            last_vel = existing.last_vel,
            current_vel = existing.current_vel,
            prev_smooth_vel = existing.prev_smooth_vel,
            prev_smooth_time = existing.prev_smooth_time,
            turn_rate = existing.turn_rate,
            turn_axis = existing.turn_axis,
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
            target_turn_rate = target_data.turn_rate
            target_turn_axis = target_data.turn_axis

            missile_pos = missile_info.Position
            missile_vel = missile_info.Velocity

            local distance = (missile_pos - target_pos).magnitude

            if distance <= proximity_distance then
                Game:DetonateLuaControlledMissile(transceiver_id, missile_id)
                goto continue
            end

            local intercept_point = nil
            local t = 0

            if distance <= terminal_guidance_distance then
                -- TERMINAL: turn-rate prediction — accurate against evasive targets
                intercept_point, t = solve_intercept_turnrate(
                    target_pos, target_vel, target_turn_rate, target_turn_axis,
                    missile_pos, missile_vel)
            else
                -- CRUISE: velocity-only lead — stable, tight grouping at range
                intercept_point, t = solve_intercept_velocity(
                    target_pos, target_vel,
                    missile_pos, missile_vel)
            end

            Game:SetLuaControlledMissileAimPoint(transceiver_id, missile_id,
                intercept_point.x, intercept_point.y, intercept_point.z)
            ::continue::
        end
    end
end
-- ================LOGICS ENDS================


-- ===============GUIDANCE STARTS===============

-- CRUISE guidance: velocity-only lead
-- simple, stable, tight grouping — used at long range
function solve_intercept_velocity(target_pos, target_vel, missile_pos, missile_vel)
    local missile_speed = missile_vel.magnitude
    if missile_speed < 1 then missile_speed = 1 end

    local dist = (target_pos - missile_pos).magnitude
    local t = dist / missile_speed
    if t > max_predict_time then t = max_predict_time end

    local intercept_point = target_pos
    for i = 1, intercept_iterations do
        intercept_point = target_pos + (target_vel * t)
        t = estimate_flight_time(missile_pos, missile_vel, intercept_point, missile_speed, missile_max_g)
        if t > max_predict_time then t = max_predict_time end
    end

    return intercept_point, t
end

-- TERMINAL guidance: turn-rate prediction
-- accounts for target maneuvering + missile turn arc
-- used at close range where accuracy matters
function solve_intercept_turnrate(target_pos, target_vel, turn_rate, turn_axis, missile_pos, missile_vel)
    local missile_speed = missile_vel.magnitude
    if missile_speed < 1 then missile_speed = 1 end

    -- initial guess: straight-line time
    local dist = (target_pos - missile_pos).magnitude
    local t = dist / missile_speed
    if t > max_predict_time then t = max_predict_time end

    local intercept_point = target_pos
    for i = 1, intercept_iterations do
        -- predict target position by rotating its velocity over time
        intercept_point = predict_target_pos(target_pos, target_vel, turn_rate, turn_axis, t)

        -- compute how long the missile actually needs to reach that point
        -- accounting for the turn arc it must fly
        t = estimate_flight_time(missile_pos, missile_vel, intercept_point, missile_speed, missile_max_g)
        if t > max_predict_time then t = max_predict_time end
    end

    return intercept_point, t
end

-- predict where the target will be after t seconds,
-- assuming it continues turning at its current turn rate.
--
-- for turn_rate ≈ 0 (straight flight): this just returns pos + vel * t
-- for turn_rate > 0 (turning): the velocity rotates, tracing a circular arc
--
-- the math: integrate velocity that rotates at ω rad/s around turn_axis.
-- at time t the velocity has rotated by angle = ω * t.
-- displacement = (speed / ω) * [sin(ωt) * vel_dir + (1 - cos(ωt)) * cross_dir]
-- where cross_dir = turn_axis × vel_dir (perpendicular, toward center of turn)
function predict_target_pos(pos, vel, turn_rate, turn_axis, t)
    local speed = vel.magnitude
    if speed < 0.1 then
        return pos  -- target is basically stationary
    end

    -- if turn rate is negligible, just use straight-line prediction
    -- threshold: less than 0.5°/s — effectively straight flight
    if turn_rate < 0.00873 then
        return pos + (vel * t)
    end

    -- unit vectors: forward (velocity direction) and sideways (toward turn center)
    local vel_dir = vel * (1 / speed)
    local cross_dir = Vector3.Cross(turn_axis, vel_dir)

    -- angle rotated over time t
    local angle = turn_rate * t

    -- analytical integral of rotating velocity vector:
    -- displacement = (speed/ω) * [ sin(angle) * vel_dir + (1 - cos(angle)) * cross_dir ]
    local r = speed / turn_rate  -- turn radius
    local displacement = (vel_dir * Mathf.Sin(angle) + cross_dir * (1 - Mathf.Cos(angle))) * r

    return pos + displacement
end

-- estimate the ACTUAL flight time for the missile to reach a target point,
-- accounting for the curved arc the missile must fly to change heading.
--
-- turn radius: r = v² / (max_g * 9.81)
-- arc length for angle θ: arc = r * θ
-- total path = arc (turning) + straight line (after turn)
function estimate_flight_time(missile_pos, missile_vel, target_point, missile_speed, max_g)
    if missile_speed < 1 then
        return (target_point - missile_pos).magnitude
    end

    local to_target = target_point - missile_pos
    local straight_dist = to_target.magnitude
    if straight_dist < 1 then return 0 end

    -- direction missile is currently flying vs needs to fly
    local current_dir = missile_vel * (1 / missile_speed)
    local desired_dir = to_target * (1 / straight_dist)

    -- angle between current heading and desired heading
    local dot = Vector3.Dot(current_dir, desired_dir)
    if dot > 1 then dot = 1 end
    if dot < -1 then dot = -1 end
    local turn_angle = Mathf.Acos(dot)  -- radians

    -- turn radius at current speed: r = v² / (G * 9.81)
    local turn_radius = (missile_speed * missile_speed) / (max_g * 9.81)

    -- arc length the missile flies during the turn
    local arc_length = turn_radius * turn_angle

    -- the turn covers some of the straight-line distance (the chord)
    -- chord = 2*r*sin(θ/2)
    local chord = 2 * turn_radius * Mathf.Sin(turn_angle * 0.5)

    -- remaining straight-line distance after completing the turn
    local remaining = straight_dist - chord
    if remaining < 0 then remaining = 0 end

    -- total path = arc + remaining straight line
    local total_path = arc_length + remaining

    return total_path / missile_speed
end

-- smoothed velocity from position deltas — the proven accurate one
function get_accurate_target_velocity(target_pos, state)
    if #state.sensor_pos < 2 then
        table.insert(state.sensor_pos, target_pos)
        table.insert(state.sensor_time, Game:GetTime())
    end

    if #state.sensor_pos == 2 then
        local dt = state.sensor_time[2] - state.sensor_time[1]
        if dt <= 0 then dt = 0.025 end

        local pos_diff = state.sensor_pos[2] - state.sensor_pos[1]

        local vx = pos_diff.x / dt
        local vy = pos_diff.y / dt
        local vz = pos_diff.z / dt

        table.insert(state.sensor_vel, { x = vx, y = vy, z = vz })

        if #state.sensor_vel > average_vel then
            -- average the last N velocity samples
            local avg_vx = 0
            local avg_vy = 0
            local avg_vz = 0
            for i = 1, average_vel do
                avg_vx = avg_vx + state.sensor_vel[i].x
                avg_vy = avg_vy + state.sensor_vel[i].y
                avg_vz = avg_vz + state.sensor_vel[i].z
            end
            state.current_vel = Vector3(avg_vx / average_vel, avg_vy / average_vel, avg_vz / average_vel)
            state.last_vel = state.current_vel
            state.sensor_vel = {}
        end
    end

    if #state.sensor_pos > 1 then
        table.remove(state.sensor_pos, 1)
        table.remove(state.sensor_time, 1)
    end

    return state.last_vel
end

-- track how the SMOOTHED velocity vector rotates over time
-- this gives us turn rate (rad/s) and turn axis
function update_target_turn_rate(smooth_vel, state)
    local now = Game:GetTime()

    if state.prev_smooth_vel == nil then
        state.prev_smooth_vel = smooth_vel
        state.prev_smooth_time = now
        return
    end

    local dt = now - state.prev_smooth_time
    if dt < 0.001 then return end

    local prev_speed = state.prev_smooth_vel.magnitude
    local curr_speed = smooth_vel.magnitude

    -- need meaningful velocities to measure rotation
    if prev_speed < 1 or curr_speed < 1 then
        state.turn_rate = 0
        state.prev_smooth_vel = smooth_vel
        state.prev_smooth_time = now
        return
    end

    -- angle between previous and current smoothed velocity
    local prev_dir = state.prev_smooth_vel * (1 / prev_speed)
    local curr_dir = smooth_vel * (1 / curr_speed)

    local dot = Vector3.Dot(prev_dir, curr_dir)
    if dot > 1 then dot = 1 end
    if dot < -1 then dot = -1 end
    local angle = Mathf.Acos(dot)

    -- turn rate = angle / dt  (rad/s)
    local measured_rate = angle / dt

    -- smooth it: blend 70% old + 30% new to avoid jitter
    state.turn_rate = state.turn_rate * 0.7 + measured_rate * 0.3

    -- turn axis = cross product of prev_dir × curr_dir (normalized)
    local axis = Vector3.Cross(prev_dir, curr_dir)
    local axis_mag = axis.magnitude
    if axis_mag > 0.001 then
        state.turn_axis = axis * (1 / axis_mag)
    end

    state.prev_smooth_vel = smooth_vel
    state.prev_smooth_time = now
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
