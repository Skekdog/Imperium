local RunService = game:GetService("RunService")
local SIMULATE_BOTS = true

local function IsBotSimulationEnabled(): boolean
    return RunService:IsStudio() and SIMULATE_BOTS
end

return IsBotSimulationEnabled