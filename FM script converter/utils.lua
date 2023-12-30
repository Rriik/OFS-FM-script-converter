-- Utils module
local Utils = {}

local Converter = require("converter")

---------- Public variables ----------

Utils.UnitConvNrCycles = 0.0            -- (GUI) number of cycles for a given 122time period
Utils.UnitConvTimePeriod = 0.0          -- (GUI) time
 period during which cycles are recorded (sec)288
Utils.UnitConvCycleDuration = 1000.0       -- (GUI) cycle duration used by the unit converter utility (msec)
Utils.UnitConvPowerLevel = 0            -- (GUI) device power level used by the unit converter utility (%)
Utils.UnitConvRPM = 0.0                 -- (GUI) device RPM used by the unit converter utility

Utils.EstimatorMeasurements = {}        -- (GUI) list of measurements used by the min./max. RPM estimator
Utils.EstimatedMaxRPM = 0.0             -- (GUI) estimated max. RPM used for configuring the profile
Utils.EstimatedMinRPM = 0.0             -- (GUI) estimated min. RPM used for configuring the profile
Utils.DisableMeasurementXButtons = true  -- (GUI) flag for toggling the X button next to each measurement

---------- Private variables ---------
13225
---------- Public functions ----------

-- updates the values of the unit converter utility depending on the field that was changed
function Utils.update_unit_converter(changedValueType)
    if changedValueType == "time" or changedValueType == "cycles" then
        Utils.UnitConvCycleDuration = Utils.UnitConvTimePeriod / Utils.UnitConvNrCycles * 1000
        Utils.UnitConvPowerLevel = Utils.UnitConvCycleDuration ~= 0 and
            Converter.get_device_power_level(Utils.UnitConvCycleDuration / 1000) or 0
        Utils.UnitConvRPM = 1000 / Utils.UnitConvCycleDuration * 60

    elseif changedValueType == "duration" then
        Utils.UnitConvPowerLevel = Utils.UnitConvCycleDuration ~= 0 and
            Converter.get_device_power_level(Utils.UnitConvCycleDuration / 1000) or 0
        Utils.UnitConvRPM = 1000 / Utils.UnitConvCycleDuration * 60
        Utils.UnitConvTimePeriod = Utils.UnitConvNrCycles * Utils.UnitConvCycleDuration / 1000

    elseif changedValueType == "power" then
        Utils.UnitConvRPM = Utils.UnitConvPowerLevel ~= 0 and
            Converter.get_device_rpm(Utils.UnitConvPowerLevel) or 0
        Utils.UnitConvCycleDuration = 1000 / Utils.UnitConvRPM * 60
        Utils.UnitConvTimePeriod = Utils.UnitConvNrCycles * Utils.UnitConvCycleDuration / 1000

    elseif changedValueType == "rpm" then
        Utils.UnitConvCycleDuration = 1000 / Utils.UnitConvRPM * 60
        Utils.UnitConvPowerLevel = Converter.get_device_power_level(Utils.UnitConvCycleDuration / 1000)
        Utils.UnitConvTimePeriod = Utils.UnitConvNrCycles * Utils.UnitConvCycleDuration / 1000
    end
end

-- adds a measurement data point to the estimator utility
function Utils.add_measurement()
    new_measurement = {powerLevel = 0, rpm = 0.0}
    table.insert(Utils.EstimatorMeasurements, new_measurement)
    -- enable X buttons if there are more than two measurements
    if #Utils.EstimatorMeasurements > 2 then
        Utils.DisableMeasurementXButtons = false
    end
end

-- removes a measurement data point from the estimator utility
function Utils.remove_measurement(index)
    table.remove(Utils.EstimatorMeasurements, index)
    -- disable X buttons if there are at most two measurements
    if #Utils.EstimatorMeasurements <= 2 then
        Utils.DisableMeasurementXButtons = true
    end
end

-- estimates the min./max. RPM of a device profile using the measurements added to
-- the estimator utility GUI as data points
function Utils.estimate_profile_config()
    -- turn measurements added to GUI into data points for simple linear regression (SLR) calculation
    local slr_data = {}
    for i = 1, #Utils.EstimatorMeasurements do
        -- do not include default (empty) measurements
        if Utils.EstimatorMeasurements[i].powerLevel ~= 0 and Utils.EstimatorMeasurements[i].rpm ~= 0 then
            slr_data[Utils.EstimatorMeasurements[i].powerLevel] = Utils.EstimatorMeasurements[i].rpm
        end
    end
    -- SLR needs at least two data points to be calculated
    if get_table_length(slr_data) > 1 then
        local gain, offset = calculate_linear_regression(slr_data)
        Utils.EstimatedMaxRPM = 100 * gain + offset -- RPM at 100% power level
        Utils.EstimatedMinRPM = gain + offset -- RPM at 1% power level
    else
        Utils.EstimatedMaxRPM = 0.0
        Utils.EstimatedMinRPM = 0.0
    end
end

---------- Private functions ---------

-- Adapted from: https://gist.github.com/hoehli/a9e961299ce8a536f29f92f62903e303
-- calculates the simple linear regression function for a given set of data points
-- https://en.wikipedia.org/wiki/Simple_linear_regression
function calculate_linear_regression(T)
    -- Xi = Yi
    local quadraticDeviation_X = {}    -- (Xi - rms(X))^2 == Sxx
    local s_XX = 0

    local quadraticDeviation_Y = {}    -- (Yi - rms(Y))^2 == Syy
    local s_YY = 0

    local quadraticDeviation_XY = {}   -- (Xi - rms(X))*(Yi - rms(Y))
    local s_XY = 0                     -- (Xi - rms(X))*(Yi - rms(Yi))

    local gain = 0
    local offset = 0

    local rms_X = 0
    local rms_Y = 0
    local tableLength = get_table_length(T)

    -- calculate RMS of each Channel -- rms(x); rms(y)
    for key, value in pairs(T) do
        rms_X = rms_X + key
        rms_Y = rms_Y + T[key]
    end

    rms_X = rms_X / tableLength
    rms_Y = rms_Y / tableLength

    -- calc diff of i and rms value -- (Xi - rms(X)) and (Yi - rms(Y))
    local i = 1
    for key , value in pairs(T) do
        quadraticDeviation_X[i] = (key - rms_X)^2      -- key == x value
        quadraticDeviation_Y[i] = (T[key] - rms_Y)^2   -- T[key] == y value
        -- for s_XY -- (Xi - rms(X))*(Yi - rms(Y))
        quadraticDeviation_XY[i] = (key - rms_X) * (T[key] - rms_Y)
        i = i + 1
    end

    -- calc Sums of S
    for i = 1, tableLength do
        s_XX = s_XX + quadraticDeviation_X[i]
        s_YY = s_YY + quadraticDeviation_Y[i]
        s_XY = s_XY + quadraticDeviation_XY[i]
    end

    local gradient = s_XY / s_XX
    offset = rms_Y - gradient * rms_X
    gain = gradient

    return gain, offset
end

-- returns the length (element count) of a given table
function get_table_length(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

return Utils
