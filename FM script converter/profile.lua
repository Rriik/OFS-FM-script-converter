-- Profile module
local Profile = {}

local JSON = require("json")

---------- Public variables ----------

Profile.DeviceList = {                -- default device profile list
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
}

Profile.DeviceListNames = {}          -- (GUI) stores the name fields of the available device profiles
Profile.SelectedDevice = 1            -- (GUI) index of selected device (default is "Generic device")

Profile.DeviceName = "Generic device" -- (GUI) the name of the device (profile)
Profile.DeviceMaxRPM = 100            -- (GUI) the highest recorded RPM of the device (100% power)
Profile.DeviceMinRPM = 1              -- (GUI) the lowest recorded RPM of the device (1% power)

Profile.DisableCreate = false         -- (GUI) flag for toggling the Create profile button
Profile.DisableModify = false         -- (GUI) flag for toggling the Modify profile button
Profile.DisableRemove = false         -- (GUI) flag for toggling the Remove profile button

---------- Private variables ---------

---------- Public functions ----------

-- loads the profile configuration from device storage, if it exists in the extension directory
-- when it does not exist, the default values are used for initialization
function Profile.load_config()
    local file = io.open(ofs.ExtensionDir() .. "\\config.json", "r")
    if file ~= nil then
        local config_json = file:read()
        local config = JSON.decode(config_json)
        Profile.DeviceList = config.DeviceList
        Profile.SelectedDevice = config.SelectedDevice
        file:close()
    end
end

-- stores the profile configuration to device storage in the extension directory
function Profile.save_config()
    local config = {}
    config.DeviceList = Profile.DeviceList
    config.SelectedDevice = Profile.SelectedDevice

    local config_json = JSON.encode(config)
    local file = io.open(ofs.ExtensionDir() .. "\\config.json", "w")
    if file ~= nil then
        file:write(config_json)
        file:close()
    end
end

-- creates a new device profile and stores it in the DeviceList table
function Profile.create_new()
    local newDeviceProfile = {}
    newDeviceProfile.name = Profile.DeviceName
    newDeviceProfile.maxRPM = Profile.DeviceMaxRPM
    newDeviceProfile.minRPM = Profile.DeviceMinRPM
    table.insert(Profile.DeviceList, newDeviceProfile)
    -- change selected index to new device profile in anticipation of refresh_fields()
    Profile.SelectedDevice = #Profile.DeviceList
end

-- modifies the values of the currently selected device profile in the DeviceList table
function Profile.modify_current()
    Profile.DeviceList[Profile.SelectedDevice].name = Profile.DeviceName
    Profile.DeviceList[Profile.SelectedDevice].maxRPM = Profile.DeviceMaxRPM
    Profile.DeviceList[Profile.SelectedDevice].minRPM = Profile.DeviceMinRPM
end

-- removes the currently selected device profile from the DeviceList table
function Profile.remove_current()
    table.remove(Profile.DeviceList, Profile.SelectedDevice)
    -- account for potentially out of bounds selected device index
    if Profile.SelectedDevice > #Profile.DeviceList then
        Profile.SelectedDevice = #Profile.DeviceList
    end
end

-- toggles the profile management buttons if certain conditions are met
function Profile.toggle_buttons()
    -- toggle Create profile button if the name field value differs from the saved config
    if Profile.DeviceName ~=  Profile.DeviceList[Profile.SelectedDevice].name then
        Profile.DisableCreate = false
    else
        Profile.DisableCreate = true
    end
    -- toggle Modify profile button if any field values differ from the saved config
    if Profile.DeviceName ~=  Profile.DeviceList[Profile.SelectedDevice].name or
    Profile.DeviceMaxRPM ~= Profile.DeviceList[Profile.SelectedDevice].maxRPM or
    Profile.DeviceMinRPM ~= Profile.DeviceList[Profile.SelectedDevice].minRPM then
        Profile.DisableModify = false
    else
        Profile.DisableModify = true
    end
    -- toggle Remove profile button (ensure at least one profile exists)
    if #Profile.DeviceList >= 2 then
        Profile.DisableRemove = false
    else
        Profile.DisableRemove = true
    end
end

-- refreshes the device profile selector and settings fields of the GUI
function Profile.refresh_fields()
    Profile.DeviceListNames = {}
    for _, device in ipairs(Profile.DeviceList) do
        table.insert(Profile.DeviceListNames, device.name)
    end
    Profile.DeviceName = Profile.DeviceList[Profile.SelectedDevice].name
    Profile.DeviceMaxRPM = Profile.DeviceList[Profile.SelectedDevice].maxRPM
    Profile.DeviceMinRPM = Profile.DeviceList[Profile.SelectedDevice].minRPM
end

---------- Private functions ---------

return Profile
