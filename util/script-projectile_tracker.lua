-- projectile tracker

-- additional variables
weapons = {}
weapons_buff = {}
weapons_averaged = {}
weapons_to_track = {6, 5, 7} -- ciws used to track ordinance
weapons_averaging = 5 -- amount of weapon history before averaging

-- time variable
deltaT = 0
currT = 0
prevT = 0
currS = 0
prevS = 0

-- global I variable
Game=nil
has_init = false
second_has_passed = false

-- ===============LOGICS STARTS===============
-- custom function that will either be called in the
-- every_tick or every_second function 
-- (you have to manually call it tho)
function main()
    local isCalibrating = log_track_weapon()
    if isCalibrating == 1 then
        return 1
    end

    local w1 = weapons_averaged[5]
    local w2 = weapons_averaged[7]
    local target, rng = paralax_to_range(w1.pos, w2.pos, w1.direction, w2.direction)
    if target then
        Game:Log(string.format("Est. target @ %.2f, %.2f, %.2f (range %.1f)", target.x, target.y, target.z, rng))
    end
end

function paralax_to_range(pos1, pos2, dir1, dir2)
    -- vector from obs1 to obs2
    local p21 = pos2 - pos1

    -- assume dir1, dir2 are normalized
    local d1d2 = Vector3.Dot(dir1, dir2)
    local denom = 1 - d1d2 * d1d2
    Game:Log("Denom: " .. denom)

    -- lines nearly parallel → unreliable
    -- if math.abs(denom) < 1e-6 then
    --     Game:Log("Lines are nearly parallel")
    --     return nil, nil
    -- end

    -- project p21 onto each direction
    local p21d1 = Vector3.Dot(p21, dir1)
    local p21d2 = Vector3.Dot(p21, dir2)

    -- distances along each line to closest approach
    local t1 = (p21d1 - p21d2 * d1d2) / denom
    local t2 = (p21d1 * d1d2 - p21d2) / denom

    -- closest points on each LOS
    local closest1 = pos1 + dir1 * t1
    local closest2 = pos2 + dir2 * t2

    -- midpoint as estimated target
    local target = (closest1 + closest2) / 2

    -- range from observer 1
    local range = (target - pos1).magnitude
    return target, range
end
-- ================LOGICS ENDS================


-- ===============UPDATE STARTS===============
function enumerate_weapons()
    for i = 0, Game:GetWeaponCount() - 1 do
        local weapon = Game:GetWeaponInfo(i)
        local temp = {
            id = i,
            type = weapon.WeaponType,
            slot_mask = binToStr(intToBin(weapon.WeaponSlotMask)),
            direction = weapon.CurrentDirection,
            pos = weapon.GlobalPosition,
        }
        weapons[i] = temp
    end
    -- push the weapons table in to the back of weapons_buff table
    table.insert(weapons_buff, 1, weapons)
    if(#weapons_buff > weapons_averaging) then
        table.remove(weapons_buff)
    end
end
function log_track_weapon()
    if #weapons_buff < weapons_averaging then
        Game:Log("Calibrating...")
        return 1
    end

    -- loop over weapons_to_track table
    for i, id in ipairs(weapons_to_track) do
        -- then average out between each entry in the weapons_buff table
        local avg_pos = Vector3(0, 0, 0)
        local avg_dir = Vector3(0, 0, 0)
        for j = 1, weapons_averaging do
            avg_pos = avg_pos + weapons_buff[j][id].pos
            avg_dir = avg_dir + weapons_buff[j][id].direction
        end
        avg_pos = avg_pos / weapons_averaging
        avg_dir = avg_dir / weapons_averaging

        weapons_averaged[id] = {
            id = id,
            type = weapons[id].type,
            slot_mask = weapons[id].slot_mask,
            direction = avg_dir,
            pos = avg_pos,
        }
        -- log the averaged weapon data
        Game:Log("Weapon " .. id .. " averaged direction: " .. weapons_averaged[id].direction.x .. ", " .. weapons_averaged[id].direction.y .. ", " .. weapons_averaged[id].direction.z)
        Game:Log("Weapon " .. id .. " averaged pos: " .. weapons_averaged[id].pos.x .. ", " .. weapons_averaged[id].pos.y .. ", " .. weapons_averaged[id].pos.z)
    end
    return 0
end
-- ================UPDATE ENDS================





-- function that will run [every tick]
function every_tick(I)
    enumerate_weapons()
    main()
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

-- function utill that will update time
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

-- the actuall Update function that will run every tick
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




-- ================UTIL STARTS================
-- some utility functions (we don't care about them
-- so we can put them at the bottom of the script)
function intToBin(int)
    local binary = {}
    while int > 0 do
        table.insert(binary, 1, int % 2)
        int = math.floor(int / 2)
    end
    return binary
end

function binToStr(binary)
    local str = ""
    for i = 1, #binary do
        str = str .. binary[i]
    end
    return str
end

function newOrdinance(id, pos, vel, time)
    local ordinance_obj = {
        id = 0,
        pos = {},
        vel = {},
        time = 0,
    }
    return ordinance_obj
end
-- =================UTIL ENDS=================