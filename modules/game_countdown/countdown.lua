
local currentTime
local countdownEvent

local targetTime = os.time({
    year = 2024,
    month = 7,
    day = 26,
    hour = 20,
    min = 0,
    sec = 0
})

function formatTime(diff)
    local days = math.floor(diff / (24 * 3600))
    diff = diff % (24 * 3600)
    local hours = math.floor(diff / 3600)
    diff = diff % 3600
    local minutes = math.floor(diff / 60)
    local seconds = diff % 60
    if (modules.client_locales.getCurrentLocale().name == 'pl') then
        return string.format("%02d dni, %02d godzin, %02d minut, %02d sekund", days, hours, minutes, seconds)
    else
        return string.format("%02d days, %02d hours, %02d minutes, %02d seconds", days, hours, minutes, seconds)
    end
end

function updateCountdown()
    currentTime = os.time()
    local diff = os.difftime(targetTime, currentTime)
    if diff > 0 then
        return formatTime(diff)
    else
        return ""
    end
end

function startCountdown()
    countdownEvent = scheduleEvent(function()
        local time = updateCountdown()
        modules.client_topmenu.updateCountdownLabel(time)
        if time == "" then
            stopCountdown()
        else
            startCountdown()
        end
    end, 1000)
end

function stopCountdown()
    if countdownEvent then
        removeEvent(countdownEvent)
        countdownEvent = nil
    end
end

function init()
    startCountdown()
end

function terminate()
    stopCountdown()
end
