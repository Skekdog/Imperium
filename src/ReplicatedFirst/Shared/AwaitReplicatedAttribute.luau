local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function<T>(attribute: string): any
    local value = ReplicatedStorage:GetAttribute(attribute)
    if typeof(value) == "nil" then
        ReplicatedStorage:GetAttributeChangedSignal(attribute):Wait()
        return ReplicatedStorage:GetAttribute(attribute)
    end
    return value
end
