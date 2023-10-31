local Converter = require("converter")
local Profile = require("profile")
local Utils = require("utils")

function init()
    -- this runs once when enabling the extension
    Profile.init_settings()
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
        Profile.update_settings()
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
    end

    if ofs.CollapsingHeader("Device profile calibration utilities") then
        if ofs.CollapsingHeader("  Unit converter") then
            ofs.Text("Cycle duration (msec)")
            Utils.UnitConvCycleDuration, UnitConvCycleDurationChanged =
                ofs.Input("##UnitConvCycleDuration", Utils.UnitConvCycleDuration, 1)
            ofs.Text("Device power level (%)")
            Utils.UnitConvPowerLevel, UnitConvPowerLevelChanged =
                ofs.InputInt("##UnitConvPowerLevel", Utils.UnitConvPowerLevel, 1)
            ofs.Text("RPM")
            Utils.UnitConvRPM, UnitConvRPMChanged =
                ofs.Input("##UnitConvRPM", Utils.UnitConvRPM, 1)
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
        Converter.UsePowerDropoff, _ =
            ofs.Checkbox("Drop power level on peak/trough series", Converter.UsePowerDropoff)
        if Converter.UsePowerDropoff then
            ofs.Text("|-> Dropoff time offset (msec)")
            Converter.PowerDropoffTimeOffset, _ =
                ofs.InputInt("##PowerDropoffTimeOffset", Converter.PowerDropoffTimeOffset)
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
