local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lobby = require(script.Parent.Lobby)
local LobbyTypes = require(script.Parent.Parent.Parent.ReplicatedFirst.Lobby.LobbyTypes)

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

    lobby:RemovePlayer(plr)
end)

clientServer.CreateLobby.OnServerEvent:Connect(function(plr, password: unknown)
    if typeof(password) ~= "string" then
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

    lobby:Kick(target)
end)

clientServer.StartLobby.OnServerEvent:Connect(function(plr)
    local lobby = Lobby.GetLobby(plr.UserId)
    if lobby then
        lobby:Start()
    end
end)

local availableSettings: LobbyTypes.AvailableSettings = {
    ["Turn Time"] = 15,
    ["Auction Time"] = 10,
    ["Map"] = {
        "Happy Home",
    },
    ["Board"] = {
        "Classic (UK)",
    },
}
clientServer.GetAvailableSettings.OnServerInvoke = function(plr)
    return availableSettings
end

clientServer.GetAllLobbies.OnServerInvoke = function(plr)
    return Lobby.GetAllLobbies()
end
