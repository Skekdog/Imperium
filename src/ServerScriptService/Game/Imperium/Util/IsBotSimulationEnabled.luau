local RunService = game:GetService("RunService")
local SIMULATE_BOTS = false

local function IsBotSimulationEnabled(): boolean
    return RunService:IsStudio() and SIMULATE_BOTS
end

return IsBotSimulationEnabled