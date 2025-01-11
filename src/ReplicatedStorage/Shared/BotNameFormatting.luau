local module = {}

function module.Format(name: string): string
    return "🤖 " .. name
end

function module.Unformat(name: string): string
    return name:split(" ")[2]
end

function module.IsFormattedBotName(name: string): boolean
    return name:split(" ")[1] == "🤖"
end

return module