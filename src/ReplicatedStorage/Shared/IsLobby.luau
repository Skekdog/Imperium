local SharedData = require(script.Parent.SharedData)

local function IsLobby(): boolean
    return game.PlaceId == SharedData.LobbyId
end

return IsLobby