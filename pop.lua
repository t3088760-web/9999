-- =========================================================================
-- KAIJU RODAN V6.8.0 — WHITELIST / VERIFICATION REMOVED
-- =========================================================================

-- =========================================================================
-- [SECTION 1] SERVICES
-- =========================================================================
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- =========================================================================
-- [SECTION 2] CLEANUP OLD CONNECTIONS (from previous runs)
-- =========================================================================
if _G.a then
    for _, connection in pairs(_G.a) do
        pcall(function() connection:Disconnect() end)
    end
    _G.a = nil
end

-- =========================================================================
-- [SECTION 3] STATE VARIABLES
-- =========================================================================
local OwnerName = LP.Name
local petMode = false
local flying = false
local noclip = false
local IsInvisible = false
local IsTransitioning = false
local isReloading = false
local isMinimized = false

local flySpeed = 1
local vVect = 0

-- OVERCLOCKED CACHE & ASYNC BYPASS BUFFERS --
local PROP_CACHE = {}
local CURRENT_CFRAMES = {}
local TARGET_CFRAMES = {}
local LAST_SEND_TIME = {}
local COLOR_SENDING = {}
local NETWORK_STATE = {}
local lastColorUpdate = 0
local colorIndex = 1
local originalPos = nil
local snapNextFrame = false
local TOTAL_MAX_PROPS = 90

-- NETWORK BYPASS TUNING & ADAPTIVE SIGNAL SAFETY --
local BASE_TICK_RATE = 0.015
local NETWORK_TICK_RATE = 0.015
local estimatedPing = 0.03
local lastPosition = Vector3.zero
local smoothedMouseX = 0
local MAX_CHOKE_TIMEOUT = 0.05

-- CINEMATIC MANEUVER SPEED ADJUSTMENT --
local currentRoll = 0
local MAX_ROLL = 32
local ROLL_SPEED = 6.5
local BASE_RETURN_SPEED = 12

local MANUAL_ROTATION = Vector3.new(200, 270, 20)
local VirtualRootCFrame = CFrame.new()

-- =========================================================================
-- [SECTION 4] COLORS
-- =========================================================================
local COLORS = {
    AbyssRed  = Color3.fromRGB(150, 0, 5),
    DarkAbyss = Color3.fromRGB(35, 2, 2),
    Magma     = Color3.fromRGB(245, 60, 0),
    Accent    = Color3.fromRGB(255, 45, 0)
}

local function getAbyssColor(t, offset)
    local cycle = (t * 0.3 + (offset * 0.15)) % 1
    if cycle < 0.33 then
        return COLORS.Magma:Lerp(COLORS.AbyssRed, cycle * 3)
    elseif cycle < 0.66 then
        return COLORS.AbyssRed:Lerp(COLORS.DarkAbyss, (cycle - 0.33) * 3)
    else
        return COLORS.DarkAbyss:Lerp(COLORS.Magma, (cycle - 0.66) * 3)
    end
end

-- =========================================================================
-- [SECTION 5] PROP VALIDATION
-- =========================================================================
local function UpdateAndValidateRodanProps()
    local targetFolder = workspace:FindFirstChild("WorkspaceCom") and workspace.WorkspaceCom:FindFirstChild("001_TrafficCones")
    if not targetFolder then return false end

    local targetPropName = "Prop" .. OwnerName
    if OwnerName == "terasiremik" then targetPropName = "Propterasiremik" end

    for id, storedProp in pairs(PROP_CACHE) do
        if not storedProp or not storedProp.Parent then
            PROP_CACHE[id] = nil
            CURRENT_CFRAMES[id] = nil
            TARGET_CFRAMES[id] = nil
            LAST_SEND_TIME[id] = nil
            COLOR_SENDING[id] = nil
            NETWORK_STATE[id] = nil
        end
    end

    for _, child in ipairs(targetFolder:GetChildren()) do
        if child.Name == targetPropName then
            local alreadyRegistered = false
            for _, storedProp in pairs(PROP_CACHE) do
                if storedProp == child then alreadyRegistered = true break end
            end

            if not alreadyRegistered then
                for id = 1, TOTAL_MAX_PROPS do
                    if not PROP_CACHE[id] then
                        PROP_CACHE[id] = child
                        CURRENT_CFRAMES[id] = nil
                        TARGET_CFRAMES[id] = nil
                        LAST_SEND_TIME[id] = 0
                        COLOR_SENDING[id] = false
                        NETWORK_STATE[id] = false
                        break
                    end
                end
            end
        end
    end
    return true
end

local function getBombCount()
    local count = 0
    local bp = LP:FindFirstChild("Backpack")
    local char = LP.Character
    if bp then for _, item in pairs(bp:GetChildren()) do if item.Name == "Bomb" then count = count + 1 end end end
    if char then for _, item in pairs(char:GetChildren()) do if item.Name == "Bomb" then count = count + 1 end end end
    return count
end

-- =========================================================================
-- [SECTION 6] ASSET DATA — ANIMATION CFrame GROUPS
-- =========================================================================
local function getOff(base, target) return base:ToObjectSpace(target) end
local baseRef = CFrame.new(-22.5595, 85.1412, 443.6309, 0.0333, -0.0396, -0.9987, -0.2914, -0.9562, 0.0282, -0.9559, 0.2903, -0.0434)

