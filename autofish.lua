-- ===================================================
-- Roblox 自動釣魚腳本 (v11.1 - 拖曳卡住/黏滑鼠修復版)
-- ===================================================

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local isRunning = false
local loopTask = nil

-- ---------------------------------------------------
-- ⚙️ 預設參數 (可直接在 UI 上修改)
-- ---------------------------------------------------
local CHARGE_TIME = 0.700             -- 預設蓄力時間 (秒)
local CLICK_AFTER_FISH_DELAY = 0.8   -- 預設收魚後點擊延遲 (秒)
local toggleKey = Enum.KeyCode.F6     -- 預設開關熱鍵
local isBindingKey = false            -- 是否正在讀取熱鍵按壓

-- ---------------------------------------------------
-- 1. 建立 UI 介面
-- ---------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFishFullGuiV11_1"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 270)
mainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

-- 標題列 (兼具拖曳握把功能)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.Text = "全功能自動釣魚 v11.1 (按住此處拖曳)"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 12
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Active = true
titleLabel.Parent = mainFrame

-- 開關按鈕 (ON / OFF)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.05, 0, 0.13, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.Text = "開始釣魚 (OFF)"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 15
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Parent = mainFrame

-- 手動點擊 / 拋竿按鈕
local manualBtn = Instance.new("TextButton")
manualBtn.Size = UDim2.new(0.9, 0, 0, 30)
manualBtn.Position = UDim2.new(0.05, 0, 0.28, 0)
manualBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 200)
manualBtn.Text = "手動點擊 / 拋竿"
manualBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
manualBtn.TextSize = 14
manualBtn.Font = Enum.Font.SourceSansBold
manualBtn.Parent = mainFrame

-- Helper 函式：建立標籤與輸入框
local function createSettingRow(posY, labelText, defaultVal)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 25)
    label.Position = UDim2.new(0.05, 0, posY, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.3, 0, 0, 25)
    box.Position = UDim2.new(0.65, 0, posY, 0)
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    box.Text = tostring(defaultVal)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 13
    box.Font = Enum.Font.SourceSans
    box.Parent = mainFrame

    return box
end

-- 設定區域 (蓄力時間 & 點擊延遲)
local chargeBox = createSettingRow(0.42, "蓄力時間 (秒):", CHARGE_TIME)
local delayBox = createSettingRow(0.54, "收魚點擊延遲:", CLICK_AFTER_FISH_DELAY)

-- 熱鍵設定區域
local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(0.5, 0, 0, 25)
keyLabel.Position = UDim2.new(0.05, 0, 0.66, 0)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = "熱鍵開關:"
keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
keyLabel.TextSize = 13
keyLabel.TextXAlignment = Enum.TextXAlignment.Left
keyLabel.Font = Enum.Font.SourceSans
keyLabel.Parent = mainFrame

local keybindBtn = Instance.new("TextButton")
keybindBtn.Size = UDim2.new(0.4, 0, 0, 25)
keybindBtn.Position = UDim2.new(0.55, 0, 0.66, 0)
keybindBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
keybindBtn.Text = "按鍵: [ F6 ]"
keybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
keybindBtn.TextSize = 13
keybindBtn.Font = Enum.Font.SourceSansBold
keybindBtn.Parent = mainFrame

-- 狀態提示
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.9, 0, 0, 20)
statusLabel.Position = UDim2.new(0.05, 0, 0.85, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "狀態: 待命"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.Parent = mainFrame

-- ---------------------------------------------------
-- 2. 🌟 自訂不黏滑鼠的視窗拖曳邏輯 🌟
-- ---------------------------------------------------
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- ---------------------------------------------------
-- 3. 虛擬背景輸入模組
-- ---------------------------------------------------
local function holdLeftClick()
    VirtualUser:Button1Down(Vector2.new(0, 0), Camera and Camera.CFrame or CFrame.new())
    VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 0)
end

local function releaseLeftClick()
    VirtualUser:Button1Up(Vector2.new(0, 0), Camera and Camera.CFrame or CFrame.new())
    VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 0)
