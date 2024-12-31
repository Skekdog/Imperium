-- descriptor string is of format "DisplayName (@Name)"
return function(descriptor: Configuration | Player | string, mode: "Username" | "Display Name" | "Both"?): string
    if typeof(descriptor) == "string" then
        if mode == "Username" then
            return descriptor:split(" ")[2]:sub(3, -2)
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