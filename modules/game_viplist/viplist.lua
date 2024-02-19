vipWindow = nil
vipButton = nil
addVipWindow = nil
editVipWindow = nil
vipInfo = {}
refreshEvent = nil
vipStateSortOrder = {
    [VipState.Online] = 1,
    [VipState.Training] = 2,
    [VipState.OfflineTraining] = 3,
    [VipState.Pending] = 4,
    [VipState.Disconnected] = 5,
    [VipState.Offline] = 6,
}

function init()
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onAddVip = onAddVip,
        onVipStateChange = onVipStateChange
    })

    g_keyboard.bindKeyDown('Ctrl+P', toggle)

    vipButton = modules.client_topmenu.addRightGameToggleButton('vipListButton', tr('VIP List') .. ' (Ctrl+P)',
                                                                '/images/topbuttons/viplist', toggle)
    vipButton:setOn(true)
    vipWindow = g_ui.loadUI('viplist')

    if not g_game.getFeature(GameAdditionalVipInfo) then
        loadVipInfo()
    end
    refresh()
    vipWindow:setup()
    if g_game.isOnline() then
        vipWindow:setupOnStart()
    end


end



function terminate()
    g_keyboard.unbindKeyDown('Ctrl+P')
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onAddVip = onAddVip,
        onVipStateChange = onVipStateChange
    })

    if not g_game.getFeature(GameAdditionalVipInfo) then
        saveVipInfo()
    end

    if addVipWindow then
        addVipWindow:destroy()
    end

    if editVipWindow then
        editVipWindow:destroy()
    end

    vipWindow:destroy()
    vipButton:destroy()

    vipWindow = nil
    vipButton = nil

    if refreshEvent then
        removeEvent(refreshEvent)
        refreshEvent = nil
    end
end

function startRefreshingVipList()
    if refreshEvent then
        removeEvent(refreshEvent)
    end
    refreshEvent = scheduleEvent(refreshVipList, 30000) -- 30 seconds
end

function refreshVipList()
    refresh()
    startRefreshingVipList() -- Schedule the next refresh
end


function loadVipInfo()
    local settings = g_settings.getNode('VipList')
    if not settings then
        vipInfo = {}
        return
    end
    vipInfo = settings['VipInfo'] or {}
end

function saveVipInfo()
    settings = {}
    settings['VipInfo'] = vipInfo
    g_settings.mergeNode('VipList', settings)
end

function online()
    vipWindow:setupOnStart() -- load character window configuration
    refresh()
    startRefreshingVipList()
end

function offline()
    vipWindow:setParent(nil, true)
    clear()
    if refreshEvent then
        removeEvent(refreshEvent)
        refreshEvent = nil
    end
end

function refresh()
    clear()
    for id, vip in pairs(g_game.getVips()) do
        onAddVip(id, unpack(vip))
    end

    vipWindow:setContentMinimumHeight(38)
end

function clear()
    local vipList = vipWindow:getChildById('contentsPanel')
    vipList:destroyChildren()
end

function toggle()
    if vipButton:isOn() then
        vipWindow:close()
        vipButton:setOn(false)
    else
        vipWindow:open()
        vipButton:setOn(true)
    end
end

function onMiniWindowOpen()
    vipButton:setOn(true)
end

function onMiniWindowClose()
    vipButton:setOn(false)
end

function createAddWindow()
    if not addVipWindow then
        addVipWindow = g_ui.displayUI('addvip')
    end
end

