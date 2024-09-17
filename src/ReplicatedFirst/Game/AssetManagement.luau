local module = {}

function module.Mortgage(name: string): ()
    print("mortgage", name)
end

function module.Unmortgage(name: string): ()
    print("unmortgage", name)
end

function module.BuyHouse(name: string): ()
    print("buy house", name)
end

function module.BuyHotel(name: string): ()
    print("buy hotel", name)
end

function module.SellHouse(name: string): ()
    print("sell house", name)
end

function module.SellHotel(name: string): ()
    print("sell hotel", name)
end

function module.SellAll(name: string): ()
    print("sell all", name)
end

return module