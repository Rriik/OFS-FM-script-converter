local Converter = require("converter")
local Profile = require("profile")
local Utils = require("utils")

function init()
    -- this runs once when enabling the extension
    Profile.load_config()
    Profile.refresh_fields()
    for i = 1, 2 do -- add 2 empty measurements as default
        Utils.add_measurement()
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
    Profile.SelectedDevice, SelectedDeviceChanged =
        ofs.Combo("##SelectedDevice", Profile.SelectedDevice, Profile.DeviceListNames)
    if SelectedDeviceChanged then
        Profile.refresh_fields()
        Profile.save_config()
        Utils.update_unit_converter("duration")
    end

    if ofs.CollapsingHeader("Device profile settings") then
        ofs.Text("Name")
        ofs.SameLine()
        Profile.DeviceName, DeviceNameChanged = ofs.Input("##DeviceName", Profile.DeviceName)
        ofs.Text("Max. RPM")
        ofs.SameLine()
        Profile.DeviceMaxRPM, DeviceMaxRPMChanged = ofs.Input("##DeviceMaxRPM", Profile.DeviceMaxRPM, 1)
        ofs.Text("Min. RPM")
        ofs.SameLine()
        Profile.DeviceMinRPM, DeviceMinRPMChanged = ofs.Input("##DeviceMinRPM", Profile.DeviceMinRPM, 1)
        if DeviceMaxRPMChanged or DeviceMinRPMChanged then
            Utils.update_unit_converter("duration")
        end
        ofs.Separator()

        Profile.toggle_buttons()
        ofs.BeginDisabled(Profile.DisableCreate)
        if ofs.Button("Create") then
            Profile.create_new()
            Profile.refresh_fields()
            Profile.save_config()
            Utils.update_unit_converter("duration")
        end
        ofs.EndDisabled()
        ofs.SameLine()
        ofs.BeginDisabled(Profile.DisableModify)
        if ofs.Button("Modify") then
            Profile.modify_current()
            Profile.refresh_fields()
            Profile.save_config()
            Utils.update_unit_converter("duration")
        end
        ofs.EndDisabled()
        ofs.SameLine()
        ofs.BeginDisabled(Profile.DisableRemove)
        if ofs.Button("Remove") then
            Profile.remove_current()
            Profile.refresh_fields()
            Profile.save_config()
            Utils.update_unit_converter("duration")
        end
        ofs.EndDisabled()
    end

    if ofs.CollapsingHeader("Device profile calibration utilities") then
        if ofs.CollapsingHeader("  Unit converter") then
            ofs.Text("Number of cycles")
            Utils.UnitConvNrCycles, UnitConvNrCyclesChanged =
                ofs.Input("##UnitConvNrCycles", Utils.UnitConvNrCycles, 1)
            ofs.Text("Time period (sec)")
            Utils.UnitConvTimePeriod, UnitConvTimePeriodChanged =
                ofs.Input("##UnitConvTimePeriod", Utils.UnitConvTimePeriod, 1)
            ofs.Text("Cycle duration (msec)")
            Utils.UnitConvCycleDuration, UnitConvCycleDurationChanged =
                ofs.Input("##UnitConvCycleDuration", Utils.UnitConvCycleDuration, 1)
            ofs.Text("Device power level (%)")
            Utils.UnitConvPowerLevel, UnitConvPowerLevelChanged =
                ofs.InputInt("##UnitConvPowerLevel", Utils.UnitConvPowerLevel, 1)
            ofs.Text("RPM")
            Utils.UnitConvRPM, UnitConvRPMChanged =
                ofs.Input("##UnitConvRPM", Utils.UnitConvRPM, 1)
            if UnitConvNrCyclesChanged then
                Utils.update_unit_converter("cycles")
            end
            if UnitConvTimePeriodChanged then
                Utils.update_unit_converter("time")
            end
            if UnitConvCycleDurationChanged then
                Utils.update_unit_converter("duration")
            end
            if UnitConvPowerLevelChanged then
                Utils.update_unit_converter("power")
            end
            if UnitConvRPMChanged then
                Utils.update_unit_converter("rpm")
            end
        end

        if ofs.CollapsingHeader("  Min./Max. RPM estimator") then
            for i = 1, #Utils.EstimatorMeasurements do
                ofs.Text("Measurement " .. tostring(i))
                ofs.SameLine()
                ofs.BeginDisabled(Utils.DisableMeasurementXButtons)
                if ofs.Button("X##Estimator#Measurement" .. tostring(i)) then
                    Utils.remove_measurement(i)
                    ofs.EndDisabled()
                    break
                end
                ofs.EndDisabled()
                Utils.EstimatorMeasurements[i].powerLevel, _ =
                    ofs.SliderInt("Power level##EstimatorPowerLevel" .. tostring(i),
                    Utils.EstimatorMeasurements[i].powerLevel, 1, 100)
                Utils.EstimatorMeasurements[i].rpm, _ =
                    ofs.Input("RPM##EstimatorRPM" .. tostring(i), Utils.EstimatorMeasurements[i].rpm, 1)
            end
            if ofs.Button("Add measurement") then
                Utils.add_measurement()
            end
            ofs.Separator()
            Utils.estimate_profile_config()
            ofs.Text("Estimated profile configuration:")
            ofs.Text("- Max. RPM: " .. string.format("%.2f", Utils.EstimatedMaxRPM))
            ofs.Text("- Min. RPM: " .. string.format("%.2f", Utils.EstimatedMinRPM))
        end
    end

    if ofs.CollapsingHeader("Conversion options") then
        Converter.RecordPowerOnSinglePeaks, _ =
            ofs.Checkbox("Record power level on single peaks", Converter.RecordPowerOnSinglePeaks)
        Converter.RecordPowerOnSingleTroughs, _ =
            ofs.Checkbox("Record power level on single troughs", Converter.RecordPowerOnSingleTroughs)
        Converter.RecordPowerOnPeakSeries, _ =
            ofs.Checkbox("Record power level on peak series", Converter.RecordPowerOnPeakSeries)
        Converter.RecordPowerOnTroughSeries, _ =
            ofs.Checkbox("Record power level on trough series", Converter.RecordPowerOnTroughSeries)
        ofs.Separator()
        Converter.UsePowerDropoff, _ =
            ofs.Checkbox("Drop power level on peak/trough series", Converter.UsePowerDropoff)
        if Converter.UsePowerDropoff then
            ofs.Text("|-> Dropoff time offset (msec)")
            Converter.PowerDropoffTimeOffset, _ =
                ofs.InputInt("##PowerDropoffTimeOffset", Converter.PowerDropoffTimeOffset)
        else
            Converter.PowerDropoffTimeOffset = 100
        end
        Converter.OverrideStepSize, _ =
            ofs.Checkbox("Override power level step size", Converter.OverrideStepSize)
        if Converter.OverrideStepSize then
            ofs.Text("|-> Step size")
            Converter.PowerLevelStepSize, _ =
                clamp(ofs.InputInt("##PowerLevelStepSize", Converter.PowerLevelStepSize), 1, 10)
        else
            Converter.PowerLevelStepSize = 1
        end
        Converter.Ignore0PosSeries, _ =
            ofs.Checkbox("Ignore 0-position action series", Converter.Ignore0PosSeries)
        if ofs.Button("Convert selection")then
            Converter.convert_script(true)
        end
        ofs.SameLine()
        if ofs.Button("Convert whole script") then
            Converter.convert_script(false)
        end
    end

    if ofs.CollapsingHeader("Debug options") then
        if ofs.Button("Select all peaks") then
            Converter.select_all_peaks_or_troughs("peaks")
        end
        ofs.SameLine()
        if ofs.Button("Select all troughs") then
            Converter.select_all_peaks_or_troughs("troughs")
        end
    end
end
