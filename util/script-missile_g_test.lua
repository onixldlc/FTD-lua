-- Missile G-pull test
-- Launches missiles upward, then commands a 180° turn.
-- Measures actual max G from velocity change over time.
-- Paste into a craft with a missile launcher + lua transceiver.

test_altitude = 200        -- fly up to this height before commanding the turn
phase = {}                 -- keyed by missile Id: "climb" | "turn" | "measure" | "done"
missile_prev_vel = {}      -- previous tick velocity for each missile (m/s)
missile_max_g_measured = {} -- max G seen for each missile
missile_turn_start = {}    -- game time when turn was commanded

-- game time tracking
prev_game_time = nil
game_dt = 0.025

Game = nil
function Update(I)
    if Game == nil then Game = I end
    I:ClearLogs()

    -- track game dt
    local now = I:GetTimeSinceSpawn()
    if prev_game_time ~= nil then
        game_dt = now - prev_game_time
        if game_dt < 0.001 then game_dt = 0.001 end
    end
    prev_game_time = now

    for t = 0, I:GetLuaTransceiverCount() - 1 do
        for m = 0, I:GetLuaControlledMissileCount(t) - 1 do
            local info = I:GetLuaControlledMissileInfo(t, m)
            local uid = info.Id
            local pos = info.Position
            local vel = info.Velocity  -- m/s

            -- init
            if phase[uid] == nil then
                phase[uid] = "climb"
                missile_prev_vel[uid] = vel
                missile_max_g_measured[uid] = 0
            end

            -- ========== PHASE: CLIMB ==========
            if phase[uid] == "climb" then
                -- aim straight up
                I:SetLuaControlledMissileAimPoint(t, m, pos.x, pos.y + 5000, pos.z)
                I:Log("M" .. uid .. " [CLIMB] alt=" .. Mathf.Round(pos.y) .. " spd=" .. Mathf.Round(vel.magnitude) .. "m/s")

                if pos.y >= test_altitude then
                    phase[uid] = "turn"
                    missile_turn_start[uid] = now
                    I:Log("M" .. uid .. " reached altitude, commanding 180° turn!")
                    I:LogToHud("M" .. uid .. " 180° TURN at alt " .. Mathf.Round(pos.y))
                end

            -- ========== PHASE: TURN (aim straight down) ==========
            elseif phase[uid] == "turn" or phase[uid] == "measure" then
                -- aim straight down below the missile
                I:SetLuaControlledMissileAimPoint(t, m, pos.x, pos.y - 5000, pos.z)

                -- measure G from velocity change
                local prev_vel = missile_prev_vel[uid]
                local dv = vel - prev_vel                    -- delta velocity (m/s)
                local accel_mag = dv.magnitude / game_dt     -- m/s²
                local g_pull = accel_mag / 9.81              -- in G's

                if g_pull > missile_max_g_measured[uid] then
                    missile_max_g_measured[uid] = g_pull
                end

                phase[uid] = "measure"

                local elapsed = now - missile_turn_start[uid]
                local current_heading = vel.normalized
                -- check if missile is now pointing mostly downward (dot with down > 0.9)
                local down = Vector3(0, -1, 0)
                local heading_dot = Vector3.Dot(current_heading, down)

                I:Log("M" .. uid .. " [TURN] t=" .. Mathf.Round(elapsed, 2) .. "s"
                    .. " spd=" .. Mathf.Round(vel.magnitude) .. "m/s"
                    .. " G=" .. Mathf.Round(g_pull, 1)
                    .. " maxG=" .. Mathf.Round(missile_max_g_measured[uid], 1)
                    .. " heading_down=" .. Mathf.Round(heading_dot, 2))

                I:LogToHud("M" .. uid
                    .. " G=" .. Mathf.Round(g_pull, 1)
                    .. " max=" .. Mathf.Round(missile_max_g_measured[uid], 1)
                    .. " spd=" .. Mathf.Round(vel.magnitude))

                -- if the missile completed the 180° turn (now pointing mostly down)
                if heading_dot > 0.9 then
                    phase[uid] = "done"
                    I:Log("M" .. uid .. " TURN COMPLETE! Max G measured: " .. Mathf.Round(missile_max_g_measured[uid], 2))
                    I:LogToHud("M" .. uid .. " DONE: MAX G = " .. Mathf.Round(missile_max_g_measured[uid], 2))
                end

                -- timeout: detonate after 15 seconds of turning if not done
                if elapsed > 15 then
                    phase[uid] = "done"
                    I:Log("M" .. uid .. " TIMEOUT. Max G measured: " .. Mathf.Round(missile_max_g_measured[uid], 2))
                    I:LogToHud("M" .. uid .. " TIMEOUT: MAX G = " .. Mathf.Round(missile_max_g_measured[uid], 2))
                    I:DetonateLuaControlledMissile(t, m)
                end

            -- ========== PHASE: DONE ==========
            elseif phase[uid] == "done" then
                I:Log("M" .. uid .. " RESULT: Max G = " .. Mathf.Round(missile_max_g_measured[uid], 2))
                I:LogToHud("M" .. uid .. " MAX G = " .. Mathf.Round(missile_max_g_measured[uid], 2))
                -- let it fly or detonate
                I:DetonateLuaControlledMissile(t, m)
            end

            missile_prev_vel[uid] = vel
        end
    end
end