local AnimationStates = {
    Idle = {
        getOff(baseRef, CFrame.new(-22.5595, 85.1412, 443.6309, 0.0333, -0.0396, -0.9987, -0.2914, -0.9562, 0.0282, -0.9559, 0.2903, -0.0434)),
        getOff(baseRef, CFrame.new(-22.5789, 80.8101, 445.0938, 0.0340, -0.0241, 0.9991, -0.0262, 0.9993, 0.0250, -0.9990, -0.0270, 0.0333)),
        getOff(baseRef, CFrame.new(-22.3849, 81.0340, 440.4468, 0.9990, 0.0017, -0.0442, 0.0118, 0.9530, 0.3028, 0.0426, -0.3031, 0.9521)),
        getOff(baseRef, CFrame.new(-22.6916, 80.7880, 464.2337, -0.0291, -0.0019, -0.9996, 0.9654, 0.2594, -0.0286, 0.2592, -0.9658, -0.0057)),
        getOff(baseRef, CFrame.new(-22.1016, 81.5662, 471.3340, -0.9998, -0.0207, 0.0054, -0.0064, 0.0485, -0.9988, 0.0204, -0.9986, -0.0486)),
        getOff(baseRef, CFrame.new(-23.6430, 81.5647, 471.4639, -0.0524, -0.0711, -0.9961, 0.9974, 0.0459, -0.0558, 0.0497, -0.9964, 0.0685)),
        getOff(baseRef, CFrame.new(-22.4462, 81.5582, 471.2482, -0.0266, 0.1563, -0.9873, 0.9985, 0.0523, -0.0186, 0.0487, -0.9863, -0.1574)),
        getOff(baseRef, CFrame.new(-22.5154, 84.0416, 442.6541, 0.9994, -0.0112, -0.0323, 0.0204, 0.9542, 0.2985, 0.0275, -0.2991, 0.9538)),
        getOff(baseRef, CFrame.new(-22.8075, 82.4058, 469.3398, 0.9994, -0.0215, -0.0266, 0.0204, 0.9989, -0.0431, 0.0275, 0.0425, 0.9987)),
        getOff(baseRef, CFrame.new(-23.1931, 81.8592, 473.4248, -0.6977, 0.0000, 0.7163, 0.0000, 1.0000, 0.0000, -0.7163, 0.0000, -0.6977)),
        getOff(baseRef, CFrame.new(-26.7159, 78.4614, 469.7310, -0.1434, 0.4658, -0.8732, -0.4628, 0.7483, 0.4752, 0.8748, 0.4722, 0.1082)),
        getOff(baseRef, CFrame.new(-19.3005, 78.2772, 469.4558, -0.0740, -0.4505, 0.8897, 0.4224, 0.7940, 0.4372, -0.9034, 0.4082, 0.1316)),
        getOff(baseRef, CFrame.new(-27.5673, 73.0421, 474.7500, -0.1077, 0.5521, -0.8268, -0.8913, 0.3147, 0.3263, 0.4404, 0.7720, 0.4582)),
        getOff(baseRef, CFrame.new(-18.7817, 73.0421, 474.6388, -0.0892, -0.2259, 0.9701, 0.8718, 0.4533, 0.1857, -0.4817, 0.8622, 0.1565)),
        getOff(baseRef, CFrame.new(-30.2974, 81.1854, 458.7873, -0.2865, 0.0418, -0.9572, 0.0390, 0.9987, 0.0319, 0.9573, -0.0282, -0.2878)),
        getOff(baseRef, CFrame.new(-32.5398, 81.4400, 464.2003, -0.3835, 0.0417, -0.9226, 0.0420, 0.9987, 0.0277, 0.9226, -0.0281, -0.3847)),
        getOff(baseRef, CFrame.new(-43.1402, 81.7131, 457.8232, -0.2865, 0.0418, -0.9572, 0.0390, 0.9987, 0.0319, 0.9573, -0.0282, -0.2878)),
        getOff(baseRef, CFrame.new(-44.6870, 81.9124, 460.8935, -0.3835, 0.0417, -0.9226, 0.0420, 0.9987, 0.0277, 0.9226, -0.0281, -0.3847)),
        getOff(baseRef, CFrame.new(-57.6802, 82.2183, 457.7902, -0.0994, 0.0418, -0.9942, 0.0322, 0.9987, 0.0388, 0.9945, -0.0281, -0.1006)),
        getOff(baseRef, CFrame.new(-51.4529, 82.2079, 463.7776, -0.3892, 0.0418, -0.9202, 0.0421, 0.9987, 0.0275, 0.9202, -0.0281, -0.3904)),
        getOff(baseRef, CFrame.new(-65.6964, 82.5774, 459.7799, -0.0994, 0.0418, -0.9942, 0.0322, 0.9987, 0.0388, 0.9945, -0.0281, -0.1006)),
        getOff(baseRef, CFrame.new(-73.0331, 83.0297, 462.0041, -0.0994, 0.0418, -0.9942, 0.0322, 0.9987, 0.0388, 0.9945, -0.0281, -0.1006)),
        getOff(baseRef, CFrame.new(-13.7991, 81.7321, 459.2469, 0.2241, 0.0166, 0.9744, 0.0652, -0.9979, 0.0020, 0.9724, 0.0630, -0.2247)),
        getOff(baseRef, CFrame.new(-13.3212, 82.1667, 463.4998, 0.3954, 0.0166, 0.9183, 0.0644, -0.9979, -0.0097, 0.9163, 0.0630, -0.3957)),
        getOff(baseRef, CFrame.new(0.9693, 82.1488, 458.9337, 0.2241, 0.0166, 0.9744, 0.0652, -0.9979, 0.0020, 0.9724, 0.0630, -0.2247)),
        getOff(baseRef, CFrame.new(-0.2478, 82.3851, 463.2268, 0.3954, 0.0166, 0.9183, 0.0644, -0.9979, -0.0097, 0.9163, 0.0630, -0.3957)),
        getOff(baseRef, CFrame.new(14.5757, 82.3199, 459.3643, 0.0935, 0.0166, 0.9955, 0.0643, -0.9979, 0.0106, 0.9935, 0.0630, -0.0944)),
        getOff(baseRef, CFrame.new(7.8667, 82.6986, 464.9568, 0.3954, 0.0166, 0.9183, 0.0644, -0.9979, -0.0097, 0.9163, 0.0630, -0.3957)),
        getOff(baseRef, CFrame.new(22.3444, 82.5508, 461.3820, 0.0935, 0.0166, 0.9955, 0.0643, -0.9979, 0.0106, 0.9935, 0.0630, -0.0944)),
        getOff(baseRef, CFrame.new(29.8605, 82.5508, 463.4437, 0.0935, 0.0166, 0.9955, 0.0643, -0.9979, 0.0106, 0.9935, 0.0630, -0.0944))
    },
    Sayap1 = {
        getOff(baseRef, CFrame.new(-22.5595, 85.1412, 443.6309, 0.0333, -0.0396, -0.9987, -0.2914, -0.9562, 0.0282, -0.9559, 0.2903, -0.0434)),
        getOff(baseRef, CFrame.new(-22.6780, 79.2367, 446.3270, 0.0637, 0.0353, 0.9973, -0.6697, 0.7424, 0.0164, -0.7399, -0.6691, 0.0710)),
        getOff(baseRef, CFrame.new(-22.3849, 81.0340, 440.4468, 0.9990, 0.0017, -0.0442, 0.0118, 0.9530, 0.3028, 0.0426, -0.3031, 0.9521)),
        getOff(baseRef, CFrame.new(-22.6916, 80.7880, 464.2337, -0.0291, -0.0019, -0.9996, 0.9654, 0.2594, -0.0286, 0.2592, -0.9658, -0.0057)),
        getOff(baseRef, CFrame.new(-22.1016, 81.5662, 471.3340, -0.9998, -0.0207, 0.0054, -0.0064, 0.0485, -0.9988, 0.0204, -0.9986, -0.0486)),
        getOff(baseRef, CFrame.new(-23.6430, 81.5647, 471.4639, -0.0524, -0.0711, -0.9961, 0.9974, 0.0459, -0.0558, 0.0497, -0.9964, 0.0685)),
        getOff(baseRef, CFrame.new(-22.4462, 81.5582, 471.2483, -0.0266, 0.1563, -0.9873, 0.9985, 0.0523, -0.0186, 0.0487, -0.9863, -0.1574)),
        getOff(baseRef, CFrame.new(-22.5154, 84.0416, 442.6541, 0.9994, -0.0112, -0.0323, 0.0204, 0.9542, 0.2985, 0.0275, -0.2991, 0.9538)),
        getOff(baseRef, CFrame.new(-22.8075, 82.4058, 469.3398, 0.9994, -0.0215, -0.0266, 0.0204, 0.9989, -0.0431, 0.0275, 0.0425, 0.9987)),
        getOff(baseRef, CFrame.new(-23.1931, 81.8593, 473.4248, -0.6977, 0.0000, 0.7163, 0.0000, 1.0000, 0.0000, -0.7163, 0.0000, -0.6977)),
        getOff(baseRef, CFrame.new(-26.7160, 78.4614, 469.7310, -0.1434, 0.4658, -0.8732, -0.4628, 0.7483, 0.4752, 0.8748, 0.4722, 0.1082)),
        getOff(baseRef, CFrame.new(-19.3006, 78.2772, 469.4558, -0.0740, -0.4505, 0.8897, 0.4224, 0.7940, 0.4372, -0.9034, 0.4082, 0.1316)),
        getOff(baseRef, CFrame.new(-27.5672, 73.0421, 474.7500, -0.1077, 0.5521, -0.8268, -0.8913, 0.3147, 0.3263, 0.4404, 0.7720, 0.4582)),
        getOff(baseRef, CFrame.new(-18.7816, 73.0421, 474.6388, -0.0892, -0.2259, 0.9701, 0.8718, 0.4533, 0.1857, -0.4817, 0.8622, 0.1565)),
        getOff(baseRef, CFrame.new(-30.2974, 87.3520, 458.7873, -0.2865, 0.7635, -0.5787, 0.0390, 0.6128, 0.7892, 0.9573, 0.2035, -0.2053)),
        getOff(baseRef, CFrame.new(-31.0376, 86.4189, 465.0055, -0.3668, 0.7318, -0.5744, 0.0154, 0.6222, 0.7827, 0.9302, 0.2782, -0.2394)),
        getOff(baseRef, CFrame.new(-35.1951, 94.3106, 458.5383, -0.2866, 0.7856, -0.5483, 0.0390, 0.5814, 0.8127, 0.9573, 0.2115, -0.1973)),
        getOff(baseRef, CFrame.new(-37.0568, 94.6899, 463.6446, -0.3835, 0.7563, -0.5301, 0.0420, 0.5877, 0.8080, 0.9226, 0.2876, -0.2571)),
        getOff(baseRef, CFrame.new(-44.4361, 103.7627, 459.3284, -0.0994, 0.6035, -0.7911, 0.0321, 0.7966, 0.6036, 0.9945, 0.0345, -0.0986)),
        getOff(baseRef, CFrame.new(-46.2724, 104.4155, 463.9917, -0.3623, 0.5958, -0.7168, 0.0414, 0.7786, 0.6262, 0.9312, 0.1973, -0.3067)),
        getOff(baseRef, CFrame.new(-56.7099, 111.9764, 460.7517, -0.0994, 0.5346, -0.8392, 0.0322, 0.8447, 0.5343, 0.9945, 0.0261, -0.1011)),
        getOff(baseRef, CFrame.new(-62.8999, 116.3212, 463.1172, 0.0256, 0.5344, -0.8449, -0.0942, 0.8427, 0.5301, 0.9952, 0.0661, 0.0719)),
        getOff(baseRef, CFrame.new(-15.8458, 88.2828, 459.6700, 0.2241, 0.8220, 0.5236, 0.0652, -0.5487, 0.8335, 0.9724, -0.1527, -0.1765)),
        getOff(baseRef, CFrame.new(-14.9415, 86.9702, 465.9330, 0.3954, 0.7680, 0.5039, 0.0642, -0.5703, 0.8189, 0.9163, -0.2915, -0.2748)),
        getOff(baseRef, CFrame.new(-11.3941, 94.4157, 460.5518, 0.2241, 0.8178, 0.5300, 0.0652, -0.5552, 0.8292, 0.9724, -0.1512, -0.1778)),
        getOff(baseRef, CFrame.new(-10.1467, 93.9770, 465.4979, 0.3954, 0.7739, 0.4947, 0.0645, -0.5606, 0.8256, 0.9163, -0.2926, -0.2736)),
        getOff(baseRef, CFrame.new(-1.3480, 105.1433, 461.0664, 0.0936, 0.6823, 0.7251, 0.0643, -0.7309, 0.6795, 0.9935, -0.0170, -0.1123)),
        getOff(baseRef, CFrame.new(-0.7845, 105.5440, 465.4377, 0.2161, 0.6870, 0.6938, 0.1810, -0.7264, 0.6630, 0.9594, -0.0180, -0.2815)),
        getOff(baseRef, CFrame.new(10.1705, 114.7232, 462.4572, 0.0935, 0.5650, 0.8198, 0.0643, -0.8251, 0.5613, 0.9935, -0.0003, -0.1135)),
        getOff(baseRef, CFrame.new(16.3167, 118.9204, 464.3803, 0.0935, 0.5419, 0.8352, 0.0643, -0.8404, 0.5381, 0.9935, 0.0044, -0.1134))
    },
    Sayap2 = {
        getOff(baseRef, CFrame.new(-22.5595, 85.1412, 443.6309, 0.0333, -0.0396, -0.9987, -0.2914, -0.9562, 0.0282, -0.9559, 0.2903, -0.0434)),
        getOff(baseRef, CFrame.new(-22.5789, 80.8101, 445.0938, 0.0340, -0.0241, 0.9991, -0.0262, 0.9993, 0.0250, -0.9990, -0.0270, 0.0333)),
        getOff(baseRef, CFrame.new(-22.3849, 81.0340, 440.4468, 0.9990, 0.0017, -0.0442, 0.0118, 0.9530, 0.3028, 0.0426, -0.3031, 0.9521)),
        getOff(baseRef, CFrame.new(-22.6916, 80.7880, 464.2337, -0.0291, -0.0019, -0.9996, 0.9654, 0.2594, -0.0286, 0.2592, -0.9658, -0.0057)),
        getOff(baseRef, CFrame.new(-22.1016, 81.5662, 471.3340, -0.9998, -0.0207, 0.0054, -0.0064, 0.0485, -0.9988, 0.0204, -0.9986, -0.0486)),
        getOff(baseRef, CFrame.new(-23.6431, 81.5647, 471.4640, -0.0524, -0.0711, -0.9961, 0.9974, 0.0459, -0.0558, 0.0497, -0.9964, 0.0685)),
        getOff(baseRef, CFrame.new(-22.4461, 81.5582, 471.2483, -0.0266, 0.1563, -0.9873, 0.9985, 0.0523, -0.0186, 0.0487, -0.9863, -0.1574)),
        getOff(baseRef, CFrame.new(-22.5154, 84.0416, 442.6541, 0.9994, -0.0112, -0.0323, 0.0204, 0.9542, 0.2985, 0.0275, -0.2991, 0.9538)),
        getOff(baseRef, CFrame.new(-22.8075, 82.4058, 469.3398, 0.9994, -0.0215, -0.0266, 0.0204, 0.9989, -0.0431, 0.0275, 0.0425, 0.9987)),
        getOff(baseRef, CFrame.new(-23.1931, 81.8593, 473.4248, -0.6977, 0.0000, 0.7163, 0.0000, 1.0000, 0.0000, -0.7163, 0.0000, -0.6977)),
        getOff(baseRef, CFrame.new(-26.7160, 79.7945, 469.7310, -0.1243, 0.7114, -0.6917, -0.2399, 0.6549, 0.7166, 0.9628, 0.2550, 0.0893)),
        getOff(baseRef, CFrame.new(-19.3006, 79.8250, 469.4558, -0.0761, -0.8654, 0.4953, 0.2021, 0.4730, 0.8575, -0.9764, 0.1654, 0.1389)),
        getOff(baseRef, CFrame.new(-27.5672, 77.4616, 474.7500, -0.0326, 0.7860, -0.6174, -0.5440, 0.5042, 0.6707, 0.8385, 0.3577, 0.4111)),
        getOff(baseRef, CFrame.new(-18.7816, 77.2141, 474.6388, -0.0463, -0.7991, 0.5994, 0.4710, 0.5117, 0.7186, -0.8812, 0.3155, 0.3522)),
        getOff(baseRef, CFrame.new(-30.6059, 77.4405, 459.8058, -0.2865, -0.7144, -0.6384, 0.0390, 0.6571, -0.7528, 0.9573, -0.2394, 0.1604)),
        getOff(baseRef, CFrame.new(-32.5282, 77.0920, 464.3739, -0.3835, -0.6936, -0.6098, 0.0419, 0.6465, -0.7618, 0.9226, -0.3178, 0.2193)),
        getOff(baseRef, CFrame.new(-41.2200, 66.9823, 460.0205, -0.2866, -0.6515, -0.7025, 0.0389, 0.7247, -0.6880, 0.9573, -0.2244, 0.1807)),
        getOff(baseRef, CFrame.new(-42.7692, 66.8548, 463.7298, -0.3835, -0.6354, -0.6702, 0.0420, 0.7129, -0.7000, 0.9226, -0.2974, 0.2458)),
        getOff(baseRef, CFrame.new(-52.0596, 57.3928, 461.0674, -0.0994, -0.6672, -0.7382, 0.0322, 0.7393, -0.6726, 0.9945, -0.0906, 0.0519)),
        getOff(baseRef, CFrame.new(-53.5080, 56.9920, 463.2140, -0.3893, -0.6342, -0.6680, 0.0422, 0.7122, -0.7008, 0.9202, -0.3006, 0.2505)),
        getOff(baseRef, CFrame.new(-63.0564, 48.7751, 462.9189, -0.0735, -0.6140, -0.7859, 0.0312, 0.7862, -0.6171, 0.9968, -0.0699, -0.0385)),
        getOff(baseRef, CFrame.new(-69.2299, 44.2951, 465.2740, -0.0993, -0.6078, -0.7879, 0.0322, 0.7894, -0.6130, 0.9945, -0.0864, 0.0587)),
        getOff(baseRef, CFrame.new(-14.1310, 77.9609, 460.3540, 0.2241, -0.7537, 0.6178, 0.0652, -0.6210, -0.7811, 0.9724, 0.2153, -0.0898)),
        getOff(baseRef, CFrame.new(-13.0676, 78.5066, 464.7146, 0.3954, -0.7045, 0.5894, 0.0643, -0.6189, -0.7829, 0.9163, 0.3473, -0.1985)),
        getOff(baseRef, CFrame.new(-3.5625, 67.2963, 461.5082, 0.2240, -0.6615, 0.7157, 0.0653, -0.7226, -0.6882, 0.9724, 0.2008, -0.1189)),
        getOff(baseRef, CFrame.new(-2.4200, 67.2051, 465.4780, 0.3953, -0.6525, 0.6465, 0.0644, -0.6824, -0.7282, 0.9163, 0.3292, -0.2274)),
        getOff(baseRef, CFrame.new(7.4989, 57.7637, 463.3781, 0.0936, -0.6146, 0.7833, 0.0643, -0.7814, -0.6208, 0.9935, 0.1085, -0.0345)),
        getOff(baseRef, CFrame.new(8.7736, 57.7183, 465.1112, 0.3955, -0.5578, 0.7296, 0.0644, -0.7756, -0.6279, 0.9163, 0.2952, -0.2708)),
        getOff(baseRef, CFrame.new(19.6615, 49.0577, 465.5342, 0.0935, -0.5649, 0.8199, 0.0644, -0.8183, -0.5711, 0.9935, 0.0927, -0.0654)),
        getOff(baseRef, CFrame.new(25.8495, 45.0519, 467.9508, 0.0935, -0.5795, 0.8096, 0.0643, -0.8079, -0.5857, 0.9935, 0.0961, -0.0601))
    }
}

