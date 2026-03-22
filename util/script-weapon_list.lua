-- weapon_list: Lists all weapons on the craft (hull + subconstructs)

-- time variable
deltaT = 0
currT = 0
prevT = 0
currS = 0
prevS = 0

-- global I variable
Game = nil
has_init = false
second_has_passed = false

-- ===============CUSTOM STARTS===============

function list_hull_weapons(I)
    local count = I:GetWeaponCount()
    I:Log("=== HULL WEAPONS (" .. count .. ") ===")
    for w = 0, count - 1 do
        local info = I:GetWeaponInfo(w)
        if info.Valid then
            local pos = info.LocalPosition
            local dir = info.CurrentDirection
            I:Log(string.format("  [%d] type:%d | pos:(%.1f, %.1f, %.1f) | speed:%.0f | dir:(%.2f, %.2f, %.2f)",
                w, info.WeaponType,
                pos.x, pos.y, pos.z, info.Speed,
                dir.x, dir.y, dir.z))
        end
    end
end

function list_subconstruct_weapons(I)
    local sc_count = I:GetAllSubconstructsCount()
    I:Log("=== SUBCONSTRUCTS (" .. sc_count .. ") ===")
    for s = 0, sc_count - 1 do
        local sc_id = I:GetSubConstructIdentifier(s)
        local sc_info = I:GetSubConstructInfo(sc_id)
        local is_turret = I:IsTurret(sc_id)
        local is_spin = I:IsSpinBlock(sc_id)
        local is_piston = I:IsPiston(sc_id)
        local alive = I:IsAlive(sc_id)

        local sc_type = "Other"
        if is_turret then sc_type = "Turret"
        elseif is_spin then sc_type = "SpinBlock"
        elseif is_piston then sc_type = "Piston"
        end

        I:Log(string.format("  SC[%d] id:%d type:%s alive:%s",
            s, sc_id, sc_type, tostring(alive)))

        -- list weapons on this subconstruct
        local wcount = I:GetWeaponCountOnSubConstruct(sc_id)
        if wcount > 0 then
            I:Log("    Weapons on SC " .. sc_id .. ": " .. wcount)
            for w = 0, wcount - 1 do
                local info = I:GetWeaponInfoOnSubConstruct(sc_id, w)
                if info.Valid then
                    local pos = info.LocalPosition
                    local dir = info.CurrentDirection
                    I:Log(string.format("      [%d] type:%d | pos:(%.1f, %.1f, %.1f) | speed:%.0f | dir:(%.2f, %.2f, %.2f)",
                        w, info.WeaponType,
                        pos.x, pos.y, pos.z, info.Speed,
                        dir.x, dir.y, dir.z))
                end
            end
        end
    end
end

function list_friendlies(I)
    local count = I:GetFriendlyCount()
    I:Log("=== FRIENDLIES (" .. count .. ") ===")
    for f = 0, count - 1 do
        local info = I:GetFriendlyInfo(f)
        if info.Valid then
            I:Log(string.format("  [%d] %s | id:%d | hp:%.0f%% | pos:(%.0f, %.0f, %.0f)",
                f, info.BlueprintName, info.Id,
                info.HealthFraction * 100,
                info.ReferencePosition.x, info.ReferencePosition.y, info.ReferencePosition.z))
        end
    end
end

function list_fleet(I)
    local fleet = I.Fleet
    if fleet then
        I:Log("=== FLEET: " .. fleet.Name .. " (id:" .. fleet.ID .. ") ===")
        I:Log("  Ship index in fleet: " .. I.FleetIndex)
        I:Log("  Is flagship: " .. tostring(I.IsFlagship))
        if fleet.Members then
            local count = #fleet.Members
            I:Log("  Members count: " .. count)
            -- LuaArray from FTD: try both 0-based and 1-based to see which works
            for i = 0, count do
                local ok, member = pcall(function() return fleet.Members[i] end)
                if ok and member and member.Valid then
                    I:Log(string.format("  Member[%d] %s | id:%d | hp:%.0f%%",
                        i, member.BlueprintName, member.Id, member.HealthFraction * 100))
                end
            end
        end
    end
end

-- ================CUSTOM ENDS================


-- function that will run [every tick]
function every_tick(I)
    list_hull_weapons(I)
    list_subconstruct_weapons(I)
    list_friendlies(I)
    list_fleet(I)
    I:LogToHud("Weapon list refreshed")
end

-- function that will run [every second]
function every_second(I)
end

-- function that will run [only once]
function init(I)
    if Game == nil then
        Game = I
    end
    has_init = true
end

-- function util that will update time
function update_deltaT(I)
    currT = I:GetTime()
    currS = Mathf.Floor(currT)

    deltaT = currT - prevT
    prevT = currT

    if currS == prevS then
        second_has_passed = false
    else
        second_has_passed = true
        prevS = currS
    end
end

-- the actual Update function that will run every tick
function Update(I)
    -- initialization
    if has_init == false then
        init(I)
    end

    -- clean up before anything runs
    I:ClearLogs()

    -- functions to run
    update_deltaT(I)
    every_tick(I)
    if(second_has_passed) then
        every_second(I)
    end
end
