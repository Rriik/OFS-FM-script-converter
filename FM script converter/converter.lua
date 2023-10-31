-- Converter module
local Converter = {}

local Profile = require("profile")

---------- Public variables ----------

Converter.RecordPowerOnSinglePeaks = true   -- (GUI) whether to record the device power level on single peaks
Converter.RecordPowerOnSingleTroughs = true -- (GUI) whether to record the device power level on single troughs
Converter.RecordPowerOnPeakSeries = true    -- (GUI) whether to record the device power level on peak series
Converter.RecordPowerOnTroughSeries = true  -- (GUI) whether to record the device power level on trough series
Converter.UsePowerDropoff = true            -- (GUI) whether to use the device power level dropoff feature
Converter.PowerDropoffTimeOffset = 100      -- (GUI) time offset to enter/exit device power level dropoff (msec)
Converter.Ignore0PosSeries = true           -- (GUI) whether to leave 0-position action series untouched

---------- Private variables ---------

SlopeDirection = {RISING = 1, NEUTRAL = 0, FALLING = -1} -- enum used for peak/trough detection

---------- Public functions ----------

-- converts a raw penetration rhythm funscript into one that is usable by a rotary fuck machine,
-- utilizing a cycle-time-to-power-level function described by the minimum and maximum RPM of the
-- selected device profile
-- uses various conversion options that can be adjusted through the extension GUI
-- can process either the whole script, or just selected actions in the script
function Converter.convert_script(onlySelection)
    local script = ofs.Script(ofs.ActiveIdx())
    local deviceActions = {}
    local peaks, troughs = get_peaks_troughs(script.actions)

    local prevPeak, prevTrough = nil, nil
    local peakSeries, troughSeries = false, false
    local peakSeriesFirstAction, troughSeriesFirstAction = nil, nil

    for idx, action in ipairs(script.actions) do
        -- process selected actions (or whole script if desired)
        if onlySelection == false or (onlySelection and action.selected) then
            -- if current action is a peak
            if find_action_in_table(action, peaks) then
                local peakDuration = 1.0e10 -- defaults to high value in case it cannot be calculated
                if peakSeries then
                    if idx < #script.actions and not find_action_in_table(script.actions[idx + 1], peaks) or
                    idx == #script.actions then
                        peakSeries = false -- deactivate if next action is not a peak
                        if action.pos == 0 and Converter.Ignore0PosSeries then
                            table.insert(deviceActions, Action.new(action.at, 0, false))
                        else
                            if Converter.RecordPowerOnPeakSeries then -- obtain duration between peaks
                                local nextPeak = find_next_action_in_table(idx, peaks) -- try to find next peak
                                if nextPeak then
                                    peakDuration = get_action_duration(action, nextPeak)
                                end
                                -- obtain device power level using duration between peaks and add it to an action
                                local powerLevel = Converter.get_device_power_level(peakDuration)
                                table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                            end
                            if Converter.UsePowerDropoff then -- add power dropoff for multiple peak gap
                                insert_dropoff_actions(deviceActions, peakSeriesFirstAction, action)
                            end
                        end
                    end

                elseif idx < #script.actions and find_action_in_table(script.actions[idx + 1], peaks) then
                    peakSeries = true -- activate if next action is also a peak
                    peakSeriesFirstAction = action -- store first action in peak series
                    if action.pos == 0 and Converter.Ignore0PosSeries then
                        table.insert(deviceActions, Action.new(action.at, 0, false))
                    else
                        if Converter.RecordPowerOnPeakSeries then -- obtain duration between peaks
                            if prevPeak then -- use previous peak if available
                                peakDuration = get_action_duration(prevPeak, action)
                            elseif prevTrough then -- otherwise use previous trough if available
                                peakDuration = get_action_duration(prevTrough, action)
                            end
                            -- obtain device power level using duration between peaks and add it to an action
                            local powerLevel = Converter.get_device_power_level(peakDuration)
                            table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                        end
                    end

                else
                    if Converter.RecordPowerOnSinglePeaks then -- obtain duration between peaks
                        if prevPeak then -- use previous peak if available
                            peakDuration = get_action_duration(prevPeak, action)
                        else -- otherwise try to find next peak
                            local nextPeak = find_next_action_in_table(idx, peaks)
                            if nextPeak then
                                peakDuration = get_action_duration(action, nextPeak)
                            end
                        end
                        -- obtain device power level using duration between peaks and add it to an action
                        local powerLevel = Converter.get_device_power_level(peakDuration)
                        table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                    end
                end
                prevPeak = action

            elseif find_action_in_table(action, troughs) then
                local troughDuration = 1.0e10 -- defaults to high value in case it cannot be calculated
                if troughSeries then
                    if idx < #script.actions and not find_action_in_table(script.actions[idx + 1], troughs) or
                    idx == #script.actions then
                        troughSeries = false -- deactivate if next action is not a trough
                        if action.pos == 0 and Converter.Ignore0PosSeries then
                            table.insert(deviceActions, Action.new(action.at, 0, false))
                        else
                            if Converter.RecordPowerOnTroughSeries then -- obtain duration between troughs
                                local nextTrough = find_next_action_in_table(idx, troughs) -- try to find next trough
                                if nextTrough then
                                    troughDuration = get_action_duration(action, nextTrough)
                                end
                                -- obtain device power level using duration between troughs and add it to an action
                                local powerLevel = Converter.get_device_power_level(troughDuration)
                                table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                            end
                            if Converter.UsePowerDropoff then -- add power dropoff for multiple trough gap
                                insert_dropoff_actions(deviceActions, troughSeriesFirstAction, action)
                            end
                        end
                    end

                elseif idx < #script.actions and find_action_in_table(script.actions[idx + 1], troughs) then
                    troughSeries = true -- activate if next action is also a trough
                    troughSeriesFirstAction = action -- store first action in trough series
                    if action.pos == 0 and Converter.Ignore0PosSeries then
                        table.insert(deviceActions, Action.new(action.at, 0, false))
                    else
                        if Converter.RecordPowerOnTroughSeries then -- obtain duration between troughs
                            if prevTrough then -- use previous trough if available
                                troughDuration = get_action_duration(prevTrough, action)
                            elseif prevPeak then -- otherwise use previous peak if available
                                troughDuration = get_action_duration(prevPeak, action)
                            end
                            -- obtain device power level using duration between troughs and add it to an action
                            local powerLevel = Converter.get_device_power_level(troughDuration)
                            table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                        end
                    end

                else
                    if Converter.RecordPowerOnSingleTroughs then -- obtain duration between troughs
                        if prevTrough then -- use previous trough if available
                            troughDuration = get_action_duration(prevTrough, action)
                        else -- otherwise try to find next trough
                            local nextTrough = find_next_action_in_table(idx, troughs)
                            if nextTrough then
                                troughDuration = get_action_duration(action, nextTrough)
                            end
                        end
                        -- obtain device power level using duration between troughs and add it to an action
                        local powerLevel = Converter.get_device_power_level(troughDuration)
                        table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                    end
                end
                prevTrough = action
            end
            -- mark original action for removal
            script:markForRemoval(idx)
        end
    end

    -- remove marked actions and concatenate the two action tables
    script:removeMarked()
    for idx, action in ipairs(deviceActions) do
        table.insert(script.actions, deviceActions[idx])
    end

    -- sort the resulting script and commit it
    script:sort()
    script:commit()