-- =========================================================================
-- [SECTION 7] UI CONSTRUCTION
-- =========================================================================
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "Rodan_Kaiju_Overclock_Hub"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 200, 0, 455)
main.Position = UDim2.new(0.05, 0, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(15, 3, 2)
main.BorderSizePixel = 0
main.ClipsDescendants = true

local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = COLORS.DarkAbyss
titleBar.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 8, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Kaiju Rodan V6.8.0 (Bypass)"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", titleBar)
MinBtn.Size = UDim2.new(0, 22, 0, 22)
MinBtn.Position = UDim2.new(1, -26, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(10, 2, 2)
MinBtn.BorderSizePixel = 1
MinBtn.BorderColor3 = COLORS.DarkAbyss
MinBtn.Text = "▲"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 12
local btnCorner = Instance.new("UICorner", MinBtn)
btnCorner.CornerRadius = UDim.new(0, 4)

local contentContainer = Instance.new("Frame", main)
contentContainer.Size = UDim2.new(1, 0, 1, -30)
contentContainer.Position = UDim2.new(0, 0, 0, 30)
contentContainer.BackgroundTransparency = 1
contentContainer.ClipsDescendants = true

-- UI DRAG HANDLERS --
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

local function styleBtn(b)
    b.BackgroundColor3, b.BorderSizePixel, b.BorderColor3 = Color3.fromRGB(15, 2, 2), 1, COLORS.DarkAbyss
    b.TextColor3, b.Font, b.TextSize = Color3.new(0.85, 0.8, 0.8), Enum.Font.SourceSansBold, 11
    b.MouseEnter:Connect(function() b.BorderColor3 = COLORS.Accent b.TextColor3 = Color3.new(1,1,1) end)
    b.MouseLeave:Connect(function() b.BorderColor3 = COLORS.DarkAbyss b.TextColor3 = Color3.new(0.85,0.8,0.8) end)
end

local function createBtn(txt, pos, size, parent)
    local b = Instance.new("TextButton", parent or contentContainer)
    b.Text, b.Position, b.Size = txt, pos, size styleBtn(b)
    return b
end

local b2Frame = Instance.new("Frame", contentContainer)
b2Frame.Size = UDim2.new(1, -10, 0, 160)
b2Frame.Position = UDim2.new(0, 5, 0, 5)
b2Frame.BackgroundTransparency = 1

local SummonBtn = createBtn("SUMMON RODAN KAIJU", UDim2.new(0,0,0,0), UDim2.new(1,0,0.22,0), b2Frame)
local fBtn      = createBtn("Fly: OFF", UDim2.new(0.5,2,0.26,0), UDim2.new(0.5,-2,0.22,0), b2Frame)
local upBtn     = createBtn("UP", UDim2.new(0,0,0.26,0), UDim2.new(0.25,-2,0.22,0), b2Frame)
local dnBtn     = createBtn("DN", UDim2.new(0.25,0,0.26,0), UDim2.new(0.25,-2,0.22,0), b2Frame)
local plusBtn   = createBtn("+" , UDim2.new(0.5,2,0.52,0), UDim2.new(0.25,-2,0.22,0), b2Frame)
local minusBtn  = createBtn("-", UDim2.new(0.75,2,0.52,0), UDim2.new(0.25,-2,0.22,0), b2Frame)
local sNum      = createBtn("SPD: 1", UDim2.new(0,0,0.52,0), UDim2.new(0.5,-2,0.22,0), b2Frame)
local cBtn      = createBtn("Noclip: OFF", UDim2.new(0,0,0.78,0), UDim2.new(1,0,0.22,0), b2Frame)

local line = Instance.new("Frame", contentContainer)
line.Size = UDim2.new(1, -10, 0, 1)
line.Position = UDim2.new(0, 5, 0, 175)
line.BackgroundColor3 = COLORS.DarkAbyss
line.BorderSizePixel = 0

local bombFrame = Instance.new("Frame", contentContainer)
bombFrame.Size = UDim2.new(1, -10, 0, 225)
bombFrame.Position = UDim2.new(0, 5, 0, 185)
bombFrame.BackgroundTransparency = 1

local Counter = Instance.new("TextLabel", bombFrame)
Counter.Size = UDim2.new(1, 0, 0, 25)
Counter.Position = UDim2.new(0, 0, 0, 0)
Counter.Text = "BOMBS COUNTER: 0"
Counter.TextColor3 = Color3.fromRGB(255, 255, 255)
Counter.Font = Enum.Font.SourceSansBold
Counter.TextSize = 13
Counter.BackgroundTransparency = 1

local bReload = createBtn("AUTO RELOAD + TP", UDim2.new(0,0,0.14,0), UDim2.new(1,0,0.16,0), bombFrame)
local bEquip  = createBtn("EQUIP ALL BOMBS", UDim2.new(0,0,0.33,0), UDim2.new(1,0,0.16,0), bombFrame)
local bBlast  = createBtn("BLAST CANNON", UDim2.new(0,0,0.52,0), UDim2.new(1,0,0.18,0), bombFrame)
bBlast.BackgroundColor3 = Color3.fromRGB(140, 25, 0)

local bDetonate = createBtn("DETONATE ALL BOMBS", UDim2.new(0,0,0.73,0), UDim2.new(1,0,0.18,0), bombFrame)
bDetonate.BackgroundColor3 = Color3.fromRGB(70, 5, 0)

local invBtn   = createBtn("INVISIBLE: OFF", UDim2.new(0,0,0.93,0), UDim2.new(1,0,0.16,0), bombFrame)

local creditLabel = Instance.new("TextLabel", contentContainer)
creditLabel.Size = UDim2.new(1, 0, 0, 15)
creditLabel.Position = UDim2.new(0, 0, 1, -15)
creditLabel.BackgroundTransparency = 1
creditLabel.Text = "Engine: DYTON_txt"
creditLabel.TextColor3 = COLORS.Accent
creditLabel.Font = Enum.Font.Code
creditLabel.TextSize = 9

-- =========================================================================
-- [SECTION 8] CHARACTER / PHYSICS HELPERS
-- =========================================================================
local VisibleParts = {}
local function SetupCharacter()
    local char = LP.Character or LP.CharacterAdded:Wait()
    VisibleParts = {}
    for _, d in pairs(char:GetDescendants()) do
        if (d:IsA("BasePart") or d:IsA("Decal")) and d.Name ~= "HumanoidRootPart" then
            table.insert(VisibleParts, d)
        end
    end
end

local function restoreNaturalCollision(char)
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            local name = v.Name:lower()
            v.CanCollide = (name:find("torso") or name:find("root") or name:find("leg") or name:find("head")) and not noclip
        end
    end
end

local function resetPhysics(char)
    if not char then return end
    local hum, root = char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart")
    if hum then hum.PlatformStand = false hum:ChangeState(Enum.HumanoidStateType.Running) end
    if root then
        if root:FindFirstChild("CodeVel") then root.CodeVel:Destroy() end
        if root:FindFirstChild("CodeGyro") then root.CodeGyro:Destroy() end
        root.AssemblyLinearVelocity = Vector3.zero
    end
    restoreNaturalCollision(char)
end

local function ToggleInvis()
    if IsTransitioning then return end
    IsInvisible = not IsInvisible
    invBtn.Text = IsInvisible and "INVISIBLE: ON" or "INVISIBLE: OFF"
    invBtn.TextColor3 = IsInvisible and COLORS.Accent or Color3.new(0.8, 0.8, 0.8)

    local targetTransparency = IsInvisible and 1 or 0
    for _, part in pairs(VisibleParts) do
        if part and part.Parent then pcall(function() part.Transparency = targetTransparency end) end
    end

    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if IsInvisible then
        if root then VirtualRootCFrame = root.CFrame end
    else
        IsTransitioning = true
        task.delay(0.15, function() IsTransitioning = false end)
    end
end

-- =========================================================================
-- [SECTION 9] UI EVENT HANDLERS
-- =========================================================================
SummonBtn.MouseButton1Click:Connect(function()
    petMode = not petMode
    if petMode then
        SetupCharacter()
        flying, noclip, snapNextFrame = true, true, true
        fBtn.Text, cBtn.Text, SummonBtn.TextColor3 = "Fly: ON", "Noclip: ON", COLORS.Accent
        UpdateAndValidateRodanProps()

        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            lastPosition = char.HumanoidRootPart.Position
        end
    else
        if IsInvisible then ToggleInvis() end
        flying, noclip = false, false
        fBtn.Text, cBtn.Text, SummonBtn.TextColor3 = "Fly: OFF", "Noclip: OFF", Color3.new(0.8,0.8,0.8)
        resetPhysics(LP.Character)
        table.clear(PROP_CACHE)
        table.clear(CURRENT_CFRAMES)
        table.clear(TARGET_CFRAMES)
        table.clear(LAST_SEND_TIME)
        table.clear(COLOR_SENDING)
        table.clear(NETWORK_STATE)
        currentRoll = 0
    end
end)

fBtn.MouseButton1Click:Connect(function() flying = not flying fBtn.Text = flying and "Fly: ON" or "Fly: OFF" if not flying then resetPhysics(LP.Character) end end)
cBtn.MouseButton1Click:Connect(function() noclip = not noclip cBtn.Text = noclip and "Noclip: ON" or "Noclip: OFF" restoreNaturalCollision(LP.Character) end)
plusBtn.MouseButton1Click:Connect(function() flySpeed = flySpeed + 1 sNum.Text = "SPD: "..tostring(flySpeed) end)
minusBtn.MouseButton1Click:Connect(function() flySpeed = math.max(1, flySpeed - 1) sNum.Text = "SPD: "..tostring(flySpeed) end)
upBtn.MouseButton1Down:Connect(function() vVect = 1 end) upBtn.MouseButton1Up:Connect(function() vVect = 0 end)
dnBtn.MouseButton1Down:Connect(function() vVect = -1 end) dnBtn.MouseButton1Up:Connect(function() vVect = 0 end)
invBtn.MouseButton1Click:Connect(ToggleInvis)

bReload.MouseButton1Click:Connect(function()
    isReloading = not isReloading
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local detectorPath = workspace.WorkspaceCom["001_CriminalWeapons"].GiveTools.Bomb.ClickDetector

    if isReloading then
        bReload.Text = "STOP & TP BACK"
        bReload.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        bReload.TextColor3 = Color3.new(1, 1, 1)
        if root then originalPos = root.CFrame root.CFrame = detectorPath.Parent.CFrame end
        task.spawn(function()
            while isReloading do
                pcall(function() fireclickdetector(detectorPath) end)
                task.wait(0.05)
            end
        end)
    else
        bReload.Text = "AUTO RELOAD + TP"
        bReload.BackgroundColor3 = Color3.fromRGB(15, 2, 2)
        bReload.TextColor3 = Color3.new(0.8,0.8,0.8)
        if root and originalPos then root.CFrame = originalPos originalPos = nil end
    end
end)

bEquip.MouseButton1Click:Connect(function() for _, v in pairs(LP.Backpack:GetChildren()) do if v.Name == "Bomb" then v.Parent = LP.Character end end end)

bBlast.MouseButton1Click:Connect(function()
    local char = LP.Character
    if not char then return end
    local bombs = {}
    for _, v in pairs(LP.Backpack:GetChildren()) do if v.Name == "Bomb" then table.insert(bombs, v) end end
    for _, v in pairs(char:GetChildren()) do if v.Name == "Bomb" then table.insert(bombs, v) end end
    if #bombs == 0 then return end
    for i, bomb in ipairs(bombs) do
        task.spawn(function() pcall(function() bomb.Parent = char task.wait() bomb:Activate() end) end)
        if i % 20 == 0 then RS.Heartbeat:Wait() end
    end
end)

bDetonate.MouseButton1Click:Connect(function()
    local args = { "Bomb" .. OwnerName }
    pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Blo1wBomb1sServe1r"):FireServer(unpack(args)) end)
end)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetSize = isMinimized and UDim2.new(0, 200, 0, 30) or UDim2.new(0, 200, 0, 455)
    MinBtn.Text = isMinimized and "▼" or "▲"
    TS:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize}):Play()
    contentContainer.Visible = not isMinimized
