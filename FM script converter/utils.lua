-- Utils module
local Utils = {}

local Converter = require("converter")

---------- Public variables ----------

Utils.UnitConvCycleDuration = 0.0 -- (GUI) cycle duration used by the unit converter utility (msec)
Utils.UnitConvPowerLevel = 0      -- (GUI) device power level used by the unit converter utility (%)
Utils.UnitConvRPM = 0.0           -- (GUI) device RPM used by the unit converter utility

---------- Private variables ---------

---------- Public functions ----------

-- updates the values of the unit converter utility depending on the field that was changed
function Utils.update_unit_converter(changedValueType)
    if changedValueType == "duration" then
        Utils.UnitConvPowerLevel = Utils.UnitConvCycleDuration ~= 0 and
            Converter.get_device_power_level(Utils.UnitConvCycleDuration / 1000) or 0
        Utils.UnitConvRPM = 1000 / Utils.UnitConvCycleDuration * 60

    elseif changedValueType == "power" then
        Utils.UnitConvRPM = Utils.UnitConvPowerLevel ~= 0 and
            Converter.get_device_rpm(Utils.UnitConvPowerLevel) or 0
        Utils.UnitConvCycleDuration = 1000 / Utils.UnitConvRPM * 60

    elseif changedValueType == "rpm" then
        Utils.UnitConvCycleDuration = 1000 / Utils.UnitConvRPM * 60
        Utils.UnitConvPowerLevel = Converter.get_device_power_level(Utils.UnitConvCycleDuration / 1000)
    end
end

---------- Private functions ---------

return Utils
