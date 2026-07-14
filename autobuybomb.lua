-- [[ Mountain RNG - 智能自動購買 + 獨立防踢 UI 控制面板 ]] --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

_G.AutoBuyBombs = false -- 預設關閉自動購買
_G.AntiAFKEnabled = true -- 預設開啟防踢功能

local CHECK_DELAY = 0.1  -- 有貨時的狂刷頻率（秒）
local SLEEP_DELAY = 60    -- 沒貨時的休眠冷卻時間（秒）

local targetBombs = {
    "ClassicBomb",
    "IceBomb",
    "ThunderBomb",
    "PoisonBomb",
    "WindBomb",
    "FireBomb",
    "TimeBomb",
    "AgonyBomb"
}

-- ==========================================================
-- 1. 獨立防踢 (Anti-AFK) 核心邏輯 - 每 30 秒執行一次
-- ==========================================================
task.spawn(function()
    while true do
        task.wait(30) -- 每 30 秒檢查並動一下
        if _G.AntiAFKEnabled then
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                print("[Anti-AFK] 已過 30 秒，自動在後台模擬點擊防止斷線。")
            end)
        end
    end
end)

-- 當偵測到 Idled 訊號時也雙重保險觸發
LocalPlayer.Idled:Connect(function()
    if _G.AntiAFKEnabled then
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end
end)

-- ==========================================================
-- 2. 建立精美 GUI 控制面板 (防止重複生成)
-- ==========================================================
if CoreGui:FindFirstChild("MountainRNG_AutoBuyUI") then
    CoreGui.MountainRNG_AutoBuyUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MountainRNG_AutoBuyUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- ==========================================================
-- 2. 建立精美 GUI 控制面板 (防止重複生成)
-- ==========================================================
if CoreGui:FindFirstChild("MountainRNG_AutoBuyUI") then
    CoreGui.MountainRNG_AutoBuyUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MountainRNG_AutoBuyUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- 主面板 (加高高度至 210，完美容納 3 個按鈕與底部提示字)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 210) -- 高度拉長到 210
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- 圓角
local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = MainFrame

-- 標題列
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Mountain RNG 助手"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Parent = MainFrame

-- 狀態提示
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0, 28)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "目前狀態: 已關閉"
StatusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Parent = MainFrame

-- 【自動購買切換按鈕】
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 180, 0, 32)
ToggleBtn.Position = UDim2.new(0.5, -90, 0, 55)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- 預設紅色 (OFF)
ToggleBtn.Text = "自動購買: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Parent = MainFrame

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 6)
BtnCorner1.Parent = ToggleBtn

-- 【Anti-AFK 切換按鈕】
local AfkBtn = Instance.new("TextButton")
AfkBtn.Name = "AfkBtn"
AfkBtn.Size = UDim2.new(0, 180, 0, 32)
AfkBtn.Position = UDim2.new(0.5, -90, 0, 95)
AfkBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- 預設綠色 (ON)
AfkBtn.Text = "Anti-AFK: ON (30s)"
AfkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AfkBtn.TextSize = 14
AfkBtn.Font = Enum.Font.SourceSansBold
AfkBtn.Parent = MainFrame

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 6)
BtnCorner2.Parent = AfkBtn

-- 【控制台分行按鈕】 (藍色美化版)
local DividerBtn = Instance.new("TextButton")
DividerBtn.Name = "DividerBtn"
DividerBtn.Size = UDim2.new(0, 180, 0, 32)
DividerBtn.Position = UDim2.new(0.5, -90, 0, 135) -- 放在 Anti-AFK 按鈕下方，間距為 8 像素
DividerBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 255) -- 經典藍色
DividerBtn.Text = "🧹 控制台分行 / 清理"
DividerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DividerBtn.TextSize = 13
DividerBtn.Font = Enum.Font.SourceSansBold
DividerBtn.AutoButtonColor = true -- 點擊時會有自動微弱變暗的反饋
DividerBtn.Parent = MainFrame

-- 給按鈕加上圓角
local BtnCorner3 = Instance.new("UICorner")
BtnCorner3.CornerRadius = UDim.new(0, 6)
BtnCorner3.Parent = DividerBtn

-- 點擊事件：在 Console 輸出精美的分段
DividerBtn.MouseButton1Click:Connect(function()
    print("\n\n" .. string.rep("=", 50))
end)

