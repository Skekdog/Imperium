-- descriptor string is of format "DisplayName (@Name)"
return function(descriptor: Configuration | Player | string, mode: "Username" | "Display Name" | "Both"?): string
    if typeof(descriptor) == "string" then
        if mode == "Username" then
            local split = descriptor:split(" ")
            if #split == 2 then
                return split[2]:sub(3, -2)
            else -- then this is a bot
                return descriptor
            end
            
        elseif mode == "Display Name" then
            return descriptor:split(" ")[1]
        elseif mode == "Both" then
            return descriptor
        else
            return descriptor
        end
    end
    return if descriptor:IsA("Configuration") then descriptor.Name else `{descriptor.DisplayName} (@{descriptor.Name})`
end