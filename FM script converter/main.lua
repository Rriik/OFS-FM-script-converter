local Utils = require("utils")      -- include utils.lua

DeviceList = {                      -- extendable device profile list
    {
        name = "Generic device",
        maxRPM = 100.0,
        minRPM = 1.0
    },
    {
        name = "Hismith Pro 1 (1kg load)",
        maxRPM = 254.75,
        minRPM = 17.5
    },
    -- uncomment section below to add a custom profile
    -- {
    --     name = "Your device profile",
    --     maxRPM = 100.0, -- your device's recorded RPM at 100% power* (see README for more info)
    --     minRPM = 1.0  -- your device's recorded RPM at 1% power
    -- },
}

DeviceNames = {}                    -- stores the name fields of the available device profiles
SelectedDevice = 1                  -- index of selected device (default is "Generic device")

DeviceMaxRPM = 100                  -- the highest recorded RPM of the device (100% power)
DeviceMinRPM = 1                    -- the lowest recorded RPM of the device (1% power)

UsePowerDropoff = true              -- whether to use the device power level dropoff feature
PowerDropoffTimeOffset = 100        -- time offset to enter/exit device power level dropoff (msec)

RecordPowerOnSinglePeaks = true     -- whether to record the device power level on single peaks
RecordPowerOnSingleTroughs = true   -- whether to record the device power level on single troughs
RecordPowerOnPeakSeries = true      -- whether to record the device power level on peak series
RecordPowerOnTroughSeries = true    -- whether to record the device power level on trough series

Ignore0PosSeries = true             -- whether to leave 0-position action series untouched

CalcCycleDuration = 0               -- default cycle duration for power level calculator (msec)
CalcPowerLevel = 0                  -- default device power level for power level calculator (%)
CalcRPM = 0.0                       -- default device RPM for power level calculator

function init()
    -- this runs once when enabling the extension
    for _, device in ipairs(DeviceList) do
        table.insert(DeviceNames, device.name)
    end
    print("initialized")
end

function update(delta)
    -- this runs every OFS frame
    -- delta is the time since the last call in seconds
    -- doing heavy computation here will lag OFS
end

function gui()
    -- this only runs when the window is open
    -- this is the place where a custom gui can be created
    -- doing heavy computation here will lag OFS

    ofs.Text("Select device profile")
    SelectedDevice, SelectedDeviceChanged = ofs.Combo("##Combo1", SelectedDevice, DeviceNames)
    if SelectedDeviceChanged then
        DeviceMaxRPM = DeviceList[SelectedDevice].maxRPM
        DeviceMinRPM = DeviceList[SelectedDevice].minRPM
        update_calculator("cycle")
    end

    if ofs.CollapsingHeader("Device settings") then
        ofs.Text("Max. RPM")
        ofs.SameLine()
        DeviceMaxRPM, DeviceMaxRPMChanged = ofs.Input("##Input1", DeviceMaxRPM, 1)
        ofs.Text("Min. RPM")
        ofs.SameLine()
        DeviceMinRPM, DeviceMinRPMChanged = ofs.Input("##Input2", DeviceMinRPM, 1)
        if DeviceMaxRPMChanged or DeviceMinRPMChanged then
            update_calculator("cycle")
        end
    end

    if ofs.CollapsingHeader("Device power level calculator") then
        ofs.Text("Cycle duration (msec)")
        CalcCycleDuration, CalcCycleDurationChanged = ofs.InputInt("##InputInt2", CalcCycleDuration, 1)
        if CalcCycleDurationChanged then
            update_calculator("cycle")
        end
        ofs.Text("Power level (%)")
        CalcPowerLevel, CalcPowerLevelChanged = ofs.InputInt("##InputInt3", CalcPowerLevel, 1)
        if CalcPowerLevelChanged then
            update_calculator("power")
        end
        ofs.Text("RPM")
        CalcRPM, CalcRPMChanged = ofs.InputInt("##InputInt4", CalcRPM, 1)
        if CalcRPMChanged then
            update_calculator("rpm")
        end
    end

    if ofs.CollapsingHeader("Conversion options") then
        RecordPowerOnSinglePeaks, _ = ofs.Checkbox("Record power level on single peaks", RecordPowerOnSinglePeaks)
        RecordPowerOnSingleTroughs, _ = ofs.Checkbox("Record power level on single troughs", RecordPowerOnSingleTroughs)
        RecordPowerOnPeakSeries, _ = ofs.Checkbox("Record power level on peak series", RecordPowerOnPeakSeries)
        RecordPowerOnTroughSeries, _ = ofs.Checkbox("Record power level on trough series", RecordPowerOnTroughSeries)
        UsePowerDropoff, _ = ofs.Checkbox("Drop power level on peak/trough series", UsePowerDropoff)
        if UsePowerDropoff then
            ofs.Text("|-> Dropoff time offset (msec)")
            PowerDropoffTimeOffset, _ = ofs.InputInt("##InputInt1", PowerDropoffTimeOffset)
        end
        Ignore0PosSeries, _ = ofs.Checkbox("Ignore 0-position action series", Ignore0PosSeries)
        if ofs.Button("Convert selection")then
            convert_script(true)
        end
        ofs.SameLine()
        if ofs.Button("Convert whole script") then
            convert_script(false)
        end
    end

    if ofs.CollapsingHeader("Debug options") then
        if ofs.Button("Select all peaks") then
            Utils.select_all_peaks_or_troughs("peaks")
        end
        ofs.SameLine()
        if ofs.Button("Select all troughs") then
            Utils.select_all_peaks_or_troughs("troughs")
        end
    end
