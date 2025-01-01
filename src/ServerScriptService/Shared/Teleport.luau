local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local GameConfiguration = require(script.Parent.Parent.Parent.ReplicatedFirst.Shared.GameConfiguration)
local SharedData = require(script.Parent.Parent.Parent.ReplicatedFirst.Shared.SharedData)
local SafeTeleport = require(script.Parent.SafeTeleport)

local gameInfoStore = MemoryStoreService:GetHashMap("GameInfo")

export type GameInfo = {
    Players: number,
    BotPlayers: {string},
} & GameConfiguration.SerialisedSettings

return function(players: {Player}, place: "Game" | "Lobby", gameInfo: GameInfo?, callback: ((success: boolean, TeleportAsyncResult) -> ())?): ()
    task.spawn(function()
        local accessCode, privateId = TeleportService:ReserveServer(if place == "Game" then SharedData.GameId else SharedData.LobbyId)

        local options = Instance.new("TeleportOptions")
        options.ReservedServerAccessCode = accessCode
    
        if place == "Game" then
            assert(gameInfo)
            gameInfoStore:SetAsync(privateId, gameInfo, 180)
        end
    
        local success, result = SafeTeleport(if place == "Game" then SharedData.GameId else SharedData.LobbyId, players, options)
        if callback then
            callback(success, result)
        end
    end)
end
