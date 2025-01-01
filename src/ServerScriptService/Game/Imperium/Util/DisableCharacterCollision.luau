local PhysicsService = game:GetService("PhysicsService")

PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:RegisterCollisionGroup("Dice")
PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)
PhysicsService:CollisionGroupSetCollidable("Dice", "Characters", false)
local function disableCollisionForPart(part: Instance): ()
    if part:IsA("BasePart") then
        part.CollisionGroup = "Characters"
    end
end

local function DisableCollision(char: Model): ()
    for _, v in char:GetDescendants() do
        disableCollisionForPart(v)
    end

    char.DescendantAdded:Connect(disableCollisionForPart)
end

return DisableCollision