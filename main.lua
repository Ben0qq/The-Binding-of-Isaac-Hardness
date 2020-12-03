local hardnessMod = RegisterMod("Hardness", 1)
local json = require("json")

hardness = 1.0
timeStart = 0
timeStop = 0
roomsVisited = {n=0}
timesTakenDamage = 0
isRoomWithBoss = false


function hardnessMod:render()
    Isaac.RenderText(hardness, 1, 210, 128, 128, 128, 155)
    Isaac.RenderText(timeStart, 1, 220, 128, 128, 128, 155)
    Isaac.RenderText(timeStop, 1, 230, 128, 128, 128, 155)
    Isaac.RenderText(#roomsVisited, 1, 240, 128, 128, 128, 155)
end

function hardnessMod:takenDmg()
    timesTakenDamage = timesTakenDamage+1
end

function hardnessMod:startRoom()
    timeStart = Game().TimeCounter
    if Isaac.CountBosses()>0 then
        isRoomWithBoss = true
    end
    local entities = Isaac.GetRoomEntities()
    for i=1, #entities do
        if entities[i]:IsEnemy() then
            entities[i].MaxHitPoints = entities[i].MaxHitPoints*hardness
            entities[i].HitPoints = entities[i].MaxHitPoints
        end    
    end
end    

function hardnessMod:countHardness()
    
    timeStop = Game().TimeCounter
    if #roomsVisited == 0 then 
        table.insert( roomsVisited, (timeStop-timeStart)) 
    end

    local median = 0
    if #roomsVisited%2 == 0 then
        median = (roomsVisited[#roomsVisited/2]+roomsVisited[#roomsVisited/2+1])/2
    else
        median = roomsVisited[math.ceil(#roomsVisited/2)]
    end
    
    local parameter = (timeStop-timeStart)/median
    parameter = parameter - 1
    local scale = 0.2
    if isRoomWithBoss == false then 
        if parameter<0 then scale=0.1 end
        hardness = hardness - 0.01*math.floor(parameter/scale)
        hardness = hardness - 0.01*timesTakenDamage
    else
        if parameter<0 then scale=0.1 end
        hardness = hardness - 0.01*math.floor(parameter/(scale*2))
        hardness = hardness - 0.01*timesTakenDamage
    end
    

    if hardness<0.5 then
        hardness = 0.5
    end
    if hardness>1.5 then
        hardness = 1.5
    end
   table.insert( roomsVisited, timeStop-timeStart)
    table.sort(roomsVisited)
    timesTakenDamage = 0
    isRoomWithBoss = false
end    

function hardnessMod:resetOnFloorStart()
    hardness = 1.0
    timeStart = 0
    timeStop = 0
    roomsVisited = {}
    timesTakenDamage = 0
    isRoomWithBoss = false
end

function hardnessMod:save()
    hardnessMod.SaveData(hardnessMod, json.encode({hardness, roomsVisited}))
end

function hardnessMod:load(_,continueGame)
    if continueGame == true then   
        if hardnessMod:HasData() then
            local Table = json.decode(Isaac.LoadModData(hardnessMod))
            hardness=Table[1]
            roomsVisited=Table[2]
        end
    end
end

hardnessMod:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, hardnessMod.startRoom);
hardnessMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, hardnessMod.resetOnFloorStart);
hardnessMod:AddCallback(ModCallbacks.MC_POST_RENDER, hardnessMod.render);
hardnessMod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, hardnessMod.countHardness);
hardnessMod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, hardnessMod.save);
hardnessMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, hardnessMod.load);
hardnessMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, hardnessMod.takenDmg, EntityType.ENTITY_PLAYER);

