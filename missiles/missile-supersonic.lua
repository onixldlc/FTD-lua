-- multistage-supersonic-missile
mainframe = 2
targets_lists = {}
missile_target_dict = {}


Game=nil
function Update(I)
    if Game == nil then
        Game = I
    end
    
    I:ClearLogs()
    -- constantly update the target lists!
    targets_lists = get_target_list()    

    for transceiver_id = 0, I:GetLuaTransceiverCount() - 1 do
        for missile_id = 0, I:GetLuaControlledMissileCount(transceiver_id) - 1 do
            
            -- check if the target is taken by another missile
            if missile_target_dict[missile_id] == nil then
                assign_missile_target(missile_id)
            end

            missile = I:GetLuaControlledMissileInfo(transceiver_id, missile_id)
            missile_pos = missile.Position
            missile_vel = missile.Velocity

            target_id = missile_target_dict[missile_id]
            target = I:GetTargetInfo(mainframe, target_id)
            target_pos = target.Position
            if missile_pos.y < 1000 then
                I:Log("Missile " .. missile_id .. ":")
                I:Log("Target ID: " .. target.Id)
                I:Log("Alt: " .. missile_pos.y)
                I:Log("Speed: " .. missile_vel.magnitude .. " m/s" .. " (" .. missile_vel.magnitude * 3.6 .. " km/h)")
                I:Log("Phase: initial height gain")
                goto continue
            elseif missile_pos.y < 2000 then
                I:Log("Missile " .. missile_id .. ":")
                I:Log("Target ID: " .. target.Id)
                I:Log("Alt: " .. missile_pos.y)
                I:Log("Speed: " .. missile_vel.magnitude .. " m/s" .. " (" .. missile_vel.magnitude * 3.6 .. " km/h)")
                I:Log("Phase: aquiring target")
                I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, target_pos.x, 5000, target_pos.z)
            elseif missile_pos.y < 2600 then
                I:Log("Missile " .. missile_id .. ":")
                I:Log("Target ID: " .. target.Id)
                I:Log("Alt: " .. missile_pos.y)
                I:Log("Speed: " .. missile_vel.magnitude .. " m/s" .. " (" .. missile_vel.magnitude * 3.6 .. " km/h)")
                I:Log("Phase: dropping payload")
                I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, target_pos.x, target_pos.y, target_pos.z)
            elseif missile_pos.y < 3000 then
                I:Log("Missile " .. missile_id .. ":")
                I:Log("Target ID: " .. target.Id)
                I:Log("Alt: " .. missile_pos.y)
                I:Log("Speed: " .. missile_vel.magnitude .. " m/s" .. " (" .. missile_vel.magnitude * 3.6 .. " km/h)")
                I:Log("Phase: self-destructing")
                I:DetonateLuaControlledMissile(transceiver_id, missile_id)
            end
            ::continue::
        end
    end
    --         missile = I:GetLuaControlledMissileInfo(transceiver_id, missile_id)
    --         missile_pos = missile.Position
    --         missile_vel = missile.Velocity
            
    --         if missile_pos.y < 1000 then
    --             I:Log("Missile " .. missile_id .. ":")
    --             I:Log("Target ID: " .. target.Id)
    --             I:Log("Alt: " .. missile_pos.y)
    --             I:Log("Speed: " .. missile_vel.magnitude)
    --             I:Log("Phase: initial height gain")
    --             goto continue
    --         elseif missile_pos.y < 2000 then
    --             I:Log("Missile " .. missile_id .. ":")
    --             I:Log("Target ID: " .. target.Id)
    --             I:Log("Alt: " .. missile_pos.y)
    --             I:Log("Speed: " .. missile_vel.magnitude)
    --             I:Log("Phase: aquiring target")
    --             I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, target_pos.x, target_pos.y, target_pos.z)
    --         end

            
    --         -- interceptPoint, t = solveForMissileIntercept(modified_target_pos, target_vel, target_accel, missile_pos, missile_vel)
    --         -- dist_to_point = Mathf.Abs(missile_pos.magnitude - interceptPoint.magnitude)

    --         -- if dist_to_point < 5 then
    --         --     I:Log("Missile " .. missile_id .. " self-destructing!")
    --         --     I:DetonateLuaControlledMissile(transceiver_id, missile_id)
    --         -- end

    --         -- if missile_pos.y > 2000 then
    --         --     I:Log("Missile " .. missile_id .. " deploying!")
    --         -- end

    --         -- I:Log("Missile " .. missile_id .. " Aim Point: " .. interceptPoint.x .. ", " .. interceptPoint.y .. ", " .. interceptPoint.z)
    --         -- I:Log("Missile " .. missile_id .. " Position: " .. missile_pos.x .. ", " .. missile_pos.y .. ", " .. missile_pos.z)
    --         -- I:Log("Missile " .. missile_id .. " Time to Intercept: " .. t)
    --         -- if missile_pos.y < 100 then
    --         --     I:Log("Missile " .. missile_id .. " is too low!")
    --         -- else
    --         --     I:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, interceptPoint.x, interceptPoint.y, interceptPoint.z)
    --         -- end
    --     end
    -- end
end

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

function assign_missile_target(missile_id)
    local fallback = nil
    for _, entry in ipairs(targets_lists) do
        if not entry.info.Valid then goto next_target end
        if fallback == nil then fallback = entry.index end
        -- check if the target is the player's choice, if so, assign it to the missile immediately
        if entry.info.PlayerTargetChoice then
            missile_target_dict[missile_id] = entry.index
            return
        end
        ::next_target::
    end
    -- fallback: assign first valid target
    missile_target_dict[missile_id] = fallback
end