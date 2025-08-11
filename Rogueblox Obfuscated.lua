
local playerStatSettings = {
    walkspeed = { enabled = false, value = 0 },
    climbspeed = { enabled = false, value = 0 }
}

local gliderFlySettings = {
    enabled = false,
    forwardSpeed = 150,
    backwardSpeed = 150,
    strafeSpeed = 150,
    verticalSpeed = 150,
    isActivelyFlying = false
}

local originalPlayerStats = {
    walkspeed = nil,
    climbspeed = nil,
}

local espSettings = {
    enemies = {
        enabled = false, 
        distance = 1000, 
        color = Color3.fromRGB(255, 0, 0), 
        showDistance = false, 
        font = "ConsolasBold",
        excludeLocalPlayer = true,
        healthDisplayStyle = "Vertical",
        showManaPox = false, 
    },
    mobs = {
        enabled = false, 
        distance = 500, 
        color = Color3.fromRGB(255, 165, 0), 
        showDistance = false, 
        font = "ConsolasBold",
        filterEnabled = false, 
        whitelist = {},
        healthDisplayStyle = "Vertical",
    },
    npcs = {
        enabled = false, 
        distance = 400, 
        color = Color3.fromRGB(66, 164, 245), 
        showDistance = false, 
        font = "ConsolasBold"
    },
    locatedNpc = {
        color = Color3.fromRGB(255, 0, 0),
        showDistance = true,
        font = "ConsolasBold",
    },
    chests = {
        enabled = false,
        distance = 500,
        color = Color3.fromRGB(235, 128, 52),
        showDistance = false,
        font = "ConsolasBold"
    },
    trinkets = {
        enabled = false,
        distance = 200,
        color = Color3.fromRGB(171, 52, 235),
        showDistance = false,
        font = "ConsolasBold"
    },
    misc = {
        noFall = false,
        spellHelper = { enabled = false, 
        autoRelease = false, 
        autoCast = false, 
        autoCaster = false, 
        hysteresis = 2.5, 
        releaseTarget = 1, 
        debounceMs = 150, 
        startDelayMs = 0, 
        chainCast = false, 
        chainRearmMs = 60 
    }
    }
}

local spellInfo = {
    { name = "Viscos", minPercent = 1, maxPercent = 100 },
    { name = "Dragon fist", minPercent = 40, maxPercent = 50 },
    { name = "Spiral Strike", minPercent = 50, maxPercent = 60 },
    { name = "Pustule", minPercent = 50, maxPercent = 60 },
    { name = "Scorch", minPercent = 35, maxPercent = 55 },
    { name = "Hinder", minPercent = 60, maxPercent = 70 },
    { name = "Chill", minPercent = 35, maxPercent = 55 },
    { name = "Manapull", minPercent = 40, maxPercent = 50 },
    { name = "Wraithflame", minPercent = 70, maxPercent = 85 },
    { name = "Hammerfall", minPercent = 10, maxPercent = 25 },
    { name = "Ukko", minPercent = 15, maxPercent = 25 },
    { name = "Pulset", minPercent = 70, maxPercent = 80 },
    { name = "Mana Pick", minPercent = 60, maxPercent = 70 },
    { name = "Angel Summoning", minPercent = 70, maxPercent = 80 },
    { name = "Boreaus", minPercent = 10, maxPercent = 20 },
    { name = "Radiance", minPercent = 60, maxPercent = 70 },
    { name = "Trinket Disguise", minPercent = 50, maxPercent = 60 },
    { name = "Gredien", minPercent = 20, maxPercent = 30},
    { name = "Death Blossoms", minPercent = 20, maxPercent = 40},
    { name = "Viresco", minPercent = 45, maxPercent = 55 },
    { name = "Smite", minPercent = 70, maxPercent = 80 },
    { name = "Bless", minPercent = 90, maxPercent = 100 },
    { name = "Hearth", minPercent = 60, maxPercent = 70 },
    { name = "Iudicium", minPercent = 45, maxPercent = 55 },
    { name = "Gate", minPercent = 75, maxPercent = 80 },
    { name = "Conatum", minPercent = 50, maxPercent = 60 },
    { name = "Pondus Ultima", minPercent = 85, maxPercent = 90 },
    { name = "Zimzap", minPercent = 40, maxPercent = 50 },
    { name = "Gallus molaris", minPercent = 90, maxPercent = 100 },
    { name = "Sancti Custodia", minPercent = 70, maxPercent = 80 },
    { name = "Irae Dei", minPercent = 80, maxPercent = 90 },
    { name = "Dei Voluntas", minPercent = 50, maxPercent = 60 },
    { name = "Summon Cauldron", minPercent = 80, maxPercent = 100},
    { name = "Gasher", minPercent = 40, maxPercent = 50 }
}

local spellInfoMap = {}
for _, spellData in ipairs(spellInfo) do
    spellInfoMap[spellData.name] = spellData
end

local spellInfoMapLower = {}

