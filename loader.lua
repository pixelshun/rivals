-- ==========================================
-- AUTO-FLING LOADER WITH WHITELIST
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Add your buyers' EXACT Roblox usernames inside this list
local WhitelistedUsers = {
    "WRKN99",                -- Your username
    "devistater1422",        -- Replace or add more buyers here
    "BuyerUsername2"
}

-- Function to check if the local player is allowed
local function isAllowed()
    local currentName = LocalPlayer.Name
    for _, name in ipairs(WhitelistedUsers) do
        if name:lower() == currentName:lower() then
            return true
        end
    end
    return false
end

-- Verify whitelist before fetching the script from GitHub
if not isAllowed() then
    warn("[Loader] Access Denied: You are not whitelisted to use this script.")
    return -- Stops the script completely for non-buyers
end

-- Replace this with your actual raw GitHub URL
local SCRIPT_URL = "https://raw.githubusercontent.com/pixelshun/rivals/refs/heads/main/autofling.lua"

print("[Loader] Access Granted! Authenticating and initializing AutoFling...")

local success, result = pcall(function()
    return game:HttpGet(SCRIPT_URL)
end)

if success and result then
    local fn, err = loadstring(result)
    if fn then
        fn()
    else
        warn("[Loader] Compilation error: " .. tostring(err))
    end
else
    warn("[Loader] Failed to connect to server.")
end
