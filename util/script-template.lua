-- <script-name type>

-- additional variables
abc=1

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

-- ===============CUSTOM STARTS===============
-- custom function that will either be called in the
-- every_tick or every_second function 
-- (you have to manually call it tho)
function main()
    Game:Log("Custom function called!")
end

-- ================CUSTOM ENDS================




-- function that will run [every tick]
function every_tick(I)
    I:Log("A tick has passed!")
    main()
end

-- function that will run [every second]
function every_second(I)
    I:Log("A second has passed!")
    I:LogToHud("A second has passed!")
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
