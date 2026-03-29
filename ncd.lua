local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local KnitClient = require(ReplicatedStorage.Packages.Knit.KnitClient)
local plr = Players.LocalPlayer
local success, AbilityController = pcall(function()
return KnitClient.GetController("AbilityController")
end)
if not success or not AbilityController then
return warn("AbilityController not found")
end
local OriginalLegacy = AbilityController.legacy and AbilityController.legacy.AbilityCooldown
local OriginalController = AbilityController.AbilityCooldown
_G.EnableNoCooldown = function()
plr:SetAttribute("NoCooldowns", true)
if AbilityController.legacy and type(OriginalLegacy) == "function" then
AbilityController.legacy.AbilityCooldown = function()
return 0
end
end
if type(OriginalController) == "function" then
AbilityController.AbilityCooldown = function()
return 0
end
end
pcall(function()
AbilityController.AbilityOne = 0
AbilityController.AbilityTwo = 0
AbilityController.AbilityThree = 0
end)
print("No Cooldown Enabled")
end
_G.DisableNoCooldown = function()
plr:SetAttribute("NoCooldowns", false)
if AbilityController.legacy and type(OriginalLegacy) == "function" then
AbilityController.legacy.AbilityCooldown = OriginalLegacy
end
if type(OriginalController) == "function" then
AbilityController.AbilityCooldown = OriginalController
end
print("No Cooldown Disabled (Restored)")
end