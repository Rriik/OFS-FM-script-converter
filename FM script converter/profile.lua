-- Profile module
local Profile = {}

---------- Public variables ----------

Profile.DeviceList = {                -- extendable device profile list
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

Profile.DeviceListNames = {}          -- (GUI) stores the name fields of the available device profiles
Profile.SelectedDevice = 1            -- (GUI) index of selected device (default is "Generic device")

Profile.DeviceName = "Generic device" -- (GUI) the name of the device (profile)
Profile.DeviceMaxRPM = 100            -- (GUI) the highest recorded RPM of the device (100% power)
Profile.DeviceMinRPM = 1              -- (GUI) the lowest recorded RPM of the device (1% power)

---------- Private variables ---------

---------- Public functions ----------

function Profile.init_settings()
    for _, device in ipairs(Profile.DeviceList) do
        table.insert(Profile.DeviceListNames, device.name)
    end
end

function Profile.update_settings()
    Profile.DeviceName = Profile.DeviceList[Profile.SelectedDevice].name
    Profile.DeviceMaxRPM = Profile.DeviceList[Profile.SelectedDevice].maxRPM
    Profile.DeviceMinRPM = Profile.DeviceList[Profile.SelectedDevice].minRPM
end

---------- Private functions ---------

return Profile
