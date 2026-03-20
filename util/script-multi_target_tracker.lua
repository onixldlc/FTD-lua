-- multiple target tracker, for tracking multiple targets at once
mainframe = 2
target_list = {}

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
    user_selected_target = nil
    if(target_count == 0) then
        Game:Log("No targets found")
        return
    else
        Game:Log("Found " .. target_count .. " targets")
    end

    for i = 0, target_count - 1 do
        target_info = Game:GetTargetInfo(mainframe, i)
        target_id = target_info.Id
        table.insert(target_list, { index = target_id, info = target_info })
        if(target_info.PlayerTargetChoice) then
            user_selected_target = target_id
        end
    end
    
    if user_selected_target ~= nil then
        Game:LogToHud("User selected target " .. user_selected_target)
    end
end
-- ===============runs every ticks================
