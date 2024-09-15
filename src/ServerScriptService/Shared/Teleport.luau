local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local SafeTeleport = require(script.Parent.SafeTeleport)

local gamePlaceId = 72812941745571
local lobbyPlaceId = 110109018598423

local gameInfoStore = MemoryStoreService:GetHashMap("GameInfo")

export type GameInfo = {
    Players: number,
    TurnDuration: number,
    AuctionTime: number,
}

return function(players: {Player}, place: "Game" | "Lobby", gameInfo: GameInfo?, callback: ((success: boolean, TeleportAsyncResult) -> ())?): ()
    task.spawn(function()
        local accessCode, privateId = TeleportService:ReserveServer(if place == "Game" then gamePlaceId else lobbyPlaceId)

        local options = Instance.new("TeleportOptions")
        options.ReservedServerAccessCode = accessCode
    
        if place == "Game" then
            assert(gameInfo)
            gameInfoStore:SetAsync(privateId, gameInfo, 180)
        end
    
        local success, result = SafeTeleport(if place == "Game" then gamePlaceId else lobbyPlaceId, players, options)
        if callback then
            callback(success, result)
        end
    end)
end
