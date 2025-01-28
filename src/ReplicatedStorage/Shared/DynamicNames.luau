local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local GetPlayerName = require(script.Parent.GetPlayerName)
local module = {}

export type Mode = "Username" | "Display Name" | "Both"

local lastMode: Mode?

assert(not RunService:IsServer(), "DynamicNames must not be run on the server")

local function replacePlayers(str: string, players: {string}, mode: Mode): string
    local i = 1
    -- Replace [PLAYER] with the corresponding player name from the table
    str = string.gsub(str, "%[PLAYER%]", function()
        if not players[i] then
            return "[PLAYER]"
        end

        local playerName = GetPlayerName(players[i], mode)
        i += 1
        
        return playerName or "[PLAYER]"
    end)
    return str
end

function module.UpdateLabel(mode: Mode, textLabel: TextLabel): ()
    lastMode = mode

    local format = textLabel:GetAttribute("Format") :: string?
    if not format then
        return
    end

    local descriptors = {}

    for i, v in textLabel:GetAttributes() do
        if i:sub(1, 7) == "Player_" then
            assert(typeof(v) == "string", "Expected descriptor string for Player attribute")
            local index = tonumber(i:sub(8))
            assert(index, "Expected index for Player attribute")
            descriptors[index] = v
        end
    end

    local text = replacePlayers(format, descriptors, mode)
    textLabel.Text = if textLabel:GetAttribute("MakeUpper") then text:upper() else text
end

function module.UpdateAll(mode: Mode): ()
    lastMode = mode
    for _, textLabel in CollectionService:GetTagged("DynamicNames") do
        assert(textLabel:IsA("TextLabel"), "Expected TextLabel")
        module.UpdateLabel(mode, textLabel)
    end
end

local function setupListener(textLabel: TextLabel): ()
    textLabel:GetAttributeChangedSignal("Format"):Connect(function()
        module.UpdateLabel(lastMode or "Both", textLabel)
    end)

    textLabel.AttributeChanged:Connect(function(name)
        if name:sub(1, 7) == "Player_" then
            module.UpdateLabel(lastMode or "Both", textLabel)
        end
    end)

    module.UpdateLabel(lastMode or "Both", textLabel)
end

for _, v in CollectionService:GetTagged("DynamicNames") do
    assert(v:IsA("TextLabel"), "Expected TextLabel")
    setupListener(v)
end

CollectionService:GetInstanceAddedSignal("DynamicNames"):Connect(function(textLabel)
    assert(textLabel:IsA("TextLabel"), "Expected TextLabel")
    setupListener(textLabel)
end)

return module