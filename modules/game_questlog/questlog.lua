questLogButton = nil
questLineWindow = nil
cachedQuests = {}

function init()
    g_ui.importStyle('questlogwindow')
    g_ui.importStyle('questlinewindow')

    questLogButton = modules.client_topmenu.addLeftGameButton('questLogButton', tr('Quest Log'),
                                                              '/images/topbuttons/questlog',
                                                              function() g_game.requestQuestLog() end)

    connect(g_game, {
        onQuestLog = onGameQuestLog,
        onQuestLine = onGameQuestLine,
        onGameEnd = destroyWindows
    })
end

function terminate()
    disconnect(g_game, {
        onQuestLog = onGameQuestLog,
        onQuestLine = onGameQuestLine,
        onGameEnd = destroyWindows
    })

    destroyWindows()
    questLogButton:destroy()
end

function destroyWindows()
    if questLogWindow then questLogWindow:destroy() end
    if questLineWindow then questLineWindow:destroy() end
end

function toggleNotDoneQuests()
    if showDone ~= false then
        showDone = false
    else
        showDone = nil
    end
    updateQuestList()
    updateButtonStates()
    --g_game.requestQuestLog()
end


function toggleDoneQuests()
    if showDone ~= true then
        showDone = true
    else
        showDone = nil
    end
    updateQuestList()
    updateButtonStates()
    --g_game.requestQuestLog()
end

function updateQuestList()
    if not questLogWindow then return end

    local questList = questLogWindow:getChildById('questList')
    if questList then
        questList:destroyChildren()
    end

    -- Fetch the quests (assuming you have a cached list of quests)
    for i, questEntry in pairs(cachedQuests) do
        local id, name, completed = unpack(questEntry)

        if showDone == nil or (showDone and completed) or (not showDone and not completed) then
            local questLabel = g_ui.createWidget('QuestLabel', questList)
            questLabel:setOn(completed)
            questLabel:setText(name)
            questLabel.onDoubleClick = function()
                questLogWindow:hide()
                g_game.requestQuestLine(id)
            end
        end
    end

    questList:focusChild(questList:getFirstChild())
end

function updateButtonStates()
    local doneButton = questLogWindow:getChildById('toggleDoneQuests')
    local notDoneButton = questLogWindow:getChildById('toggleNotDoneQuests')

    if showDone == true then
        doneButton:setOn(true)
        notDoneButton:setOn(false)
    elseif showDone == false then
        doneButton:setOn(false)
        notDoneButton:setOn(true)
    else
        doneButton:setOn(false)
        notDoneButton:setOn(false)
    end
end

function onGameQuestLog(quests)
    -- Check if questLogWindow already exists and simply show it instead of recreating it
    cachedQuests = quests

    if not questLogWindow then
        questLogWindow = g_ui.createWidget('QuestLogWindow', rootWidget)
        -- Initialization code for questLogWindow goes here
    else
        questLogWindow:show()
    end

    -- Update the quest list every time without resetting the window position
    local questList = questLogWindow:getChildById('questList')
    if questList then
        questList:destroyChildren()
    end


    updateQuestList()
    updateButtonStates()

    questLogWindow.onDestroy = function() questLogWindow = nil end
    questList:focusChild(questList:getFirstChild())
end





function onGameQuestLine(questId, questMissions)
    if questLogWindow then questLogWindow:hide() end
    if questLineWindow then questLineWindow:destroy() end

    questLineWindow = g_ui.createWidget('QuestLineWindow', rootWidget)
    local missionList = questLineWindow:getChildById('missionList')
    local missionDescription = questLineWindow:getChildById('missionDescription')

    connect(missionList, {
        onChildFocusChange = function(self, focusedChild)
            if focusedChild == nil then return end
            missionDescription:setText(focusedChild.description)
        end
    })

    for i, questMission in pairs(questMissions) do
        local name, description = unpack(questMission)

        local missionLabel = g_ui.createWidget('MissionLabel')
        missionLabel:setText(name)
        missionLabel.description = description
        missionList:addChild(missionLabel)
    end

    questLineWindow.onDestroy = function()
        if questLogWindow then questLogWindow:show(true) end
        questLineWindow = nil
    end

    missionList:focusChild(missionList:getFirstChild())
end
