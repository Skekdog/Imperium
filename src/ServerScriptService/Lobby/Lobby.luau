local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BotNameFormatting = require(ReplicatedFirst.Shared.BotNameFormatting)
local BotCharacters = require(ServerScriptService.Shared.BotNames)
local LobbyTypes = require(script.Parent.Parent.Parent.ReplicatedFirst.Lobby.LobbyTypes)
local GameConfiguration = require(script.Parent.Parent.Parent.ReplicatedFirst.Shared.GameConfiguration)
local SendNotification = require(script.Parent.Parent.Shared.SendNotification)
local Teleport = require(script.Parent.Parent.Shared.Teleport)

local serverClient = ReplicatedStorage.Lobby.ServerClient

local MAX_PLAYERS = 8
local MIN_PLAYERS = 2

local lobbies: {[number]: LobbyTypes.Lobby?} = {}

local teleportingPlayers: {Player} = {}

local function IsTeleporting(plr: Player): boolean
    return not not table.find(teleportingPlayers, plr)
end

local function Kick(lobby: LobbyTypes.Lobby, plr: string): ()
    if plr ~= lobby.Owner.Name then
        local player = Players:FindFirstChild(plr)
        if player and player:IsA("Player") then
            SendNotification("You have been kicked from [PLAYER]'s lobby.", {lobby.Owner}, {player})
        end
    end
    lobby:RemovePlayer(plr)
end

local function Start(lobby: LobbyTypes.Lobby): ()
    local playerPlayers: {Player} = {}
    for _, v in lobby.Players do
        local plr = Players:FindFirstChild(v)
        if plr and plr:IsA("Player") then
            table.insert(playerPlayers, plr)
        end
    end

    if #lobby.Players < MIN_PLAYERS then
        return SendNotification("Not enough players to start the game.", nil, playerPlayers)
    end

    local botPlayers: {string} = {}
    for _, v in lobby.Players do
        if BotNameFormatting.IsFormattedBotName(v) then
            table.insert(botPlayers, BotNameFormatting.Unformat(v))
        end
    end

    local info = {
        Players = #playerPlayers,
        BotPlayers = botPlayers,
    } :: Teleport.GameInfo
    for i, v in lobby.Settings do
        info[i] = v
    end

    for _, plr in playerPlayers do
        serverClient.ToggleUI:FireClient(plr, false)
        table.insert(teleportingPlayers, plr)
    end

    SendNotification("[PLAYER] has started the game. Please wait.", {lobby.Owner}, playerPlayers)
    Teleport(playerPlayers, "Game", info, function(success)
        if not success then
            for _, v in playerPlayers do
                local index = table.find(teleportingPlayers, v)
                if index then
                    serverClient.ToggleUI:FireClient(v, true)
                    table.remove(teleportingPlayers, table.find(teleportingPlayers, v))
                end
            end
        end
    end)

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
    local index = table.find(lobby.Players, plr.Name)
    if index or #lobby.Players >= MAX_PLAYERS then
        return
    end

    table.insert(lobby.Players, plr.Name)

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

    if table.find(lobby.Players, plr.Name) then
        return "you are already in this lobby"
    end

    if IsTeleporting(plr) then
        return "you are already joining a game"
    end

    lobby:AddPlayer(plr)

    return "Success"
end

local function TryAddBotPlayer(lobby: LobbyTypes.Lobby): "Success" | string
    if #lobby.Players >= MAX_PLAYERS then
        return "this lobby is full"
    end

    for _, v in BotCharacters do
        if not table.find(lobby.Players, BotNameFormatting.Format(v)) then
            table.insert(lobby.Players, BotNameFormatting.Format(v))
            serverClient.PlayerAdded:FireAllClients(lobby.Owner.UserId, BotNameFormatting.Format(v))
            return "Success"
        end
    end
    
    return "there are no more available bots"
end

local function RemovePlayer(lobby: LobbyTypes.Lobby, plr: string): ()
    print(lobby.Players)
    local index = table.find(lobby.Players, plr)
    if index then
        table.remove(lobby.Players, index)
    end

    if plr == lobby.Owner.Name then
        local playerPlayers: {Player} = {}
        for _, v in lobby.Players do
            local player = Players:FindFirstChild(v)
            if player and player:IsA("Player") then
                table.insert(playerPlayers, player)
            end
        end

        SendNotification("[PLAYER] has disbanded their lobby.", {lobby.Owner}, playerPlayers)
        lobby:Disband()
    end

    serverClient.PlayerRemoved:FireAllClients(lobby.Owner.UserId, plr)
end

local function SetSetting(lobby: LobbyTypes.Lobby, setting: string, value: string | number): ()
    lobby.Settings[setting] = value

    serverClient.SettingUpdated:FireAllClients(lobby.Owner.UserId, setting, value)
end

local function GetAllSettings(lobby: LobbyTypes.Lobby): GameConfiguration.SerialisedSettings
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

function module.GetAllLobbies(): {LobbyTypes.Lobby}
    local allLobbies = {}

    for _, lobby in lobbies do
        assert(lobby)
        table.insert(allLobbies, lobby)
    end

    return allLobbies
end

function module.GetAllLobbiesAsClient(): {LobbyTypes.ClientLobby}
    local allLobbies: {LobbyTypes.ClientLobby} = {}

    for _, lobby in lobbies do
        assert(lobby)
        table.insert(allLobbies, lobby:GetClientLobby())
    end

    return allLobbies
end

module.IsTeleporting = IsTeleporting

function module.new(host: Player, password: string): LobbyTypes.Lobby
    local lobby = {}

    lobby.Owner = host
    lobby.Password = password
    lobby.Players = {host.Name}
    lobby.Settings = {} :: GameConfiguration.SerialisedSettings

    for _, v in GameConfiguration do
        lobby.Settings[v.Name] = v.Default
    end

    lobby.Kick = Kick
    lobby.Start = Start
    lobby.Disband = Disband
    lobby.AddPlayer = AddPlayer
    lobby.RemovePlayer = RemovePlayer
    lobby.SetSetting = SetSetting
    lobby.GetAllSettings = GetAllSettings
    lobby.TryJoin = TryJoin
    lobby.GetClientLobby = GetClientLobby
    lobby.TryAddBotPlayer = TryAddBotPlayer

    for _, v in lobbies do
        assert(v)

        if table.find(v.Players, host.Name) then
            v:RemovePlayer(host.Name)
        end
    end

    lobbies[host.UserId] = lobby

    for _, player in Players:GetPlayers() do
        serverClient.LobbyAdded:FireClient(player, lobby:GetClientLobby(player))
    end

    return lobby
end

return module