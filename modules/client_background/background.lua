-- private variables
local background
local clientVersionLabel

function openUrlDiscord()
    if g_app.getOs() == 'windows' then
        os.execute(string.format('start %s', "https://discord.gg/VTzffQe9uS"))
    elseif g_app.getOs() == 'linux' then
        os.execute(string.format('xdg-open "%s"', "https://discord.gg/VTzffQe9uS"))
    elseif g_app.getOs() == 'mac' then
        os.execute(string.format('open "%s"', "https://discord.gg/VTzffQe9uS"))
    else
        print("Unsupported OS for direct URL opening.")
    end
end

function gothaniaLabelClick()
    if g_app.getOs() == 'windows' then
        os.execute(string.format('start %s', "https://gothania.pl/"))
    elseif g_app.getOs() == 'linux' then
        os.execute(string.format('xdg-open "%s"', "https://gothania.pl/"))
    elseif g_app.getOs() == 'mac' then
        os.execute(string.format('open "%s"', "https://gothania.pl/"))
    else
        print("Unsupported OS for direct URL opening.")
    end
end

-- public functions
function init()
    background = g_ui.displayUI('background')

    clientVersionLabel = background:getChildById('clientVersionLabel')
    clientVersionLabel:setText(g_app.getName() .. ' ' .. g_app.getVersion() .. ' version')
    discordHyperLink = background:getChildById('discordHyperLink')
    gothaniaLabel = background:getChildById('gothaniaLabel')

    if not g_game.isOnline() then
        addEvent(function()
            g_effects.fadeIn(gothaniaLabel, 2500)
        end)
    end

    if not g_game.isOnline() then
        addEvent(function()
            g_effects.fadeIn(clientVersionLabel, 2500)
        end)
    end

    if not g_game.isOnline() then
        addEvent(function()
            g_effects.fadeIn(discordHyperLink, 2500)
        end)
    end

    connect(g_game, {
        onGameStart = hide
    })
    connect(g_game, {
        onGameEnd = show
    })
end

function terminate()
    disconnect(g_game, {
        onGameStart = hide
    })
    disconnect(g_game, {
        onGameEnd = show
    })

    g_effects.cancelFade(background:getChildById('clientVersionLabel'))
    background:destroy()

    background = nil
    clientVersionLabel = nil
end

function hide()
    background:hide()
end

function show()
    background:show()
end

function hideVersionLabel()
    background:getChildById('clientVersionLabel'):hide()
end

function setVersionText(text)
    clientVersionLabel:setText(text)
end

function getBackground()
    return background
end
