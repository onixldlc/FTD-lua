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
        table.insert(target_list, { index = target_id, info = target_info })
        if(target_info.PlayerTargetChoice) then
            actively_targeted_id = target_id
        end
    end
    
    if actively_targeted_id ~= nil then
        Game:LogToHud("User selected target " .. actively_targeted_id)
    end
end

function update_missile_list()
    for transceiver_id = 0, I:GetLuaTransceiverCount() - 1 do
        missile_count = I:GetLuaControlledMissileCount(transceiver_id)
        if(missile_count == 0) then
            Game:log("No missile is being fired")
            return
        end
        for missile_id = 0, missile_count - 1 do
            missile_info = I:GetLuaControlledMissileInfo(transceiver_id, missile_id)
            missile_pos = missile_info.Position
            missile_target = target_list[actively_targeted_id]
            missile_uid = missile_info.Id
            data = { pos = missile_pos, target = missile_target }
            table.insert(missiles_list, { index = missile_uid, info = data })
        end
    end
end 
-- ===============runs every ticks================