for name, data in pairs(spellInfoMap) do
    spellInfoMapLower[string.lower(name)] = data
end

local spellHelperRuntime = { prevGPressed = false, armed = false, lastReleaseTick = 0, lastSpell = nil, autoHolding = false, autoStartTick = 0, chainPending = false, chainStartTick = 0 }

local function spellHelperCleanup()
    if spellHelperRuntime.autoHolding then
        keyboard.release("g")
        spellHelperRuntime.autoHolding = false
        spellHelperRuntime.armed = false
    end
end 

local isPlaceReady = true
local renderCache = {}
local knownMobNames = {}
local fontList = { [0] = "ConsolasBold", [1] = "SmallestPixel", [2] = "Verdana", [3] = "Tahoma" }
local healthDisplayOptions = { "Vertical Bar", "Horizontal Bar", "Text Only" }
local healthStyleMap = { [0] = "Vertical", [1] = "Horizontal", [2] = "Text" }

local playersService = game.GetService("Players")
local workspace = game.GetService("Workspace")

local function handleNewPlace()
    isPlaceReady = false
    renderCache = {}
    originalPlayerStats = { walkspeed = nil, climbspeed = nil }
    gliderFlySettings.isActivelyFlying = false
end

local function getRainbowColor(speed)
    local t = utility.getTickCount() * speed
    local r = math.sin(t) * 0.5 + 0.5
    local g = math.sin(t + 2) * 0.5 + 0.5
    local b = math.sin(t + 4) * 0.5 + 0.5
    return Color3.fromRGB(r * 255, g * 255, b * 255)
end

local function round(num, decimals)
    return tonumber(string.format("%." .. (decimals or 0) .. "f", num))
end

local function getLocalPlayerPos()
    local playerCharacter = game.LocalPlayer and game.LocalPlayer.Character
    local hrp = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")
    return (hrp and hrp.Position) or nil
end

local function filterModelName(name)
    if string.sub(name, 1, 1) == "." then
        local pipeIndex = string.find(name, "|")
        if pipeIndex then
            return string.sub(name, 2, pipeIndex - 1)
        else
            return string.sub(name, 2)
        end
    end
    return name
end

local function getEntityName(model)
    if not model then return "bru 12" end
    local charNameAttr = model:GetAttribute("CharacterName")
    if charNameAttr and charNameAttr.Value and type(charNameAttr.Value) == "string" and #charNameAttr.Value > 0 then
        return charNameAttr.Value
    end
    
    return filterModelName(model.Name)
end

local function getDistance(object)
    local localPos = getLocalPlayerPos()
    if not localPos then return "0" end
    return tostring(math.floor((localPos - object.Position).Magnitude))
end

local function getFontName(fontIndex)
    return fontList[fontIndex]
end

local function uiColorToRgb(data)
    return Color3.fromRGB(data.r, data.g, data.b)
end

local function rgbToUiColor(color)
    return {r = color.R * 255, g = color.G * 255, b = color.B * 255}
end

