local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}

local clientServer = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ClientServer")
function module.Mortgage(name: string): ()
    clientServer:WaitForChild("MortgageProperty"):FireServer(name)
end

function module.Unmortgage(name: string): ()
    clientServer:WaitForChild("UnmortgageProperty"):FireServer(name)
end

function module.BuyHouse(name: string): ()
    clientServer:WaitForChild("BuyDevelopment"):FireServer(name, "House")
end

function module.BuyHotel(name: string): ()
    clientServer:WaitForChild("BuyDevelopment"):FireServer(name, "Hotel")
end

function module.SellHouse(name: string): ()
    clientServer:WaitForChild("SellDevelopment"):FireServer(name, "House")
end

function module.SellHotel(name: string): ()
    clientServer:WaitForChild("SellDevelopment"):FireServer(name, "Hotel")
end

function module.SellAll(name: string): ()
    clientServer:WaitForChild("SellAllDevelopments"):FireServer(name)
end

return module