end)

task.spawn(function() while true do Counter.Text = "BOMBS COUNTER: " .. getBombCount() task.wait(0.4) end end)

-- =========================================================================
-- [SECTION 10] CONNECTIONS + INVISIBILITY HEARTBEAT
-- =========================================================================
local Connections = {}
Connections[1] = UIS.InputBegan:Connect(function(input, gameProcessed) if not gameProcessed and input.KeyCode == Enum.KeyCode.G then ToggleInvis() end end)
Connections[2] = RS.Heartbeat:Connect(function()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if IsInvisible and root and hum then
        local OriginalCFrame = root.CFrame
        local OriginalCameraOffset = hum.CameraOffset
        VirtualRootCFrame = OriginalCFrame
        local DownCFrame = OriginalCFrame * CFrame.new(0, -500000, 0)
        root.CFrame = DownCFrame
        hum.CameraOffset = DownCFrame:ToObjectSpace(CFrame.new(OriginalCFrame.Position)).Position
        RS.RenderStepped:Wait()
        root.CFrame = OriginalCFrame
        hum.CameraOffset = OriginalCameraOffset
    elseif root and not IsTransitioning then
        VirtualRootCFrame = root.CFrame
    end
end)

-- =========================================================================
-- [SECTION 11] MAIN ENGINE — PROP SYNC (Heartbeat)
-- =========================================================================
RS.Heartbeat:Connect(function(dt)
    if not petMode then return end
    local t = tick()

    if t % 0.5 < dt then UpdateAndValidateRodanProps() end

    local totalRegisteredProps = 0
    for id, _ in pairs(PROP_CACHE) do if id > totalRegisteredProps then totalRegisteredProps = id end end
    if totalRegisteredProps < 1 then return end

    local currentPos = VirtualRootCFrame.Position
    local calculatedVelocity = (currentPos - lastPosition) / math.max(dt, 0.001)
    lastPosition = currentPos

    -- ADAPTIVE NETWORK RATE ADJUSTMENT
    if estimatedPing > 0.15 then
        NETWORK_TICK_RATE = math.clamp(estimatedPing * 0.5, BASE_TICK_RATE, 0.08)
    else
        NETWORK_TICK_RATE = BASE_TICK_RATE
    end

    local lagComp = flying and math.clamp(flySpeed * 0.22, 0, 40) or 0
    local safePing = math.clamp(estimatedPing, 0.01, 0.2)
    local predictedPosition = currentPos + (calculatedVelocity * safePing)

    local baseTargetCF = CFrame.new(predictedPosition, predictedPosition + VirtualRootCFrame.LookVector)
    local finalPos = baseTargetCF * CFrame.new(0, flying and -4 or 7, (flying and -5 or 0) - lagComp)

    local rotCF = CFrame.Angles(math.rad(MANUAL_ROTATION.X), math.rad(MANUAL_ROTATION.Y), math.rad(MANUAL_ROTATION.Z))
    local rollManeuverCF = CFrame.Angles(math.rad(currentRoll), 0, 0)
    local isDiving = (vVect == -1) or (calculatedVelocity.Y < -8 and math.abs(calculatedVelocity.Z) > 2)

    local flapPhase = math.sin(t * 5.2)
    local currentFrameState = AnimationStates.Idle
    if not isDiving then
        if flapPhase > 0.35 then currentFrameState = AnimationStates.Sayap1
        elseif flapPhase < -0.35 then currentFrameState = AnimationStates.Sayap2 end
    end

    local localLerpAlpha = 1 - math.exp(-45 * dt)
    if snapNextFrame then localLerpAlpha = 1 end

    -- CLIENT-FIRST TRACK
    for id, prop in pairs(PROP_CACHE) do
        if prop and prop.Parent then
            local offset = currentFrameState[id] or currentFrameState[((id - 1) % #currentFrameState) + 1]
            local targetCF = finalPos * rotCF * rollManeuverCF * offset

            TARGET_CFRAMES[id] = targetCF

            if snapNextFrame or not CURRENT_CFRAMES[id] then
                CURRENT_CFRAMES[id] = targetCF
            else
                CURRENT_CFRAMES[id] = CURRENT_CFRAMES[id]:Lerp(targetCF, localLerpAlpha)
            end
        end
    end
    if snapNextFrame then snapNextFrame = false end

    -- ASYNCHRONOUS NON-BLOCKING ANTI-CHOKE NETWORK STEP
    local canUpdateColor = (t - lastColorUpdate > 0.04)

    for id, prop in pairs(PROP_CACHE) do
        if prop and CURRENT_CFRAMES[id] then
            if t - (LAST_SEND_TIME[id] or 0) >= NETWORK_TICK_RATE and not NETWORK_STATE[id] then
                local cfR = prop:FindFirstChild("SetCurrentCFrame")
                if cfR and cfR:IsA("RemoteFunction") then
                    LAST_SEND_TIME[id] = t
                    NETWORK_STATE[id] = true

                    task.spawn(function()
                        local startSend = os.clock()
                        local completed = false

                        task.spawn(function()
                            local success = pcall(function()
                                cfR:InvokeServer(CURRENT_CFRAMES[id])
                            end)
                            completed = true
                            NETWORK_STATE[id] = false

                            if success and id == 1 then
                                estimatedPing = (estimatedPing * 0.95) + ((os.clock() - startSend) * 0.05)
                            end
                        end)

                        task.delay(MAX_CHOKE_TIMEOUT, function()
                            if not completed then
                                NETWORK_STATE[id] = false
                            end
                        end)
                    end)
                end
            end

            if canUpdateColor and id == colorIndex and not COLOR_SENDING[id] then
                local crR = prop:FindFirstChild("ChangePropColor")
                if crR then
                    COLOR_SENDING[id] = true
                    task.spawn(function()
                        local finishedColor = false
                        task.spawn(function()
                            pcall(function()
                                crR:InvokeServer(getAbyssColor(t, id))
                            end)
                            finishedColor = true
                            COLOR_SENDING[id] = false
                        end)
                        task.delay(0.1, function() if not finishedColor then COLOR_SENDING[id] = false end end)
                    end)
                end
            end
        end
    end

    if canUpdateColor then
        colorIndex = (colorIndex % totalRegisteredProps) + 1
        lastColorUpdate = t
    end
end)

-- =========================================================================
-- [SECTION 12] FLY ENGINE — ROLL / BODYVELOCITY (RenderStepped)
-- =========================================================================
RS.RenderStepped:Connect(function(dt)
    local char = LP.Character
    if flying and char and char:FindFirstChild("HumanoidRootPart") then
        local root, hum, cam = char.HumanoidRootPart, char.Humanoid, workspace.CurrentCamera
        local bv = root:FindFirstChild("CodeVel") or Instance.new("BodyVelocity", root)
        local bg = root:FindFirstChild("CodeGyro") or Instance.new("BodyGyro", root)
        bv.Name, bg.Name = "CodeVel", "CodeGyro"
        bv.MaxForce, bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8), Vector3.new(1e8, 1e8, 1e8)
        bg.P, bg.D, hum.PlatformStand = 48000, 520, true

        local rel = cam.CFrame:VectorToObjectSpace(hum.MoveDirection)
        local rawVel = ((cam.CFrame.LookVector * -rel.Z) + (cam.CFrame.RightVector * rel.X) + (Vector3.new(0,1,0) * vVect))

        bv.Velocity = (rawVel.Magnitude > 0) and (rawVel.Unit * (flySpeed * 25)) or Vector3.zero
        bg.CFrame = cam.CFrame

        local targetRoll = 0
        local activeLerpSpeed = ROLL_SPEED

        if rawVel.Magnitude > 0 then
            if math.abs(rel.X) > 0.1 then
                targetRoll = math.clamp(-rel.X * MAX_ROLL, -MAX_ROLL, MAX_ROLL)
            else targetRoll = 0 end
        else
            local rawMouseDelta = UIS:GetMouseDelta()
            smoothedMouseX = smoothedMouseX + (rawMouseDelta.X - smoothedMouseX) * math.min(15 * dt, 1)
            if math.abs(smoothedMouseX) > 0.5 then
                targetRoll = math.clamp(-smoothedMouseX * 1.5, -MAX_ROLL, MAX_ROLL)
            else targetRoll = 0 end
        end

        if math.abs(targetRoll) < 0.5 then
            targetRoll = 0
            activeLerpSpeed = BASE_RETURN_SPEED + (math.abs(currentRoll) * 0.3)
        end

        currentRoll = currentRoll + (targetRoll - currentRoll) * (1 - math.exp(-activeLerpSpeed * dt))
    else
        currentRoll = currentRoll + (0 - currentRoll) * (1 - math.exp(-20 * dt))
    end

    if noclip and char then
        for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

-- =========================================================================
-- [SECTION 13] CHARACTER RESPAWN HANDLER
-- =========================================================================
LP.CharacterAdded:Connect(function()
    task.wait(1)
    IsInvisible, IsTransitioning, isReloading = false, false, false
    SetupCharacter()
end)

SetupCharacter()
_G.a = Connections