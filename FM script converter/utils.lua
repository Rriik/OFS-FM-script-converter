local API = {}

SlopeDirection = {RISING = 1, NEUTRAL = 0, FALLING = -1}

-- full implementation of an algorithm that finds local extrema (minima and maxima) in a table of actions
-- correctly identifies all peaks and troughs according to mathematic definitions, including equal value
-- sequences found anywhere in the table
-- returns the maxima and minima as two tables of actions
function API.get_peaks_troughs(actions)
    local maxima, minima = {}, {}
    local n = #actions
    local prevPosDiff, nextPosDiff
    local slopeTrend = SlopeDirection.NEUTRAL

    -- deal with edge cases where there are at most 2 actions
    if n <= 1 then -- there need to be at least two actions to identify local extrema
        return maxima, minima
    elseif n == 2 then
        if API.get_action_pos_diff(actions[1], actions[2]) > 0 then
            table.insert(maxima, actions[2])
            table.insert(minima, actions[1])
        elseif API.get_action_pos_diff(actions[1], actions[2]) < 0 then
            table.insert(maxima, actions[1])
            table.insert(minima, actions[2])
        end -- if the two actions have equal positions, there are no extrema
        return maxima, minima
    end

    -- check the first action for local extrema
    nextPosDiff = API.get_action_pos_diff(actions[1], actions[2])
    if nextPosDiff > 0 then
        table.insert(minima, actions[1])
        slopeTrend = SlopeDirection.RISING
    elseif nextPosDiff < 0 then
        table.insert(maxima, actions[1])
        slopeTrend = SlopeDirection.FALLING
    end -- equal positions always get handled with the benefit of hindsight, so not here

    -- check the middle actions for local extrema
    for i = 2, n - 1 do
        prevPosDiff = API.get_action_pos_diff(actions[i - 1], actions[i])
        nextPosDiff = API.get_action_pos_diff(actions[i], actions[i + 1])
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
                while idx > 1 and API.get_action_pos_diff(actions[idx - 1], actions[idx]) == 0 do
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
                while idx > 1 and API.get_action_pos_diff(actions[idx - 1], actions[idx]) == 0 do
                    table.insert(maxima, actions[idx - 1])
                    idx = idx - 1
                end
                slopeTrend = SlopeDirection.FALLING
            end
        end
    end

    -- check the last action for local extrema
    nextPosDiff = API.get_action_pos_diff(actions[n - 1], actions[n])
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
            while idx > 1 and API.get_action_pos_diff(actions[idx - 1], actions[idx]) == 0 do
                table.insert(maxima, actions[idx - 1])
                idx = idx - 1
            end
        -- if the slope was trending downwards before this point, all prior actions with equal
        -- positions are local minima
        elseif slopeTrend == SlopeDirection.FALLING then
            table.insert(minima, actions[n])
            local idx = n
            while idx > 1 and API.get_action_pos_diff(actions[idx - 1], actions[idx]) == 0 do
                table.insert(minima, actions[idx - 1])
                idx = idx - 1
            end
        end
    end

    return maxima, minima
end

-- gets the next action after a current action's index if it exists in a given table
-- returns the next action found, or nil if the search reaches the end of the script's actions list
function API.find_next_action_in_table(currentActionIndex, actionTable)
    local script = ofs.Script(ofs.ActiveIdx())
    if currentActionIndex < #script.actions then
        for idx, action in ipairs(script.actions) do
            if idx > currentActionIndex and API.find_action_in_table(script.actions[idx], actionTable) then
                return script.actions[idx]
            end
        end
    end
    return nil
end

-- gets position difference between two actions
function API.get_action_pos_diff(action1, action2)
    return action2.pos - action1.pos
end

-- gets time duration between two actions
function API.get_action_duration(action1, action2)
    return math.abs(action2.at - action1.at)
end

-- checks whether an action is found in a table of actions
-- uses the fact that each action must have a unique 'at' value
-- downside: only works correctly as long as both the action and action table are part of the same script
function API.find_action_in_table(targetAction, actionTable)
    for _, action in ipairs(actionTable) do
        if action.at == targetAction.at then
            return true
        end
    end
    return false
end

-- math.round function
function API.round(num, decimals)
    decimals = 10 ^ (decimals or 0)
    num = num * decimals
    if num >= 0 then num = math.floor(num + 0.5) else num = math.ceil(num - 0.5) end
    return num / decimals
end

-- selects all peaks or all troughs in the script
function API.select_all_peaks_or_troughs(which)
    local script = ofs.Script(ofs.ActiveIdx())
    if script == nil then
        return
    end
    local peaks, troughs = API.get_peaks_troughs(script.actions)
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

return API
