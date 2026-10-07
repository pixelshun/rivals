-- ==========================================
-- DEBUG LOADER
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("[DEBUG] Current Game Username: " .. tostring(LocalPlayer.Name))
print("[DEBUG] Current User ID: " .. tostring(LocalPlayer.UserId))

local WhitelistedUsers = {
    "WRKN99",
    "devistater1422",
    "BuyerUsername2"
}

local function isAllowed()
    local currentName = LocalPlayer.Name
    for _, name in ipairs(WhitelistedUsers) do
        if name:lower() == currentName:lower() then
            return true
        end
    end
    return false
end

if not isAllowed() then
    warn("[Loader] Access Denied! The script thinks your name is: '" .. tostring(LocalPlayer.Name) .. "'")
    return
end

print("[Loader] Access Granted!")