end

local function clickOnce()
    holdLeftClick()
    task.wait(0.08)
    releaseLeftClick()
end

-- ---------------------------------------------------
-- 4. 尋找 FishingAnchor
-- ---------------------------------------------------
local function getFishingAnchor(character)
    if not character then return nil end
    for _, child in ipairs(character:GetChildren()) do
        if string.find(child.Name, "FishingAnchor") then
            return child
        end
    end
    return nil
end

local function waitForAnchor(character, timeout)
    local startTime = os.clock()
    local anchor = getFishingAnchor(character)
    if anchor then return anchor end

    while isRunning and (os.clock() - startTime) < timeout do
        anchor = getFishingAnchor(character)
        if anchor then return anchor end
        task.wait(0.05)
    end
    return nil
end

-- ---------------------------------------------------
-- 5. 主要邏輯迴圈
-- ---------------------------------------------------
local function autoFishLoop()
    while isRunning do
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            task.wait(1)
            continue
        end

        statusLabel.Text = "狀態: 拋竿蓄力中..."
        holdLeftClick()
        task.wait(CHARGE_TIME)
        releaseLeftClick()

        if not isRunning then break end

        statusLabel.Text = "狀態: 等待浮標生成..."
        local anchor = waitForAnchor(character, 15)

        if anchor and isRunning then
            statusLabel.Text = "狀態: 長按收線中..."
            task.wait(0.15)

            while isRunning and anchor and anchor.Parent == character do
                holdLeftClick()
                task.wait(0.05)
                anchor = getFishingAnchor(character)
            end

            releaseLeftClick()
            statusLabel.Text = "狀態: 魚上鉤，鬆開收線"

            if isRunning then
                statusLabel.Text = "狀態: 等待點擊收魚..."
                task.wait(CLICK_AFTER_FISH_DELAY)
                clickOnce()
                statusLabel.Text = "狀態: 完成一輪，準備重試"
            end
        else
            statusLabel.Text = "狀態: 未找到浮標，重試"
        end

        task.wait(0.5)
    end
    statusLabel.Text = "狀態: 已停止"
end

-- ---------------------------------------------------
-- 6. UI 事件與熱鍵監聽綁定
-- ---------------------------------------------------
local function toggleScript()
    isRunning = not isRunning

    if isRunning then
        toggleBtn.Text = "釣魚中... (ON)"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        loopTask = task.spawn(autoFishLoop)
    else
        toggleBtn.Text = "開始釣魚 (OFF)"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        releaseLeftClick()
        if loopTask then
            task.cancel(loopTask)
            loopTask = nil
        end
        statusLabel.Text = "狀態: 已停止"
    end
end

toggleBtn.MouseButton1Click:Connect(toggleScript)

manualBtn.MouseButton1Click:Connect(function()
    statusLabel.Text = "狀態: 執行手動點擊..."
    clickOnce()
    task.wait(0.3)
    if not isRunning then
        statusLabel.Text = "狀態: 待命"
    end
end)

chargeBox.FocusLost:Connect(function()
    local num = tonumber(chargeBox.Text)
    if num and num >= 0 then
        CHARGE_TIME = num
    else
        chargeBox.Text = tostring(CHARGE_TIME)
    end
end)

delayBox.FocusLost:Connect(function()
    local num = tonumber(delayBox.Text)
    if num and num >= 0 then
        CLICK_AFTER_FISH_DELAY = num
    else
        delayBox.Text = tostring(CLICK_AFTER_FISH_DELAY)
    end
end)

keybindBtn.MouseButton1Click:Connect(function()
    isBindingKey = true
    keybindBtn.Text = "請按下按鍵..."
    keybindBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end

    if isBindingKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            toggleKey = input.KeyCode
            keybindBtn.Text = "按鍵: [ " .. input.KeyCode.Name .. " ]"
            keybindBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            isBindingKey = false
        end
    else
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
            toggleScript()
        end
    end
end)