function createEditWindow(widget)
    if editVipWindow then
        return
    end

    editVipWindow = g_ui.displayUI('editvip')

    local name = widget:getText()
    local id = widget:getId():sub(4)

    local okButton = editVipWindow:getChildById('buttonOK')
    local cancelButton = editVipWindow:getChildById('buttonCancel')

    local nameLabel = editVipWindow:getChildById('nameLabel')
    nameLabel:setText(name)

    local descriptionText = editVipWindow:getChildById('descriptionText')
    descriptionText:appendText(widget:getTooltip())

    local notifyCheckBox = editVipWindow:getChildById('checkBoxNotify')
    notifyCheckBox:setChecked(widget.notifyLogin)

    local iconRadioGroup = UIRadioGroup.create()
    for i = VipIconFirst, VipIconLast do
        iconRadioGroup:addWidget(editVipWindow:recursiveGetChildById('icon' .. i))
    end
    iconRadioGroup:selectWidget(editVipWindow:recursiveGetChildById('icon' .. widget.iconId))

    local cancelFunction = function()
        editVipWindow:destroy()
        iconRadioGroup:destroy()
        editVipWindow = nil
    end

    local saveFunction = function()
        local vipList = vipWindow:getChildById('contentsPanel')
        if not widget or not vipList:hasChild(widget) then
            cancelFunction()
            return
        end

        local name = widget:getText()
        local state = widget.vipState
        local description = descriptionText:getText()
        local iconId = tonumber(iconRadioGroup:getSelectedWidget():getId():sub(5))
        local notify = notifyCheckBox:isChecked()

        if g_game.getFeature(GameAdditionalVipInfo) then
            g_game.editVip(id, description, iconId, notify)
        else
            if notify ~= false or #description > 0 or iconId > 0 then
                vipInfo[name] = {
                    description = description,
                    iconId = iconId,
                    notifyLogin = notify
                }
            else
                vipInfo[name] = nil
            end
        end

        widget:destroy()
        onAddVip(id, name, state, description, iconId, notify)

        editVipWindow:destroy()
        iconRadioGroup:destroy()
        editVipWindow = nil
    end

    cancelButton.onClick = cancelFunction
    okButton.onClick = saveFunction

    editVipWindow.onEscape = cancelFunction
    editVipWindow.onEnter = saveFunction
end

function destroyAddWindow()
    addVipWindow:destroy()
    addVipWindow = nil
end

function addVip()
    g_game.addVip(addVipWindow:getChildById('name'):getText())
    destroyAddWindow()
end

function removeVip(widgetOrName)
    if not widgetOrName then
        return
    end

    local widget
    local vipList = vipWindow:getChildById('contentsPanel')
    if type(widgetOrName) == 'string' then
        local entries = vipList:getChildren()
        for i = 1, #entries do
            if entries[i]:getText():lower() == widgetOrName:lower() then
                widget = entries[i]
                break
            end
        end
        if not widget then
            return
        end
    else
        widget = widgetOrName
    end

    if widget then
        local id = widget:getId():sub(4)
        local name = widget:getText()
        g_game.removeVip(id)
        vipList:removeChild(widget)
        if vipInfo[name] and g_game.getFeature(GameAdditionalVipInfo) then
            vipInfo[name] = nil
        end
    end
end

function hideOffline(state)
    settings = {}
    settings['hideOffline'] = state
    g_settings.mergeNode('VipList', settings)

    refresh()
end

function isHiddingOffline()
    local settings = g_settings.getNode('VipList')
    if not settings then
        return false
    end
    return settings['hideOffline']
end

function getSortedBy()
    local settings = g_settings.getNode('VipList')
    if not settings or not settings['sortedBy'] then
        return 'status'
    end
    return settings['sortedBy']
end

function sortBy(state)
    settings = {}
    settings['sortedBy'] = state
    g_settings.mergeNode('VipList', settings)

    refresh()
end

function onAddVip(id, name, state, description, iconId, notify)
    local vipList = vipWindow:getChildById('contentsPanel')

    local label = g_ui.createWidget('VipListLabel')
    label.onMousePress = onVipListLabelMousePress
    label:setId('vip' .. id)
    label:setText(name)

    if not g_game.getFeature(GameAdditionalVipInfo) then
        local tmpVipInfo = vipInfo[name]
        label.iconId = 0
        label.notifyLogin = false
        if tmpVipInfo then
            if tmpVipInfo.iconId then
                label:setImageClip(torect((tmpVipInfo.iconId * 12) .. ' 0 12 12'))
                label.iconId = tmpVipInfo.iconId
            end
            if tmpVipInfo.description then
                label:setTooltip(tmpVipInfo.description)
            end
            label.notifyLogin = tmpVipInfo.notifyLogin or false
        end
    else
        label:setTooltip(description)
        label:setImageClip(torect((iconId * 12) .. ' 0 12 12'))
        label.iconId = iconId
        label.notifyLogin = notify
    end

    if state == VipState.Online then
        label:setColor('#00ff00')
    elseif state == VipState.Pending then
        label:setColor('#000000') -- logging in
    elseif state == VipState.Training then
        label:setColor('#ffff00') -- training (yellow)
    elseif state == VipState.OfflineTraining then
        label:setColor('#ffa500') -- offline training (orange)
    elseif state == VipState.Disconnected then
        label:setColor('#3b1010') -- xlog/disconnected
    else
        label:setColor('#ff0000') -- offline
    end

    label.vipState = state

    label:setPhantom(false)
    connect(label, {
        onDoubleClick = function()
            g_game.openPrivateChannel(label:getText())
            return true
        end
    })

    if state == VipState.Offline and isHiddingOffline() then
        label:setVisible(false)
    end

    local nameLower = name:lower()
    local childrenCount = vipList:getChildCount()

    local stateSortOrder = vipStateSortOrder[state] or vipStateSortOrder[VipState.Offline] -- Default to offline sort order

    local sortedBy = getSortedBy() -- Assume this function returns the current sorting criteria: 'name', 'status', or 'type'
    local insertIndex = nil

    for i = 1, vipList:getChildCount() do
        local child = vipList:getChildByIndex(i)
        local comparison = false

        if sortedBy == 'status' then
            local childStateSortOrder = vipStateSortOrder[child.vipState] or vipStateSortOrder[VipState.Offline]
            comparison = stateSortOrder < childStateSortOrder or (stateSortOrder == childStateSortOrder and name:lower() < child:getText():lower())
        elseif sortedBy == 'name' then
            comparison = name:lower() < child:getText():lower()
        elseif sortedBy == 'type' then
            comparison = iconId < child.iconId or (iconId == child.iconId and name:lower() < child:getText():lower())
        end

        if comparison then
            insertIndex = i
            break
        end
    end

    if insertIndex then
        vipList:insertChild(insertIndex, label)
    else
        vipList:addChild(label)
    end
