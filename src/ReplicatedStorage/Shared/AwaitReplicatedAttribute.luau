local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function(attribute: string): any
    local value = ReplicatedStorage:GetAttribute(attribute)
    while value == nil do
        value = ReplicatedStorage:GetAttribute(attribute)
        task.wait()
    end
    return value
end