-- 版權/提示小標籤 (往下順移到底部，不與按鈕重疊)
local CreditLabel = Instance.new("TextLabel")
CreditLabel.Name = "CreditLabel"
CreditLabel.Size = UDim2.new(1, 0, 0, 20)
CreditLabel.Position = UDim2.new(0, 0, 0, 178) -- 往下移到 Y 軸 178
CreditLabel.BackgroundTransparency = 1
CreditLabel.Text = "按住標題列可拖曳視窗"
CreditLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
CreditLabel.TextSize = 10
CreditLabel.Font = Enum.Font.SourceSansItalic
CreditLabel.Parent = MainFrame

-- ==========================================================
-- 3. 核心購買與變數欺騙邏輯
-- ==========================================================
local function forceSetClientSelection(bombId)
    for _, v in pairs(getgc()) do
        if type(v) == "function" then
            local info = debug.getinfo(v)
            if info.name == "refreshAll" or info.name == "buildUI" or info.name == "doCashBuy" then
                for idx = 1, 50 do
                    local name, val = debug.getupvalue(v, idx)
                    if name == nil then break end
                    if name == "v10" then
                        debug.setupvalue(v, idx, bombId)
                    end
                end
            end
        end
    end
end

-- 智能監控後台循環
task.spawn(function()
    local BombBuyRequest = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("BombBuyRequest", 5)
    
    while true do
        task.wait(0.1)
        
        if _G.AutoBuyBombs and BombBuyRequest then
            local anyStockFound = false
            
            for _, bombId in pairs(targetBombs) do
                if not _G.AutoBuyBombs then break end
                
                forceSetClientSelection(bombId)
                
                pcall(function()
                    local response = BombBuyRequest:InvokeServer(bombId)
                    
                    if response and type(response) == "table" then
                        if response.ok == true then
                            anyStockFound = true
                            StatusLabel.Text = "正在購買: " .. tostring(bombId)
                            StatusLabel.TextColor3 = Color3.fromRGB(50, 200, 50)
                            print(string.format("⚡ [Start Buy] 成功購入: %s | 賸餘庫存: %s", tostring(bombId), tostring(response.remaining)))
                        elseif response.err == "nostock" then
                            -- 沒貨，跳過
                        elseif response.err == "cash" then
                            anyStockFound = true
                            StatusLabel.Text = "金幣不足購買: " .. tostring(bombId)
                            StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                        end
                    end
                end)
                
                task.wait(CHECK_DELAY)
            end
            
            -- 動態模式切換
            if _G.AutoBuyBombs then
                if not anyStockFound then
                    StatusLabel.Text = "無庫存，進入休眠中..."
                    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                    task.wait(SLEEP_DELAY)
                else
                    task.wait(CHECK_DELAY)
                end
            end
        end
    end
end)

-- ==========================================================
-- 4. UI 點擊事件綁定
-- ==========================================================

-- 自動購買開關
ToggleBtn.MouseButton1Click:Connect(function()
    _G.AutoBuyBombs = not _G.AutoBuyBombs
    
    if _G.AutoBuyBombs then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- 綠色
        ToggleBtn.Text = "自動購買: ON"
        StatusLabel.Text = "目前狀態: 監控中..."
        StatusLabel.TextColor3 = Color3.fromRGB(50, 200, 50)
        print("[UI 控制] 自動購買已啟動！")
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- 紅色
        ToggleBtn.Text = "自動購買: OFF"
        StatusLabel.Text = "目前狀態: 已關閉"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        print("[UI 控制] 自動購買已停止！")
    end
end)

-- Anti-AFK 開關
AfkBtn.MouseButton1Click:Connect(function()
    _G.AntiAFKEnabled = not _G.AntiAFKEnabled
    
    if _G.AntiAFKEnabled then
        AfkBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- 綠色
        AfkBtn.Text = "Anti-AFK: ON (30s)"
        print("[UI 控制] Anti-AFK 防踢功能已開啟（每 30 秒在後台動一下）。")
    else
        AfkBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- 紅色
        AfkBtn.Text = "Anti-AFK: OFF"
        print("[UI 控制] Anti-AFK 防踢功能已關閉。")
    end
end)
