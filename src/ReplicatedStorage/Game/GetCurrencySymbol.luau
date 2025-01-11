local AwaitReplicatedAttribute = require(script.Parent.Parent.Shared.AwaitReplicatedAttribute)
return function(): string
    return AwaitReplicatedAttribute("CurrencySymbol")
end
