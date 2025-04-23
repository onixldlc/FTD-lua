sensor_pos = {}
sensor_vel = {}
vel_avg = {}
aim_pos = {}
time = {}

prev_time = 0
average_vel = 10

function Update(I)
    target = I:GetTargetInfo(2, 0)
    current_time = Mathf.Floor(I:GetTime())
    
    target_sensor_vel = target.Velocity
    target_aim_pos = target.AimPointPosition
    target_sensor_pos = target.Position
    
    I:ClearLogs()
    printVelSensPos(target_sensor_pos, I)
    printSensVel(target_sensor_vel, I)
    prev_time = current_time
    -- I:Log("Position" .. MessX1 .. MessY1 .. MessZ1)
end

function vecDiff(a, b)
    return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z}
end

function printVelSensPos(pos, I)
    if #sensor_pos < 2 then
        table.insert(sensor_pos, pos)
        table.insert(time, I:GetTime())
    end

    if #sensor_pos == 2 then
        -- Calculate time difference
        local dt = time[2] - time[1]

        -- Calculate position difference vector using vecDiff
        local pos_diff = vecDiff(sensor_pos[2], sensor_pos[1])

        -- Calculate velocity components
        local vx = pos_diff.x / dt
        local vy = pos_diff.y / dt
        local vz = pos_diff.z / dt

        table.insert(sensor_vel, {x = vx, y = vy, z = vz})
    end

    if #sensor_vel > average_vel then
        -- average the last 10 velocities
        local avg_vx = 0
        local avg_vy = 0
        local avg_vz = 0
        for i = 1, average_vel do
            avg_vx = avg_vx + sensor_vel[i].x
            avg_vy = avg_vy + sensor_vel[i].y
            avg_vz = avg_vz + sensor_vel[i].z
        end

        vel_avg = {x = avg_vx / average_vel, y = avg_vy / average_vel, z = avg_vz / average_vel}
        sensor_vel = {}
    end

    if vel_avg.z then
        local vec = Vector3(vel_avg.x, vel_avg.y, vel_avg.z)
        I:Log("Calculated velocity (last [".. average_vel .."] vel): " .. vel_avg.x .. " " .. vel_avg.y .. " " .. vel_avg.z)
        I:Log("Calculated speed (last [".. average_vel .."] vel): " .. vec.magnitude)

        if prev_time < current_time then
            I:LogToHud("speed (avg): " .. vec.magnitude)
        end

    end
    -- Log the calculated average velocity and speed

    if #sensor_pos > 1 then
        table.remove(sensor_pos, 1)
        table.remove(time, 1)
    end
end

function printSensVel(vel, I)
    local sen_vel_x = target_sensor_vel.x
    local sen_vel_y = target_sensor_vel.y
    local sen_vel_z = target_sensor_vel.z
    local vec = Vector3(sen_vel_x, sen_vel_y, sen_vel_z)

    I:Log("target-velocity (sensor): " .. sen_vel_x .. " " .. sen_vel_y .. " "  .. sen_vel_z)
    I:Log("speed (sensor): " .. vec.magnitude)
    if prev_time < current_time then
        I:LogToHud("speed (sensor): " .. vec.magnitude)
    end
end