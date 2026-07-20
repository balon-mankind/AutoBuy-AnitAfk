-- ===================================================
-- Roblox 自動釣魚腳本 (背景虛擬輸入版 - 不搶實體滑鼠)
-- ===================================================

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local isRunning = false
local loopTask = nil

-- ---------------------------------------------------
-- ⚙️ 可調整參數設定
-- ---------------------------------------------------
local CHARGE_TIME = 0.700             -- 拋竿蓄力時間 (秒)
local CLICK_AFTER_FISH_DELAY = 0.8   -- 收魚後等待多久點擊一下 (秒)

-- ---------------------------------------------------
-- 1. UI 開關介面
-- ---------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFishAnchorGuiV10"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleLabel.Text = "背景釣魚 v10.0 (不卡滑鼠)"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0.45, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.Text = "開始釣魚 (OFF)"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 16
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Parent = mainFrame

-- ---------------------------------------------------
-- 2. 純遊戲內部虛擬輸入 (完全不占用 OS 實體滑鼠)
-- ---------------------------------------------------
local function holdLeftClick()
    -- 發送引擎層級的虛擬按壓信號
    VirtualUser:Button1Down(Vector2.new(0, 0), Camera and Camera.CFrame or CFrame.new())
    VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 0)
end

local function releaseLeftClick()
    -- 發送引擎層級的虛擬釋放信號
    VirtualUser:Button1Up(Vector2.new(0, 0), Camera and Camera.CFrame or CFrame.new())
    VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 0)
end

local function clickOnce()
    holdLeftClick()
    task.wait(0.08)
    releaseLeftClick()
end

-- ---------------------------------------------------
-- 3. 搜尋 FishingAnchor
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
-- 4. 主要邏輯迴圈
-- ---------------------------------------------------
local function autoFishLoop()
    while isRunning do
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            task.wait(1)
            continue
        end

        -- 🎯 步驟 1: 虛擬拋竿蓄力
        print("[AutoFish] 1. 發送虛擬按壓訊號拋竿 (蓄力 " .. tostring(CHARGE_TIME) .. " 秒)...")
        holdLeftClick()
        task.wait(CHARGE_TIME)
        releaseLeftClick()

        if not isRunning then break end

        -- 🎯 步驟 2: 等待 FishingAnchor 生成
        print("[AutoFish] 2. 等待 FishingAnchor 生成...")
        local anchor = waitForAnchor(character, 15)

        -- 🎯 步驟 3: 偵測到 FishingAnchor 後虛擬長按收線
        if anchor and isRunning then
            print("[AutoFish] 3. 偵測到 " .. anchor.Name .. "！背景長按收線中...")
            
            task.wait(0.15)

            -- 只要 FishingAnchor 還在，持續維持虛擬按壓
            while isRunning and anchor and anchor.Parent == character do
                holdLeftClick()
                task.wait(0.05)
                anchor = getFishingAnchor(character)
            end

            -- 鬆開虛擬長按
            releaseLeftClick()
            print("[AutoFish] 4. FishingAnchor 已消失，鬆開虛擬按壓！")

            -- 🎯 步驟 4: 收魚點擊
            if isRunning then
                print("[AutoFish] 5. 等待 " .. tostring(CLICK_AFTER_FISH_DELAY) .. " 秒後發送虛擬點擊收魚...")
                task.wait(CLICK_AFTER_FISH_DELAY)
                clickOnce()
                print("[AutoFish] 完成收魚！進入下一輪...")
            end
        else
            print("[AutoFish] 未能偵測到 FishingAnchor 或已超時，重試中...")
        end

        task.wait(0.5)
    end
end

-- ---------------------------------------------------
-- 5. 開關按鈕綁定
-- ---------------------------------------------------
toggleBtn.MouseButton1Click:Connect(function()
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
    end
end)
