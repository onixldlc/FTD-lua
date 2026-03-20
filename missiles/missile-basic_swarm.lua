-- multiple target tracker, for tracking multiple targets at once
mainframe = 2
max_missile = 48

target_list = {}
missiles_list = {}
actively_targeted_id = nil

-- time tracking for HUD (no spam)
currS = 0
prevS = 0
second_has_passed = false

Game=nil
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

-- ===============runs every ticks================
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
        data = { pos = target_pos, info = target_info }
        target_list[target_id] = data
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
                missile_pos = missile_info.Position
                missile_target_id = actively_targeted_id
                data = { target = missile_target_id, info = missile_info }
                missiles_list[missile_uid] = data
            end
            ::continue::
        end
    end
    Game:Log("data dump: " .. dump(missiles_list))
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

            target_pos = target_list[target_id].pos
            target_x = target_pos.x
            target_y = target_pos.y
            target_z = target_pos.z

            Game:SetLuaControlledMissileAimPoint(transceiver_id, missile_id, target_x, target_y, target_z)
            ::continue::
        end
    end
end
-- ===============runs every ticks================


-- ===============utils================
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then s = s .. '['..k..'] = ' end
         s = s .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
-- ===============utils================