end

-- converts the duration between two actions into a 0-100 value representing the equivalent power
-- level of the selected device
function Converter.get_device_power_level(duration)
    local rpm = (1 / duration) * 60
    local powerLevel = 1 + 99 * (rpm - Profile.DeviceMinRPM) / (Profile.DeviceMaxRPM - Profile.DeviceMinRPM)
    powerLevel = clamp(powerLevel, 0, 100)
    powerLevel = round(powerLevel, 0)
    return powerLevel
end

-- converts the power level of the selected device into the equivalent RPM value using the minimum
-- and maximum RPM configuration of the device
function Converter.get_device_rpm(powerLevel)
    return Profile.DeviceMinRPM + (Profile.DeviceMaxRPM - Profile.DeviceMinRPM) * (powerLevel - 1) / 99
end

-- selects all peaks or all troughs in the script
function Converter.select_all_peaks_or_troughs(which)
    local script = ofs.Script(ofs.ActiveIdx())
    if script == nil then
        return
    end
    local peaks, troughs = get_peaks_troughs(script.actions)
    for _, action in ipairs(script.actions) do -- deselect all actions first
        action.selected = false
    end
    if which == "peaks" then -- select peaks
        for _, action in ipairs(peaks) do
            action.selected = true
        end
    elseif which == "troughs" then -- select troughs
        for _, action in ipairs(troughs) do
            action.selected = true
        end
    end
    script:commit()