end

-- updates the device power level calculator values depending on the field that was changed
function update_calculator(changedValueType)
    if changedValueType == "cycle" then
        CalcPowerLevel = CalcCycleDuration ~= 0 and get_device_power_level(CalcCycleDuration / 1000) or 0
        CalcRPM = (1000 / CalcCycleDuration) * 60
    elseif changedValueType == "power" then
        CalcRPM = CalcPowerLevel ~= 0 and get_device_rpm(CalcPowerLevel) or 0
        CalcCycleDuration = 1000 / CalcRPM * 60
    elseif changedValueType == "rpm" then
        CalcCycleDuration = 1000 / CalcRPM * 60
        CalcPowerLevel = get_device_power_level(CalcCycleDuration / 1000)
    end
end

-- converts the duration between two actions into a 0-100 value representing the equivalent power
-- level of the selected device
function get_device_power_level(duration)
    local rpm = (1 / duration) * 60
    local powerLevel = 1 + 99 * (rpm - DeviceMinRPM) / (DeviceMaxRPM - DeviceMinRPM)
    powerLevel = clamp(powerLevel, 0, 100)
    powerLevel = Utils.round(powerLevel, 0)
    return powerLevel
end

-- converts the power level of the selected device into the equivalent RPM value using the minimum
-- and maximum RPM configuration of the device
function get_device_rpm(powerLevel)
    return DeviceMinRPM + (DeviceMaxRPM - DeviceMinRPM) * (powerLevel - 1) / 99
end

