local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function(): string
    local symbol = ReplicatedStorage:GetAttribute("CurrencySymbol") :: string?
    if not symbol then
        symbol = ReplicatedStorage:GetAttributeChangedSignal("CurrencySymbol"):Wait()
    end
    assert(symbol)
    return symbol
end
