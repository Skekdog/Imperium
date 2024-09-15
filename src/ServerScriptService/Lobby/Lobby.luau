local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LobbyTypes = require(script.Parent.Parent.Parent.ReplicatedFirst.Lobby.LobbyTypes)
local SendNotification = require(script.Parent.Parent.Shared.SendNotification)
local Teleport = require(script.Parent.Parent.Shared.Teleport)

local serverClient = ReplicatedStorage.Lobby.ServerClient

local MAX_PLAYERS = 8

local lobbies: {[number]: LobbyTypes.Lobby?} = {}

local function Kick(lobby: LobbyTypes.Lobby, plr: Player): ()
    if plr ~= lobby.Owner then
        SendNotification("You have been kicked from [PLAYER]'s lobby.", {lobby.Owner}, {plr})
    end
    lobby:RemovePlayer(plr)
end

local function Start(lobby: LobbyTypes.Lobby): ()
    local info: Teleport.GameInfo = {
        Players = #lobby.Players,
        TurnDuration = lobby.Settings["Turn Time"],
        AuctionTime = lobby.Settings["Auction Time"],
        Map = lobby.Settings["Map"],
        Board = lobby.Settings["Board"],
    }

    SendNotification("[PLAYER] has started the game. Please wait.", {lobby.Owner}, lobby.Players)
    Teleport(lobby.Players, "Game", info)

    lobbies[lobby.Owner.UserId] = nil
    serverClient.LobbyRemoved:FireAllClients(lobby.Owner.UserId)
end

local function Disband(lobby: LobbyTypes.Lobby): ()
    for _, plr in lobby.Players do
        lobby:RemovePlayer(plr)
    end

    lobbies[lobby.Owner.UserId] = nil
    serverClient.LobbyRemoved:FireAllClients(lobby.Owner.UserId)
end

local function AddPlayer(lobby: LobbyTypes.Lobby, plr: Player): ()
    local index = table.find(lobby.Players, plr)
    if index or #lobby.Players >= MAX_PLAYERS then
        return
    end

    table.insert(lobby.Players, plr)

    serverClient.PlayerAdded:FireAllClients(lobby.Owner.UserId, plr)
end

local function TryJoin(lobby: LobbyTypes.Lobby, plr: Player, password: unknown): "Success" | string
    if typeof(password) ~= "string" then
        return "of a bad request"
    end

    if not lobby then
        return "this lobby was not found"
    end

    if #lobby.Players >= MAX_PLAYERS then
        return "this lobby is full"
    end

    if lobby.Password ~= "" and lobby.Password ~= password then
        return "the password is incorrect"
    end

    if table.find(lobby.Players, plr) then
        return "you are already in this lobby"
    end

    lobby:AddPlayer(plr)

    return "Success"
end

local function RemovePlayer(lobby: LobbyTypes.Lobby, plr: Player): ()
    local index = table.find(lobby.Players, plr)
    if index then
        table.remove(lobby.Players, index)
    end

    if plr == lobby.Owner then
        SendNotification("[PLAYER] has disbanded their lobby.", {lobby.Owner}, lobby.Players)
        lobby:Disband()
    end

    serverClient.PlayerRemoved:FireAllClients(lobby.Owner.UserId, plr)
end

local function SetSetting(lobby: LobbyTypes.Lobby, setting: string, value: string | number): ()
    lobby.Settings[setting] = value

    serverClient.SettingUpdated:FireAllClients(lobby.Owner.UserId, setting, value)
end

local function GetAllSettings(lobby: LobbyTypes.Lobby): LobbyTypes.Settings
    return lobby.Settings
end

local function GetClientLobby(lobby: LobbyTypes.Lobby, to: Player?): LobbyTypes.ClientLobby
    return {
        Owner = lobby.Owner,
        Players = lobby.Players,
        Settings = lobby.Settings,
        Private = lobby.Password ~= "",
        Password = if to == lobby.Owner then lobby.Password else nil,
    }
end

local module = {}

function module.GetLobby(userId: number): LobbyTypes.Lobby?
    return lobbies[userId]
end

function module.GetAllLobbies(): {LobbyTypes.ClientLobby}
    local allLobbies: {LobbyTypes.ClientLobby} = {}

    for _, lobby in lobbies do
        assert(lobby)
        table.insert(allLobbies, lobby:GetClientLobby())
    end

    return allLobbies
end

function module.new(host: Player, password: string): LobbyTypes.Lobby
    local lobby = {}

    lobby.Owner = host
    lobby.Password = password
    lobby.Players = {host}
    lobby.Settings = {
        ["Turn Time"] = 15,
        ["Auction Time"] = 15,
        ["Map"] = "Happy Home",
        ["Board"] = "Classic (UK)",
    }

    lobby.Kick = Kick
    lobby.Start = Start
    lobby.Disband = Disband
    lobby.AddPlayer = AddPlayer
    lobby.RemovePlayer = RemovePlayer
    lobby.SetSetting = SetSetting
    lobby.GetAllSettings = GetAllSettings
    lobby.TryJoin = TryJoin
    lobby.GetClientLobby = GetClientLobby

    for _, v in lobbies do
        assert(v)

        if table.find(v.Players, host) then
            v:RemovePlayer(host)
        end
    end

    lobbies[host.UserId] = lobby

    for _, player in Players:GetPlayers() do
        serverClient.LobbyAdded:FireClient(player, lobby:GetClientLobby(player))
    end

    return lobby
end

return module