-- converts a raw penetration rhythm funscript into one that is usable by a rotary fuck machine,
-- utilizing a cycle-time-to-power-level function described by the minimum and maximum RPM of the
-- selected device profile
-- uses various conversion options that can be adjusted through the extension GUI
-- can process either the whole script, or just selected actions in the script
function convert_script(onlySelection)
    local script = ofs.Script(ofs.ActiveIdx())
    local deviceActions = {}
    local peaks, troughs = Utils.get_peaks_troughs(script.actions)

    local prevPeak, prevTrough = nil, nil
    local peakSeries, troughSeries = false, false
    local peakSeriesFirstAction, troughSeriesFirstAction = nil, nil

    for idx, action in ipairs(script.actions) do
        -- process selected actions (or whole script if desired)
        if onlySelection == false or (onlySelection and action.selected) then
            -- if current action is a peak
            if Utils.find_action_in_table(action, peaks) then
                local peakDuration = 1.0e10 -- defaults to high value in case it cannot be calculated
                if peakSeries then
                    if idx < #script.actions and not Utils.find_action_in_table(script.actions[idx + 1], peaks) or
                    idx == #script.actions then
                        peakSeries = false -- deactivate if next action is not a peak
                        if action.pos == 0 and Ignore0PosSeries then
                            table.insert(deviceActions, Action.new(action.at, 0, false))
                        else
                            if RecordPowerOnPeakSeries then -- obtain duration between peaks
                                local nextPeak = Utils.find_next_action_in_table(idx, peaks) -- try to find next peak
                                if nextPeak then
                                    peakDuration = Utils.get_action_duration(action, nextPeak)
                                end
                                -- obtain device power level using duration between peaks and add it to an action
                                local powerLevel = get_device_power_level(peakDuration)
                                table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                            end
                            if UsePowerDropoff then -- add power dropoff for multiple peak gap
                                insert_dropoff_actions(deviceActions, peakSeriesFirstAction, action)
                            end
                        end
                    end

                elseif idx < #script.actions and Utils.find_action_in_table(script.actions[idx + 1], peaks) then
                    peakSeries = true -- activate if next action is also a peak
                    peakSeriesFirstAction = action -- store first action in peak series
                    if action.pos == 0 and Ignore0PosSeries then
                        table.insert(deviceActions, Action.new(action.at, 0, false))
                    else
                        if RecordPowerOnPeakSeries then -- obtain duration between peaks
                            if prevPeak then -- use previous peak if available
                                peakDuration = Utils.get_action_duration(prevPeak, action)
                            elseif prevTrough then -- otherwise use previous trough if available
                                peakDuration = Utils.get_action_duration(prevTrough, action)
                            end
                            -- obtain device power level using duration between peaks and add it to an action
                            local powerLevel = get_device_power_level(peakDuration)
                            table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                        end
                    end

                else
                    if RecordPowerOnSinglePeaks then -- obtain duration between peaks
                        if prevPeak then -- use previous peak if available
                            peakDuration = Utils.get_action_duration(prevPeak, action)
                        else -- otherwise try to find next peak
                            local nextPeak = Utils.find_next_action_in_table(idx, peaks)
                            if nextPeak then
                                peakDuration = Utils.get_action_duration(action, nextPeak)
                            end
                        end
                        -- obtain device power level using duration between peaks and add it to an action
                        local powerLevel = get_device_power_level(peakDuration)
                        table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                    end
                end
                prevPeak = action

            elseif Utils.find_action_in_table(action, troughs) then
                local troughDuration = 1.0e10 -- defaults to high value in case it cannot be calculated
                if troughSeries then
                    if idx < #script.actions and not Utils.find_action_in_table(script.actions[idx + 1], troughs) or
                    idx == #script.actions then
                        troughSeries = false -- deactivate if next action is not a trough
                        if action.pos == 0 and Ignore0PosSeries then
                            table.insert(deviceActions, Action.new(action.at, 0, false))
                        else
                            if RecordPowerOnTroughSeries then -- obtain duration between troughs
                                local nextTrough = Utils.find_next_action_in_table(idx, troughs) -- try to find next trough
                                if nextTrough then
                                    troughDuration = Utils.get_action_duration(action, nextTrough)
                                end
                                -- obtain device power level using duration between troughs and add it to an action
                                local powerLevel = get_device_power_level(troughDuration)
                                table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                            end
                            if UsePowerDropoff then -- add power dropoff for multiple trough gap
                                insert_dropoff_actions(deviceActions, troughSeriesFirstAction, action)
                            end
                        end
                    end

                elseif idx < #script.actions and Utils.find_action_in_table(script.actions[idx + 1], troughs) then
                    troughSeries = true -- activate if next action is also a trough
                    troughSeriesFirstAction = action -- store first action in trough series
                    if action.pos == 0 and Ignore0PosSeries then
                        table.insert(deviceActions, Action.new(action.at, 0, false))
                    else
                        if RecordPowerOnTroughSeries then -- obtain duration between troughs
                            if prevTrough then -- use previous trough if available
                                troughDuration = Utils.get_action_duration(prevTrough, action)
                            elseif prevPeak then -- otherwise use previous peak if available
                                troughDuration = Utils.get_action_duration(prevPeak, action)
                            end
                            -- obtain device power level using duration between troughs and add it to an action
                            local powerLevel = get_device_power_level(troughDuration)
                            table.insert(deviceActions, Action.new(action.at, powerLevel, false))
                        end
                    end

                else
                    if RecordPowerOnSingleTroughs then -- obtain duration between troughs
                        if prevTrough then -- use previous trough if available
                            troughDuration = Utils.get_action_duration(prevTrough, action)
                        else -- otherwise try to find next trough
                            local nextTrough = Utils.find_next_action_in_table(idx, troughs)
                            if nextTrough then
                                troughDuration = Utils.get_action_duration(action, nextTrough)
                            end
                        end
                        -- obtain device power level using duration between troughs and add it to an action
                        local powerLevel = get_device_power_level(troughDuration)
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

-- inserts power level dropoff actions during peak/trough series using the configured time offset
-- if the total series duration is shorter than the combined dropoff enter and exit intervals,
-- only one dropoff action will be placed in the middle of the series duration instead
function insert_dropoff_actions(deviceActions, firstSeriesAction, lastSeriesAction)
    if Utils.get_action_duration(firstSeriesAction, lastSeriesAction) > PowerDropoffTimeOffset / 1000 * 2 then
        table.insert(deviceActions, Action.new(firstSeriesAction.at + PowerDropoffTimeOffset / 1000, 0, false))
        table.insert(deviceActions, Action.new(lastSeriesAction.at - PowerDropoffTimeOffset / 1000, 0, false))
    else
        table.insert(deviceActions, Action.new((firstSeriesAction.at + lastSeriesAction.at) / 2, 0, false))
    end
end