end

---------- Private functions ---------

-- checks whether an action is found in a table of actions
-- uses the fact that each action must have a unique 'at' value
-- downside: only works correctly as long as both the action and action table are part of the same script
function find_action_in_table(targetAction, actionTable)
    for _, action in ipairs(actionTable) do
        if action.at == targetAction.at then
            return true
        end
    end
    return false
end

-- gets the next action after a current action's index if it exists in a given table
-- returns the next action found, or nil if the search reaches the end of the script's actions list
function find_next_action_in_table(currentActionIndex, actionTable)
    local script = ofs.Script(ofs.ActiveIdx())
    if currentActionIndex < #script.actions then
        for idx, action in ipairs(script.actions) do
            if idx > currentActionIndex and find_action_in_table(script.actions[idx], actionTable) then
                return script.actions[idx]
            end
        end
    end
    return nil
end

-- gets time duration between two actions
function get_action_duration(action1, action2)
    return math.abs(action2.at - action1.at)
end

-- gets position difference between two actions
function get_action_pos_diff(action1, action2)
    return action2.pos - action1.pos
end

-- full implementation of an algorithm that finds local extrema (minima and maxima) in a table of actions
-- correctly identifies all peaks and troughs according to mathematic definitions, including equal value
-- sequences found anywhere in the table
-- returns the maxima and minima as two tables of actions
function get_peaks_troughs(actions)
    local maxima, minima = {}, {}
    local n = #actions
    local prevPosDiff, nextPosDiff
    local slopeTrend = SlopeDirection.NEUTRAL

    -- deal with edge cases where there are at most 2 actions
    if n <= 1 then -- there need to be at least two actions to identify local extrema
        return maxima, minima
    elseif n == 2 then
        if get_action_pos_diff(actions[1], actions[2]) > 0 then
            table.insert(maxima, actions[2])
            table.insert(minima, actions[1])
        elseif get_action_pos_diff(actions[1], actions[2]) < 0 then
            table.insert(maxima, actions[1])
            table.insert(minima, actions[2])
        end -- if the two actions have equal positions, there are no extrema
        return maxima, minima
    end

    -- check the first action for local extrema
    nextPosDiff = get_action_pos_diff(actions[1], actions[2])
    if nextPosDiff > 0 then
        table.insert(minima, actions[1])
        slopeTrend = SlopeDirection.RISING
    elseif nextPosDiff < 0 then
        table.insert(maxima, actions[1])
        slopeTrend = SlopeDirection.FALLING
    end -- equal positions always get handled with the benefit of hindsight, so not here

    -- check the middle actions for local extrema
    for i = 2, n - 1 do
        prevPosDiff = get_action_pos_diff(actions[i - 1], actions[i])
        nextPosDiff = get_action_pos_diff(actions[i], actions[i + 1])
        -- if prev and next actions have higher positions, current position is local minima
        if prevPosDiff < 0 and nextPosDiff > 0 then
            table.insert(minima, actions[i])
            slopeTrend = SlopeDirection.RISING
        -- if prev and next actions have lower positions, current position is local maxima
        elseif prevPosDiff > 0 and nextPosDiff < 0 then
            table.insert(maxima, actions[i])
            slopeTrend = SlopeDirection.FALLING
        -- if prev action has same position and next action has higher position
        elseif prevPosDiff == 0 and nextPosDiff > 0 then
            -- if the slope was not trending upwards before this point, all prior actions with
            -- equal positions are local minima
            if slopeTrend ~= SlopeDirection.RISING then
                table.insert(minima, actions[i])
                local idx = i
                while idx > 1 and get_action_pos_diff(actions[idx - 1], actions[idx]) == 0 do
                    table.insert(minima, actions[idx - 1])
                    idx = idx - 1
                end
                slopeTrend = SlopeDirection.RISING
            end
        -- if prev action has same position and next action has lower position
        elseif prevPosDiff == 0 and nextPosDiff < 0 then
            -- if the slope was not trending downwards before this point, all prior actions with
            -- equal positions are local maxima
            if slopeTrend ~= SlopeDirection.FALLING then
                table.insert(maxima, actions[i])
                local idx = i
                while idx > 1 and get_action_pos_diff(actions[idx - 1], actions[idx]) == 0 do
                    table.insert(maxima, actions[idx - 1])
                    idx = idx - 1
                end
                slopeTrend = SlopeDirection.FALLING
            end
        end
    end

    -- check the last action for local extrema
    nextPosDiff = get_action_pos_diff(actions[n - 1], actions[n])
    if nextPosDiff > 0 then -- if position increases, last action becomes local maxima
        table.insert(maxima, actions[n])
    elseif nextPosDiff < 0 then -- if position decreases, last action becomes local minima
        table.insert(minima, actions[n])
    else -- if position remains the same
        -- if the slope was trending upwards before this point, all prior actions with equal
        -- positions are local maxima
        if slopeTrend == SlopeDirection.RISING then
            table.insert(maxima, actions[n])
            local idx = n
            while idx > 1 and get_action_pos_diff(actions[idx - 1], actions[idx]) == 0 do
                table.insert(maxima, actions[idx - 1])
                idx = idx - 1
            end
        -- if the slope was trending downwards before this point, all prior actions with equal
        -- positions are local minima
        elseif slopeTrend == SlopeDirection.FALLING then
            table.insert(minima, actions[n])
            local idx = n
            while idx > 1 and get_action_pos_diff(actions[idx - 1], actions[idx]) == 0 do
                table.insert(minima, actions[idx - 1])
                idx = idx - 1
            end
        end
    end

    return maxima, minima
end

-- inserts power level dropoff actions during peak/trough series using the configured time offset
-- if the total series duration is shorter than the combined dropoff enter and exit intervals,
-- only one dropoff action will be placed in the middle of the series duration instead
function insert_dropoff_actions(deviceActions, firstSeriesAction, lastSeriesAction)
    if get_action_duration(firstSeriesAction, lastSeriesAction) > Converter.PowerDropoffTimeOffset / 1000 * 2 then
        local dropoffEnter = Action.new(firstSeriesAction.at + Converter.PowerDropoffTimeOffset / 1000, 0, false)
        local dropoffExit = Action.new(lastSeriesAction.at - Converter.PowerDropoffTimeOffset / 1000, 0, false)
        table.insert(deviceActions, dropoffEnter)
        table.insert(deviceActions, dropoffExit)
    else
        local dropoffComb = Action.new((firstSeriesAction.at + lastSeriesAction.at) / 2, 0, false)
        table.insert(deviceActions, dropoffComb)
    end
end

-- math.round function
function round(num, decimals)
    decimals = 10 ^ (decimals or 0)
    num = num * decimals
    if num >= 0 then num = math.floor(num + 0.5) else num = math.ceil(num - 0.5) end
    return num / decimals
end

return Converter
