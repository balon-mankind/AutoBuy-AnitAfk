-- 初始化變數與服務
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local isAntiAFKActive = false
local loopThread = nil

-- 確定 UI 放置位置
local targetGui = game:GetService("CoreGui") or (Players.LocalPlayer and Players.LocalPlayer:WaitForChild("PlayerGui"))
if not targetGui then return end

-- 避免重複執行產生多個 UI
if targetGui:FindFirstChild("AntiAFK_Panel") then
    targetGui:FindFirstChild("AntiAFK_Panel"):Destroy()
end

-- 建立主要的 ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiAFK_Panel"
ScreenGui.Parent = targetGui
ScreenGui.ResetOnSpawn = false

-- === 1. 深灰色背景面板 ===
local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Parent = ScreenGui
MainPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 24) -- 深灰色背景
MainPanel.Position = UDim2.new(0.4, 0, 0.3, 0) -- 初始畫面中偏上位置
MainPanel.Size = UDim2.new(0, 260, 0, 180) 
MainPanel.Active = true
MainPanel.Draggable = true -- 讓整個面板可以被拖曳

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 12)
PanelCorner.Parent = MainPanel

-- === 2. 標題文字 (改為 Anti-AFK) ===
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainPanel
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 0, 0, 15)
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "Anti-AFK"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 22 -- 稍微加大英文字體

-- === 3. 目前狀態提示文字 ===
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainPanel
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0, 42)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "目前狀態: 已關閉"
StatusLabel.TextColor3 = Color3.fromRGB(231, 76, 60) -- 預設紅色
StatusLabel.TextSize = 14

-- === 4. Anti-AFK 功能按鈕 ===
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = MainPanel
ToggleButton.BackgroundColor3 = Color3.fromRGB(192, 41, 43) -- 預設關閉為暗紅色
ToggleButton.Position = UDim2.new(0.08, 0, 0.44, 0)
ToggleButton.Size = UDim2.new(0, 218, 0, 42)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Anti-AFK: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 10)
ButtonCorner.Parent = ToggleButton

-- === 5. 底部提示小字 ===
local FooterLabel = Instance.new("TextLabel")
FooterLabel.Name = "FooterLabel"
FooterLabel.Parent = MainPanel
FooterLabel.BackgroundTransparency = 1
FooterLabel.Position = UDim2.new(0, 0, 1, -25)
FooterLabel.Size = UDim2.new(1, 0, 0, 20)
FooterLabel.Font = Enum.Font.SourceSansItalic
FooterLabel.Text = "按住標題列可拖曳視窗"
FooterLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
FooterLabel.TextSize = 12

-- === Anti-AFK 核心邏輯 (每 15 秒 A 與 D) ===
local function startAntiAFK()
    loopThread = task.spawn(function()
        while isAntiAFKActive do
            -- 按下 A 往左
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.A, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game)
            
            task.wait(0.2)
            
            -- 按下 D 往右
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
            
            -- 每 15 秒觸發一次
            task.wait(15)
        end
    end)
end

-- === 按鈕點擊切換事件 ===
ToggleButton.MouseButton1Click:Connect(function()
    isAntiAFKActive = not isAntiAFKActive
    
    if isAntiAFKActive then
        -- 切換為開啟狀態
        StatusLabel.Text = "目前狀態: 運作中"
        StatusLabel.TextColor3 = Color3.fromRGB(46, 204, 113) -- 綠色字
        
        ToggleButton.Text = "Anti-AFK: ON (15s)"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(39, 174, 96) -- 綠色按鈕
        
        startAntiAFK()
    else
        -- 切換為關閉狀態
        StatusLabel.Text = "目前狀態: 已關閉"
        StatusLabel.TextColor3 = Color3.fromRGB(231, 76, 60) -- 紅色字
        
        ToggleButton.Text = "Anti-AFK: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(192, 41, 43) -- 紅色按鈕
        
        if loopThread then
            task.cancel(loopThread)
            loopThread = nil
        end
    end
end)
