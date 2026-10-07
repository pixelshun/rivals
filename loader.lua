-- ==========================================
-- AUTO-FLING LOADER WITH WHITELIST
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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
    warn("[Loader] Access Denied: You are not whitelisted to use this script.")
    return
end

-- Replace or ensure this points to your actual obfuscated autofling.lua raw URL
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
