local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lobby = require(script.Parent.Lobby)
local GameConfiguration = require(script.Parent.Parent.Parent.ReplicatedFirst.Shared.GameConfiguration)

local clientServer = ReplicatedStorage.Lobby.ClientServer
clientServer.JoinLobby.OnServerInvoke = function(plr, userId: unknown, password: unknown): "Success" | string
    if typeof(userId) ~= "number" then
        return "of a bad request"
    end

    local lobby = Lobby.GetLobby(userId)
    if not lobby then
        return "this lobby was not found"
    end

    return lobby:TryJoin(plr, password)
end

clientServer.LeaveLobby.OnServerEvent:Connect(function(plr, userId: unknown)
    if typeof(userId) ~= "number" then
        return
    end

    local lobby = Lobby.GetLobby(userId)
    if not lobby then
        return
    end

    if Lobby.IsTeleporting(plr) then
        return
    end

    lobby:RemovePlayer(plr)
end)

clientServer.CreateLobby.OnServerEvent:Connect(function(plr, password: unknown)
    if typeof(password) ~= "string" then
        return
    end

    if Lobby.IsTeleporting(plr) then
        return
    end

    Lobby.new(plr, password)
end)

clientServer.KickPlayer.OnServerEvent:Connect(function(plr, target: unknown)
    if typeof(target) ~= "Instance" or not target:IsA("Player") then
        return
    end

    local lobby = Lobby.GetLobby(plr.UserId)
    if not lobby then
        return
    end

    if lobby.Owner ~= plr then
        return
    end

    if Lobby.IsTeleporting(plr) then
        return
    end

    lobby:Kick(target)
end)

clientServer.StartLobby.OnServerEvent:Connect(function(plr)
    local lobby = Lobby.GetLobby(plr.UserId)
    if lobby then
        lobby:Start()
    end
end)

clientServer.UpdateSetting.OnServerEvent:Connect(function(plr, setting: unknown, value: unknown)
    local definition: GameConfiguration.Setting
    for _, v in GameConfiguration do
        if v.Name == setting then
            definition = v
            break
        end
    end

    if not definition then
        return
    end

    local lobby = Lobby.GetLobby(plr.UserId)
    if not lobby then
        return
    end

    if definition.PossibleValues == "number" and typeof(value) ~= "number" then
        return lobby:SetSetting(definition.Name, lobby.Settings[definition.Name])
    elseif typeof(definition.PossibleValues) == "table" and not table.find(definition.PossibleValues, value :: any) then
        return lobby:SetSetting(definition.Name, lobby.Settings[definition.Name])
    end

    if typeof(value) == "number" then
        value = math.clamp(value, definition.Min or -math.huge, definition.Max or math.huge)
    end

    lobby:SetSetting(definition.Name, value)
end)

clientServer.GetAllLobbies.OnServerInvoke = function(plr)
    return Lobby.GetAllLobbiesAsClient()
end

Players.PlayerRemoving:Connect(function(plr)
    local lobby = Lobby.GetLobby(plr.UserId)
    if lobby then
        lobby:Disband()
    else
        for _, v in Lobby.GetAllLobbies() do
            v:RemovePlayer(plr)
        end
    end
end)   