local function findClosestNpcToName(npcName)
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end

    if #npcName == 0 then return nil end

    local function similarity(a, b)
        a, b = a:lower(), b:lower()
        if a == b then return math.huge end
        local score = 0
        if string.find(b, a, 1, true) then
            score = score + 100
        end
        if string.find(a, b, 1, true) then
            score = score + 100
        end

        local i, j, matches = 1, 1, 0
        while i <= #a and j <= #b do
            if a:sub(i,i) == b:sub(j,j) then
                matches = matches + 1
                i = i + 1
                j = j + 1
            else
                j = j + 1
            end
        end
        
        score = score + matches * 2
        score = score - math.abs(#a - #b)
        return score
    end

    local bestNpc, bestScore = nil, -math.huge
    for _, model in ipairs(npcsFolder:GetChildren()) do
        if model:IsA("Model") then
            local name = model.Name
            local s = similarity(npcName, name)
            if s > bestScore then
                bestScore = s
                bestNpc = model
            end
        end
    end

    print("Found NPC: " .. (bestNpc and bestNpc.Name or "nil") .. " with score: " .. tostring(bestScore))
    return bestNpc
end

local function renderEsp()
    if not isPlaceReady then return end

    for _, data in pairs(renderCache) do
        if data.part and data.name and data.part.Parent then
            local screenX, screenY, onScreen = utility.worldToScreen(data.part.Position + Vector3.new(0, 3, 0))

            if onScreen then
                local settings = espSettings[data.dataType]
                local textName = data.name

                if settings.showDistance then
                    textName = textName .. " [" .. getDistance(data.part) .. "m]"
                end
                
                local healthStyle = settings.healthDisplayStyle 

                if data.humanoid and healthStyle == "Text" then
                    textName = textName .. " (" .. tostring(round(data.humanoid.Health, 0)) .. "/" .. tostring(math.floor(data.humanoid.MaxHealth)) .. ")"
                end

                local textWidth, textHeight = draw.getTextSize(textName)
                local drawX = screenX - (textWidth / 2)
                local drawY = screenY - (textHeight / 2)
                
                local bottomY = drawY + textHeight

                if data.humanoid and healthStyle ~= "Text" then
                    if data.humanoid.MaxHealth > 0 then
                        local healthPercent = math.max(0, data.humanoid.Health / data.humanoid.MaxHealth)
                        local healthColor = Color3.new((1 - healthPercent), healthPercent, 0)

                        if healthStyle == "Vertical" then
                            local barWidth, barPadding, barHeight = 7, 5, textHeight * 2.5
                            local barX = drawX - barWidth - barPadding
                            local barY = drawY + (textHeight / 2) - (barHeight / 2)
                            
                            draw.rectFilled(barX, barY, barWidth, barHeight, Color3.new(0.1, 0.1, 0.1), 2, 200)
                            local foregroundHeight = barHeight * healthPercent
                            local foregroundY = barY + (barHeight - foregroundHeight)
                            draw.rectFilled(barX, foregroundY, barWidth, foregroundHeight, healthColor, 2)
                            draw.rect(barX, barY, barWidth, barHeight, Color3.new(0,0,0), 1, 2)

                        elseif healthStyle == "Horizontal" then
                            local barHeight, barPadding, barWidth = 7, 4, textWidth
                            local barX = drawX
                            local barY = drawY + textHeight + barPadding

                            draw.rectFilled(barX, barY, barWidth, barHeight, Color3.new(0.1, 0.1, 0.1), 2, 200)
                            local foregroundWidth = barWidth * healthPercent
                            draw.rectFilled(barX, barY, foregroundWidth, barHeight, healthColor, 2)
                            draw.rect(barX, barY, barWidth, barHeight, Color3.new(0,0,0), 1, 2)
                            bottomY = barY + barHeight
                        end
                	end
                end
                draw.textOutlined(textName, drawX, drawY, settings.color, settings.font)

                if data.dataType == "enemies" and settings.showManaPox and data.poxStack then
                    local poxText = "ManaPox: " .. data.poxStack 
                    local poxWidth, _ = draw.getTextSize(poxText)
                    local poxDrawX = screenX - (poxWidth / 2)
                    draw.textOutlined(poxText, poxDrawX, bottomY, settings.color, settings.font)
                end
            end
        end
    end
end

local function updateEspCache()
    local locateNpcName = ui.getValue("world", "npcSettings", "Locate NPC")

    if not (espSettings.enemies.enabled or espSettings.mobs.enabled or espSettings.npcs.enabled or espSettings.chests.enabled or espSettings.trinkets.enabled) and #locateNpcName == 0 then
        if next(renderCache) ~= nil then
            renderCache = {}
        end
        return
    end

    if not isPlaceReady then
        renderCache = {}
        return
    end

    local localPos = getLocalPlayerPos()
    if not localPos then return end

    local livingFolder = workspace:FindFirstChild("Living")
    local debrisFolder = workspace:FindFirstChild("Debris")
    local trinketsFolder = debrisFolder and debrisFolder:FindFirstChild("SpawnedItems")
    local npcsFolder = workspace:FindFirstChild("NPCs")
    local streamableObjects = {}

    local function cache(address, hrp, name, dataType, humanoid)
        streamableObjects[address] = { part = hrp, name = name, dataType = dataType, humanoid = humanoid }
    end

    if espSettings.mobs.enabled and livingFolder then
        for _, model in ipairs(livingFolder:GetChildren()) do
            if model:IsA("Model") and string.sub(model.Name, 1, 1) == "." then
                local mobName = getEntityName(model)

                if espSettings.mobs.whitelist[mobName] == nil then
                    espSettings.mobs.whitelist[mobName] = true
                    table.insert(knownMobNames, mobName)
                    ui.newCheckbox("mobs", "mobFilters", mobName, false)
                    local filterEnabled = ui.getValue("mobs", "mobSettings", "Filter Mobs")
                    ui.setVisibility("mobs", "mobFilters", mobName, filterEnabled)
                end

                local hrp, humanoid = model:FindFirstChild("HumanoidRootPart"), model:FindFirstChildOfClass("Humanoid")
                if hrp and humanoid then
                    if not espSettings.mobs.filterEnabled or espSettings.mobs.whitelist[mobName] then
                        if (localPos - hrp.Position).Magnitude <= espSettings.mobs.distance then
                            cache(model.Address, hrp, mobName, "mobs", humanoid)
                        end
                    end
                end
            end
        end
    end

    if espSettings.enemies.enabled and livingFolder then
        for _, model in ipairs(livingFolder:GetChildren()) do
            if model:IsA("Model") and string.sub(model.Name, 1, 1) ~= "." and playersService:FindFirstChild(model.Name) then
                if not (espSettings.enemies.excludeLocalPlayer and game.LocalPlayer and model.Name == game.LocalPlayer.Name) then
                    local hrp, humanoid = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart, model:FindFirstChildOfClass("Humanoid")
                    if hrp and humanoid and (localPos - hrp.Position).Magnitude <= espSettings.enemies.distance then
                        local dataToCache = { part = hrp, name = model.Name, dataType = "enemies", humanoid = humanoid }
                        local statusFolder = model:FindFirstChild("Status")
                        if statusFolder then
                            local poxStackCount = 0
                            for _, child in ipairs(statusFolder:GetChildren()) do
                                if child.Name == "PoxStack" then poxStackCount = poxStackCount + 1 end
                            end
                            if poxStackCount > 0 then dataToCache.poxStack = poxStackCount end
                        end
                        streamableObjects[model.Address] = dataToCache
                    end
                end
            end
        end
    end
    
    if espSettings.trinkets.enabled and trinketsFolder then 
        for _, trinket in ipairs(trinketsFolder:GetChildren()) do 
            local clickPart = trinket:FindFirstChild("ClickPart")
            if clickPart and (localPos - clickPart.Position).Magnitude <= espSettings.trinkets.distance then 
                cache(trinket.Address, clickPart, trinket.Name, "trinkets") 
            end
        end
    end

    if espSettings.chests.enabled and debrisFolder then 
        for _, model in ipairs(debrisFolder:GetChildren()) do 
            local topPart = model:IsA("Model") and string.find(model.Name, "chest_") and model:FindFirstChild("Top")
            if topPart and (localPos - topPart.Position).Magnitude <= espSettings.chests.distance then 
                local chestName = (model:GetAttribute("ChestType") or {}).Value or "Chest"
                cache(model.Address, topPart, chestName, "chests") 
            end
        end
    end

    if espSettings.npcs.enabled and npcsFolder then 
        for _, model in ipairs(npcsFolder:GetChildren()) do 
            local hrp = model:IsA("Model") and model:FindFirstChild("HumanoidRootPart")
            if hrp and (localPos - hrp.Position).Magnitude <= espSettings.npcs.distance then 
                cache(model.Address, hrp, model.Name, "npcs") 
            end
        end
    end

    local specificNpc = findClosestNpcToName(ui.getValue("world", "npcSettings", "Locate NPC"))
    if specificNpc then
        cache(specificNpc.Address, specificNpc:FindFirstChild("HumanoidRootPart"), specificNpc.Name, "locatedNpc")
    end

    renderCache = streamableObjects
end

local function handleGliderFly()
    local localPlayer = game.LocalPlayer
    if not localPlayer or not localPlayer.Character then
        if gliderFlySettings.isActivelyFlying then
            gliderFlySettings.isActivelyFlying = false
        end
        return
    end

    local character = localPlayer.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    
    if not (humanoid and hrp and head) then return end

    local shouldBeFlying = gliderFlySettings.enabled and (character:FindFirstChild("Glider") ~= nil)

    if shouldBeFlying and not gliderFlySettings.isActivelyFlying then
        gliderFlySettings.isActivelyFlying = true
    elseif not shouldBeFlying and gliderFlySettings.isActivelyFlying then
        gliderFlySettings.isActivelyFlying = false
    end

    if gliderFlySettings.isActivelyFlying then
        local game_glider_velocity = hrp:FindFirstChild("GlideVelocity")
        if game_glider_velocity then
            game_glider_velocity.Velocity = Vector3.new(0, 0, 0)
        end

        local deltaTime = utility.GetDeltaTime()
        if deltaTime <= 0 or deltaTime > 0.1 then return end

        local camera_pos = game.CameraPosition
        local head_pos = head.Position
        local look_direction = (head_pos - camera_pos).Unit

        local forwardVector = Vector3.new(look_direction.X, 0, look_direction.Z).Unit
        local upVector = Vector3.new(0, 1, 0)
        local rightVector = forwardVector:Cross(upVector)

        local totalOffset = Vector3.new(0, 0, 0)
        if keyboard.isPressed("w") then
            totalOffset = totalOffset + (forwardVector * gliderFlySettings.forwardSpeed)
        end
        if keyboard.isPressed("s") then
            totalOffset = totalOffset - (forwardVector * gliderFlySettings.backwardSpeed)
        end
        if keyboard.isPressed("a") then
            totalOffset = totalOffset - (rightVector * gliderFlySettings.strafeSpeed)
        end
        if keyboard.isPressed("d") then
            totalOffset = totalOffset + (rightVector * gliderFlySettings.strafeSpeed)
        end
        if keyboard.isPressed("space") then
            totalOffset = totalOffset + (upVector * gliderFlySettings.verticalSpeed)
        end
        if keyboard.isPressed("c") then
            totalOffset = totalOffset - (upVector * gliderFlySettings.verticalSpeed)
        end
        
        hrp.Position = hrp.Position + (totalOffset * deltaTime)
    end
end

local noFallPreviouslyEnabled = false -- have to do this cuz of some retarded crash

local function nofall()
    local localPlayer = game.LocalPlayer
    if not localPlayer then return end
    
    local character = localPlayer.Character
    if not character then return end

    local statusFolder = character:FindFirstChild("Status")
    if not statusFolder then return end

    if espSettings.misc.noFall then
        if statusFolder:FindFirstChild("Boosts") and not noFallPreviouslyEnabled then
            print("Renaming Boosts to NoFall")
            statusFolder.Boosts.Name = "NoFall"
            noFallPreviouslyEnabled = true
        end
    else
        if statusFolder:FindFirstChild("NoFall") and noFallPreviouslyEnabled then
            print("Renaming NoFall to Boosts")
            statusFolder.NoFall.Name = "Boosts"
            noFallPreviouslyEnabled = false
        end
    end
end

local function setupUi()
    ui.newTab("world", "World ESP")
    ui.newContainer("world", "playerSettings", "Player ESP", {autosize = true, next = true})
    ui.newCheckbox("world", "playerSettings", "Enable Players", false)
    ui.newCheckbox("world", "playerSettings", "Exclude Local Player", false)
    ui.newSliderFloat("world", "playerSettings", "Player Distance", 0, 2000, espSettings.enemies.distance)
    ui.newColorpicker("world", "playerSettings", "Player Color", rgbToUiColor(espSettings.enemies.color), true)
    ui.newCheckbox("world", "playerSettings", "Show Player Distance", false)
    ui.newDropdown("world", "playerSettings", "Health Display", healthDisplayOptions, 1)
    ui.newDropdown("world", "playerSettings", "Player Font", fontList, 4)

    ui.newContainer("world", "chestSettings", "Chest ESP", {autosize = true, next = false})
    ui.newCheckbox("world", "chestSettings", "Enable Chests", false)
    ui.newSliderFloat("world", "chestSettings", "Chest Distance", 0, 2000, espSettings.chests.distance)
    ui.newColorpicker("world", "chestSettings", "Chest Color", rgbToUiColor(espSettings.chests.color), true)
    ui.newCheckbox("world", "chestSettings", "Show Chest Distance", false)
    ui.newDropdown("world", "chestSettings", "Chest Font", fontList, 2)

    ui.newContainer("world", "trinketSettings", "Trinket ESP", {autosize = true, next = true})
    ui.newCheckbox("world", "trinketSettings", "Enable Trinkets", false)
    ui.newSliderFloat("world", "trinketSettings", "Trinket Distance", 0, 2000, espSettings.trinkets.distance)
    ui.newColorpicker("world", "trinketSettings", "Trinket Color", rgbToUiColor(espSettings.trinkets.color), true)
    ui.newCheckbox("world", "trinketSettings", "Show Trinket Distance", false)
    ui.newDropdown("world", "trinketSettings", "Trinket Font", fontList, 2)

    ui.newContainer("world", "npcSettings", "NPC ESP", {autosize = true, next = false})
    ui.newCheckbox("world", "npcSettings", "Enable NPCs", false)
    ui.newSliderFloat("world", "npcSettings", "NPC Distance", 0, 2000, espSettings.npcs.distance)
    ui.newColorpicker("world", "npcSettings", "NPC Color", rgbToUiColor(espSettings.npcs.color), true)
    ui.newCheckbox("world", "npcSettings", "Show NPC Distance", false)
    ui.newDropdown("world", "npcSettings", "NPC Font", fontList, 2)
    ui.newInputText("world", "npcSettings", "Locate NPC", "")

    ui.newTab("mobs", "Mob ESP")
    ui.newContainer("mobs", "mobSettings", "Mob Settings", {autosize = true, next = true})
    ui.newCheckbox("mobs", "mobSettings", "Enable Mobs", false)
    ui.newSliderFloat("mobs", "mobSettings", "Mob Distance", 0, 2000, espSettings.mobs.distance)
    ui.newColorpicker("mobs", "mobSettings", "Mob Color", rgbToUiColor(espSettings.mobs.color), true)
    ui.newCheckbox("mobs", "mobSettings", "Show Mob Distance", false)
    ui.newDropdown("mobs", "mobSettings", "Health Display", healthDisplayOptions, 1)
    ui.newDropdown("mobs", "mobSettings", "Mob Font", fontList, 2)
    ui.newCheckbox("mobs", "mobSettings", "Filter Mobs", false)
    ui.newContainer("mobs", "mobFilters", "Mob Filters", {autosize = true, next = false})

    ui.newTab("misc", "Misc Features")
    ui.newContainer("misc", "miscSettings", "Misc Settings", {autosize = true, next = true})
    ui.newCheckbox("misc", "miscSettings", "NoFall", false)
    ui.newCheckbox("misc", "miscSettings", "Enable Walkspeed", false)
    ui.newSliderFloat("misc", "miscSettings", "Walkspeed", 0, 50, 16)
    ui.newCheckbox("misc", "miscSettings", "Enable Climbspeed", false)
    ui.newSliderFloat("misc", "miscSettings", "Climbspeed", 0, 1, 0)
    ui.newCheckbox("misc", "miscSettings", "Show ManaPox Stacks", false)

    ui.newContainer("misc", "gliderFlyContainer", "Glider Fly", {autosize = true, next = false})
    ui.newCheckbox("misc", "gliderFlyContainer", "Enable Glider Fly (Space/C for Up/Down)", false)
    ui.newSliderFloat("misc", "gliderFlyContainer", "Forward Speed", 20, 200, gliderFlySettings.forwardSpeed)
    ui.newSliderFloat("misc", "gliderFlyContainer", "Backward Speed", 20, 200, gliderFlySettings.backwardSpeed)
    ui.newSliderFloat("misc", "gliderFlyContainer", "Strafe Speed", 20, 200, gliderFlySettings.strafeSpeed)
    ui.newSliderFloat("misc", "gliderFlyContainer", "Vertical Speed", 20, 200, gliderFlySettings.verticalSpeed)

    ui.newContainer("misc", "spellHelper", "Spell Helper", {autosize = true, next = true})
    ui.newCheckbox("misc", "spellHelper", "Enable Spell Helper", false)
    ui.newCheckbox("misc", "spellHelper", "Auto-Release Charge", false)
    ui.newCheckbox("misc", "spellHelper", "Auto-Cast at Min %", false)
    ui.newCheckbox("misc", "spellHelper", "Auto-Caster (on equip)", false)
    ui.newSliderFloat("misc", "spellHelper", "Hysteresis (±%)", 0, 10, espSettings.misc.spellHelper.hysteresis)
    ui.newDropdown("misc", "spellHelper", "Release Target", { "Min", "Mid", "Max" }, espSettings.misc.spellHelper.releaseTarget + 1)
    ui.newSliderFloat("misc", "spellHelper", "Debounce (ms)", 0, 300, espSettings.misc.spellHelper.debounceMs)
    ui.newSliderFloat("misc", "spellHelper", "Start Delay (ms)", 0, 1000, espSettings.misc.spellHelper.startDelayMs)
    ui.newCheckbox("misc", "spellHelper", "Chain-Cast (immediate)", false)
    ui.newSliderFloat("misc", "spellHelper", "Chain Rearm (ms)", 0, 400, espSettings.misc.spellHelper.chainRearmMs) 
end

local function slowUpdate()
    if not isPlaceReady then return end
    updateEspCache()

    espSettings.enemies.enabled = ui.getValue("world", "playerSettings", "Enable Players")
    espSettings.enemies.excludeLocalPlayer = ui.getValue("world", "playerSettings", "Exclude Local Player")
    espSettings.enemies.distance = ui.getValue("world", "playerSettings", "Player Distance")
    espSettings.enemies.color = uiColorToRgb(ui.getValue("world", "playerSettings", "Player Color"))
    espSettings.enemies.showDistance = ui.getValue("world", "playerSettings", "Show Player Distance")
    espSettings.enemies.showManaPox = ui.getValue("world", "playerSettings", "Show ManaPox Stacks") 
    espSettings.enemies.font = getFontName(ui.getValue("world", "playerSettings", "Player Font"))
    espSettings.enemies.healthDisplayStyle = healthStyleMap[ui.getValue("world", "playerSettings", "Health Display")]

    espSettings.mobs.enabled = ui.getValue("mobs", "mobSettings", "Enable Mobs")
    espSettings.mobs.distance = ui.getValue("mobs", "mobSettings", "Mob Distance")
    espSettings.mobs.color = uiColorToRgb(ui.getValue("mobs", "mobSettings", "Mob Color"))
    espSettings.mobs.showDistance = ui.getValue("mobs", "mobSettings", "Show Mob Distance")
    espSettings.mobs.healthDisplayStyle = healthStyleMap[ui.getValue("mobs", "mobSettings", "Health Display")]
    espSettings.mobs.font = getFontName(ui.getValue("mobs", "mobSettings", "Mob Font"))
    espSettings.mobs.filterEnabled = ui.getValue("mobs", "mobSettings", "Filter Mobs")

    for _, mobName in ipairs(knownMobNames) do
        ui.setVisibility("mobs", "mobFilters", mobName, espSettings.mobs.filterEnabled)
        if espSettings.mobs.filterEnabled then
            espSettings.mobs.whitelist[mobName] = ui.getValue("mobs", "mobFilters", mobName)
        end
    end

    espSettings.chests.enabled = ui.getValue("world", "chestSettings", "Enable Chests")
    espSettings.chests.distance = ui.getValue("world", "chestSettings", "Chest Distance")
    espSettings.chests.color = uiColorToRgb(ui.getValue("world", "chestSettings", "Chest Color"))
    espSettings.chests.showDistance = ui.getValue("world", "chestSettings", "Show Chest Distance")
    espSettings.chests.font = getFontName(ui.getValue("world", "chestSettings", "Chest Font"))

    espSettings.trinkets.enabled = ui.getValue("world", "trinketSettings", "Enable Trinkets")
    espSettings.trinkets.distance = ui.getValue("world", "trinketSettings", "Trinket Distance")
    espSettings.trinkets.color = uiColorToRgb(ui.getValue("world", "trinketSettings", "Trinket Color"))
    espSettings.trinkets.showDistance = ui.getValue("world", "trinketSettings", "Show Trinket Distance")
    espSettings.trinkets.font = getFontName(ui.getValue("world", "trinketSettings", "Trinket Font"))

    espSettings.npcs.enabled = ui.getValue("world", "npcSettings", "Enable NPCs")
    espSettings.npcs.distance = ui.getValue("world", "npcSettings", "NPC Distance")
    espSettings.npcs.color = uiColorToRgb(ui.getValue("world", "npcSettings", "NPC Color"))
    espSettings.npcs.showDistance = ui.getValue("world", "npcSettings", "Show NPC Distance")
    espSettings.npcs.font = getFontName(ui.getValue("world", "npcSettings", "NPC Font"))
end

local function fastUpdate()
    if not isPlaceReady then
        local lp = game.LocalPlayer
        if lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            isPlaceReady = true
        else
            return 
        end
    end

    espSettings.misc.noFall = ui.getValue("misc", "miscSettings", "NoFall")
    playerStatSettings.walkspeed.enabled = ui.getValue("misc", "miscSettings", "Enable Walkspeed")
    playerStatSettings.walkspeed.value = ui.getValue("misc", "miscSettings", "Walkspeed")
    playerStatSettings.climbspeed.enabled = ui.getValue("misc", "miscSettings", "Enable Climbspeed")
    playerStatSettings.climbspeed.value = ui.getValue("misc", "miscSettings", "Climbspeed")
    espSettings.misc.spellHelper.enabled = ui.getValue("misc", "spellHelper", "Enable Spell Helper")
    if not espSettings.misc.spellHelper.enabled then spellHelperCleanup() end
    espSettings.misc.spellHelper.autoRelease = ui.getValue("misc", "spellHelper", "Auto-Release Charge")
    espSettings.misc.spellHelper.autoCast = ui.getValue("misc", "spellHelper", "Auto-Cast at Min %")
    espSettings.misc.spellHelper.autoCaster = ui.getValue("misc", "spellHelper", "Auto-Caster (on equip)")
    espSettings.misc.spellHelper.hysteresis = ui.getValue("misc", "spellHelper", "Hysteresis (±%)")

    local releaseTargetUi = ui.getValue("misc", "spellHelper", "Release Target")
    if type(releaseTargetUi) == "number" then
        espSettings.misc.spellHelper.releaseTarget = math.max(0, math.min(2, releaseTargetUi - 1))
    end

    espSettings.misc.spellHelper.debounceMs = ui.getValue("misc", "spellHelper", "Debounce (ms)")
    espSettings.misc.spellHelper.startDelayMs = ui.getValue("misc", "spellHelper", "Start Delay (ms)")
    espSettings.misc.spellHelper.chainCast = ui.getValue("misc", "spellHelper", "Chain-Cast (immediate)")
    espSettings.misc.spellHelper.chainRearmMs = ui.getValue("misc", "spellHelper", "Chain Rearm (ms)") 

    gliderFlySettings.enabled = ui.getValue("misc", "gliderFlyContainer", "Enable Glider Fly (Space/C for Up/Down)")
    gliderFlySettings.forwardSpeed = ui.getValue("misc", "gliderFlyContainer", "Forward Speed")
    gliderFlySettings.backwardSpeed = ui.getValue("misc", "gliderFlyContainer", "Backward Speed")
    gliderFlySettings.strafeSpeed = ui.getValue("misc", "gliderFlyContainer", "Strafe Speed")
    gliderFlySettings.verticalSpeed = ui.getValue("misc", "gliderFlyContainer", "Vertical Speed")

    handleGliderFly()

    local localPlayer = game.LocalPlayer
    if not localPlayer then return end

    local character = localPlayer.Character
    if not character then
        originalPlayerStats.walkspeed = nil
        originalPlayerStats.climbspeed = nil
        return
    end

    local valuesFolder = character:FindFirstChild("Values")
    local walkspeedBuff = valuesFolder and valuesFolder:FindFirstChild("CurrentOutfitSpeedBuff")
    if walkspeedBuff then
        if playerStatSettings.walkspeed.enabled then
            if originalPlayerStats.walkspeed == nil then
                originalPlayerStats.walkspeed = walkspeedBuff.Value
            end
            walkspeedBuff.Value = playerStatSettings.walkspeed.value
        else
            if originalPlayerStats.walkspeed ~= nil then
                walkspeedBuff.Value = originalPlayerStats.walkspeed
                originalPlayerStats.walkspeed = nil
            end
        end
    end

    local climbspeedBuff = valuesFolder and valuesFolder:FindFirstChild("ClimbBuff")
    if climbspeedBuff then
        if playerStatSettings.climbspeed.enabled then
            if originalPlayerStats.climbspeed == nil then
                originalPlayerStats.climbspeed = climbspeedBuff.Value
            end
            climbspeedBuff.Value = playerStatSettings.climbspeed.value
        else
            if originalPlayerStats.climbspeed ~= nil then
                climbspeedBuff.Value = originalPlayerStats.climbspeed
                originalPlayerStats.climbspeed = nil
            end
        end
    end
    
    nofall()

    if not espSettings.misc.spellHelper.enabled then spellHelperCleanup(); return end
    local gDown = keyboard.isPressed("g") or spellHelperRuntime.autoHolding
    if not espSettings.misc.spellHelper.autoCaster and not gDown then return end 

    local equippedTool
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            equippedTool = child
            break
        end
    end

    if not equippedTool then spellHelperCleanup() end
    
    local isSpellAttr = equippedTool:GetAttribute("Spell")
    if not (isSpellAttr and isSpellAttr.Value == true) then spellHelperCleanup() end

    local spellData = spellInfoMap[equippedTool.Name]
    if not spellData then spellHelperCleanup() end

    local manaValueObj = valuesFolder and valuesFolder:FindFirstChild("Mana")
    if not (manaValueObj and manaValueObj.Value) then spellHelperCleanup() end
    
    local currentMana = manaValueObj.Value

    local now = utility.getTickCount()
    local hys = tonumber(espSettings.misc.spellHelper.hysteresis) or 2.5
    local debounceMs = tonumber(espSettings.misc.spellHelper.debounceMs) or 150
    local startDelayMs = tonumber(espSettings.misc.spellHelper.startDelayMs) or 0

    local target
    if espSettings.misc.spellHelper.releaseTarget == 2 then
        target = spellData.maxPercent
    elseif espSettings.misc.spellHelper.releaseTarget == 1 then
        target = (spellData.minPercent + spellData.maxPercent) / 2
    else
        target = spellData.minPercent
    end

    if spellHelperRuntime.lastSpell ~= equippedTool.Name then
        spellHelperRuntime.armed = false
        spellHelperRuntime.autoHolding = false
        spellHelperRuntime.prevGPressed = false
        spellHelperRuntime.lastSpell = equippedTool.Name
        spellHelperRuntime.autoStartTick = 0
    end 

    if espSettings.misc.spellHelper.autoCaster then
        if not spellHelperRuntime.autoHolding then
            if spellHelperRuntime.autoStartTick == 0 then
                spellHelperRuntime.autoStartTick = now
            end
        end

        if (now - spellHelperRuntime.lastReleaseTick) * 1000.0 >= debounceMs and (now - spellHelperRuntime.autoStartTick) * 1000.0 >= startDelayMs then
            if hasPress then
                local doPress = false
                if espSettings.misc.spellHelper.chainCast and spellHelperRuntime.chainPending then
                    if (now - spellHelperRuntime.chainStartTick) * 1000.0 >= (tonumber(espSettings.misc.spellHelper.chainRearmMs) or 0) then
                        doPress = true
                        spellHelperRuntime.chainPending = false
                    end
                else
                    doPress = true
                end

                if doPress then
                    keyboard.press("g")
                    spellHelperRuntime.autoHolding = true
                end
            end
        end
    end

    local gPressed = keyboard.isPressed("g") or spellHelperRuntime.autoHolding
    
    if gPressed and not spellHelperRuntime.prevGPressed then
        spellHelperRuntime.armed = true
    end

    if not spellHelperRuntime.armed and currentMana <= (target - hys) then
        spellHelperRuntime.armed = true

        if espSettings.misc.spellHelper.autoCaster and not spellHelperRuntime.autoHolding and hasPress then
            keyboard.press("g")
            spellHelperRuntime.autoHolding = true
        end
    end

    if spellHelperRuntime.armed and currentMana >= target then
        if (now - spellHelperRuntime.lastReleaseTick) * 1000.0 >= debounceMs then      
            keyboard.release("g")

            if espSettings.misc.spellHelper.autoCast then
                mouse.click("leftmouse")
            end

            spellHelperRuntime.lastReleaseTick = now
            spellHelperRuntime.armed = false
            spellHelperRuntime.prevGPressed = false
            spellHelperRuntime.autoStartTick = now

            if espSettings.misc.spellHelper.autoCaster then
                spellHelperRuntime.autoHolding = false
            end

            if espSettings.misc.spellHelper.autoCaster and espSettings.misc.spellHelper.chainCast then
                spellHelperRuntime.chainPending = true
                spellHelperRuntime.chainStartTick = now
            end
        end
    end

    spellHelperRuntime.prevGPressed = gPressed 
end

setupUi()

coroutine.wrap(function()
  cheat.register("onSlowUpdate", slowUpdate)
  cheat.register("onUpdate", fastUpdate)
  cheat.register("onPaint", renderEsp)
  cheat.register("newPlace", handleNewPlace)
end)()