end

function onVipStateChange(id, state)
    local vipList = vipWindow:getChildById('contentsPanel')
    local label = vipList:getChildById('vip' .. id)
    local name = label:getText()
    local description = label:getTooltip()
    local iconId = label.iconId
    local notify = label.notifyLogin
    label:destroy()

    onAddVip(id, name, state, description, iconId, notify)

    if notify and state ~= VipState.Pending then
        modules.game_textmessage.displayFailureMessage(state == VipState.Online and tr('%s has logged in.', name) or
                                                           tr('%s has logged out.', name))
    end
end

function onVipListMousePress(widget, mousePos, mouseButton)
    if mouseButton ~= MouseRightButton then
        return
    end

    local vipList = vipWindow:getChildById('contentsPanel')

    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(tr('Add new VIP'), function()
        createAddWindow()
    end)

    menu:addSeparator()
    if not isHiddingOffline() then
        menu:addOption(tr('Hide Offline'), function()
            hideOffline(true)
        end)
    else
        menu:addOption(tr('Show Offline'), function()
            hideOffline(false)
        end)
    end

    if not (getSortedBy() == 'name') then
        menu:addOption(tr('Sort by name'), function()
            sortBy('name')
        end)
    end

    if not (getSortedBy() == 'status') then
        menu:addOption(tr('Sort by status'), function()
            sortBy('status')
        end)
    end

    if not (getSortedBy() == 'type') then
        menu:addOption(tr('Sort by type'), function()
            sortBy('type')
        end)
    end

    menu:display(mousePos)

    return true
end

function onVipListLabelMousePress(widget, mousePos, mouseButton)
    if mouseButton ~= MouseRightButton then
        return
    end

    local vipList = vipWindow:getChildById('contentsPanel')

    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(tr('Send Message'), function()
        g_game.openPrivateChannel(widget:getText())
    end)
    menu:addOption(tr('Add new VIP'), function()
        createAddWindow()
    end)
    menu:addOption(tr('Edit %s', widget:getText()), function()
        if widget then
            createEditWindow(widget)
        end
    end)
    menu:addOption(tr('Remove %s', widget:getText()), function()
        if widget then
            removeVip(widget)
        end
    end)
    menu:addSeparator()
    menu:addOption(tr('Copy Name'), function()
        g_window.setClipboardText(widget:getText())
    end)

    if modules.game_console.getOwnPrivateTab() then
        menu:addSeparator()
        menu:addOption(tr('Invite to private chat'), function()
            g_game.inviteToOwnChannel(widget:getText())
        end)
        menu:addOption(tr('Exclude from private chat'), function()
            g_game.excludeFromOwnChannel(widget:getText())
        end)
    end

    if not isHiddingOffline() then
        menu:addOption(tr('Hide Offline'), function()
            hideOffline(true)
        end)
    else
        menu:addOption(tr('Show Offline'), function()
            hideOffline(false)
        end)
    end

    if not (getSortedBy() == 'name') then
        menu:addOption(tr('Sort by name'), function()
            sortBy('name')
        end)
    end

    if not (getSortedBy() == 'status') then
        menu:addOption(tr('Sort by status'), function()
            sortBy('status')
        end)
    end

    menu:display(mousePos)

    return true
end
