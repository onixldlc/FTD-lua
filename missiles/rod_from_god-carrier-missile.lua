-- rod-of-god missile

sensor_pos = {}
sensor_vel = {}
time = {}
deltaT = 0

average_vel = 3
last_vel = Vector3(0, 0, 0)
target_accel = Vector3(0, 0, 0)
current_vel = Vector3(0, 0, 0)

Game=nil

function Update(I)
    is_missile_in_air = false
    count_down_start = false


    if Game == nil then
        Game = I
    end
    I:ClearLogs()
    target = I:GetTargetInfo(2, 0)
    target_pos = target.Position
    target_vel, target_accel = getAccurateTargetInfo(target_pos)
    target_speed = target_vel.magnitude

    modified_target_pos = Vector3(target_pos.x, target_pos.y + 2100, target_pos.z)
    modified_target_pos.y = modified_target_pos.y + ((target_speed / 10) * 150) 

    if target_vel.z == nil then
        I:Log("Callibrating target velocity...")
        return 1
    else
        I:Log("Target Aim Position: " .. target_aim_pos.x .. ", " .. target_aim_pos.y .. ", " .. target_aim_pos.z)
        I:Log("Target Position: " .. target_pos.x .. ", " .. target_pos.y .. ", " .. target_pos.z)
        I:Log("Target Velocity: " .. target_vel.x .. ", " .. target_vel.y .. ", " .. target_vel.z)
        I:Log("Target Speed: " .. Mathf.Sqrt(Vector3.Dot(target_vel, target_vel)) .. " m/s")
        I:Log("Target acceleration: " .. target_accel.x .. ", " .. target_accel.y .. ", " .. target_accel.z)
        I:Log("Tracking!")
    end

    for transceiver_id = 0, I:GetLuaTransceiverCount() - 1 do
        for missile_id = 0, I:GetLuaControlledMissileCount(transceiver_id) - 1 do
            missile = I:GetLuaControlledMissileInfo(transceiver_id, missile_id)
            missile_pos = missile.Position
            missile_vel = missile.Velocity

            interceptPoint, t = solveForMissileIntercept(modified_target_pos, target_vel, target_accel, missile_pos, missile_vel)
            dist_to_point = Mathf.Abs(missile_pos.magnitude - interceptPoint.magnitude)

            if dist_to_point < 5 then
                I:Log("Missile " .. missile_id .. " self-destructing!")
                I:DetonateLuaControlledMissile(transceiver_id, missile_id)
            end

            if missile_pos.y > 2000 then
                I:Log("Missile " .. missile_id .. " deploying!")
            end

            I:Log("Missile " .. missile_id .. " Aim Point: " .. interceptPoint.x .. ", " .. interceptPoint.y .. ", " .. interceptPoint.z)
            I:Log("Missile " .. missile_id .. " Position: " .. missile_pos.x .. ", " .. missile_pos.y .. ", " .. missile_pos.z)
            I:Log("Missile " .. missile_id .. " Time to Intercept: " .. t)
            if missile_pos.y < 100 then
                I:Log("Missile " .. missile_id .. " is too low!")
            else
                I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, interceptPoint.x, interceptPoint.y, interceptPoint.z)
            end
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

function getAcceleration(current_vel, last_vel)
    local dt = time[2] - time[1]
    local ax = (current_vel.x - last_vel.x) / dt
    local ay = (current_vel.y - last_vel.y) / dt
    local az = (current_vel.z - last_vel.z) / dt
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

function getAccurateTargetInfo(target_vel)
    if #sensor_pos < 2 then
        table.insert(sensor_pos, target_pos)
        table.insert(time, Game:GetTime())
    end

    if #sensor_pos == 2 then
        -- Calculate time difference
        deltaT = time[2] - time[1]

        -- Calculate position difference vector using vecDiff
        local pos_diff = vecDiff(sensor_pos[2], sensor_pos[1])

        -- Calculate velocity components
        local vx = pos_diff.x / deltaT
        local vy = pos_diff.y / deltaT
        local vz = pos_diff.z / deltaT

        table.insert(sensor_vel, {x = vx, y = vy, z = vz})

        if #sensor_vel > average_vel then
            current_vel = getAverageVelocity()
            target_accel = getAcceleration(current_vel, last_vel)
            last_vel = current_vel
        end
    end

    if #sensor_pos > 1 then
        table.remove(sensor_pos, 1)
        table.remove(time, 1)
    end
    return last_vel, target_accel
end

function vecDiff(a, b)
    return Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
end