-- platform-laser position-tracker

-- additional variables
weapons = {}
weapons_buff = {}
weapons_averaged = {}
weapons_averaging = 5
weapons_master = {}
weapons_slave = {}

projectile_buff={}
projectile_history = 10
current_projectile_pos = Vector3(0,0,0)
active_projectile_pos = Vector3(0,0,0)

-- time variable
deltaT = 0
currT = 0
prevT = 0
currS = 0
prevS = 0
secnd = 0

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

    if #weapons_master < 2 then
        for i, weapon in ipairs(weapons) do
            Game:Log("")
            Game:Log(string.format("- type: %s", weapon.type))
            Game:Log(string.format("- slot_mask: %s", weapon.slot_mask))
            Game:Log(string.format("- position: x=%s, y=%s, z=%s", weapon.pos.x, weapon.pos.y, weapon.pos.z))
            Game:Log(string.format("- direction: %s, %s, %s", weapon.direction.x, weapon.direction.y, weapon.direction.z))
            Game:Log(string.format("Weapon %d:", weapon.id))
        end
        Game:Log("Listing weapons:")
        Game:Log("Not enough weapons to track")
        return 1
    end

    local w1 = weapons_averaged[weapons_master[1]]
    local w2 = weapons_averaged[weapons_master[2]]
    local target, rng = paralax_to_range(w1.pos, w2.pos, w1.direction, w2.direction)
    if target then
        Game:Log(string.format("Est. target @ %.2f, %.2f, %.2f (range %.1f)", target.x, target.y, target.z, rng))
        active_projectile_pos = target
        for i, id in ipairs(weapons_slave) do
            local weapon = weapons[id]
            instruct_slave(weapon, target, 0)
        end
    end
    
end

function position_to_direction(pos1, pos2)
    local direction = pos2 - pos1
    return direction
end

function instruct_slave(weapon, target, slot)
    -- convert the target to a vector3 position to direction
    local target_direction = position_to_direction(weapon.pos, target)
    Game:Log("Weapon [" .. weapon.id .."] direction: " .. target_direction.x .. ", " .. target_direction.y .. ", " .. target_direction.z)
    Game:AimWeaponInDirection(weapon.id, target_direction.x,target_direction.y,target_direction.z, slot)
    Game:FireWeapon(weapon.id, 0)
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

    -- loop over weapons_master table
    for i, id in ipairs(weapons_master) do
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
function update_projectile_pos()
    current_projectile_pos = active_projectile_pos
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

function paralax_to_range(pos1, pos2, dir1, dir2)
    -- vector from obs1 to obs2
    local p21 = pos2 - pos1

    -- assume dir1, dir2 are normalized
    local d1d2 = Vector3.Dot(dir1, dir2)
    local denom = 1 - d1d2 * d1d2
    Game:Log("Denom: " .. denom)

    -- lines nearly parallel → unreliable
    if math.abs(denom) < 1e-6 then
        Game:Log("Lines are nearly parallel")
        return nil, nil
    end

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
-- =================UTIL ENDS=================