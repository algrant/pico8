pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- BigInt class to handle large numbers
BigInt = {}
BigInt.__index = BigInt

-- Constructor
function BigInt:new(value)
    local obj = setmetatable({}, self)
    obj.chunks = {}
    obj.chunk_size = 1000000000 -- Each chunk can store up to 10^9 - 1
    if value then
        obj:set(value)
    end
    return obj
end

-- Set the value of the BigInt
function BigInt:set(value)
    self.chunks = {}
    local remaining = value
    while remaining > 0 do
        add(self.chunks, remaining % self.chunk_size)
        remaining = flr(remaining / self.chunk_size)
    end
end

-- Add another BigInt to this BigInt
function BigInt:add(other)
    local carry = 0
    local max_len = max(#self.chunks, #other.chunks)
    for i = 1, max_len do
        local sum = (self.chunks[i] or 0) + (other.chunks[i] or 0) + carry
        carry = flr(sum / self.chunk_size)
        self.chunks[i] = sum % self.chunk_size
    end
    if carry > 0 then
        add(self.chunks, carry)
    end
end

-- Multiply this BigInt by a scalar
function BigInt:mul(scalar)
    local carry = 0
    for i = 1, #self.chunks do
        local product = self.chunks[i] * scalar + carry
        carry = flr(product / self.chunk_size)
        self.chunks[i] = product % self.chunk_size
    end
    while carry > 0 do
        add(self.chunks, carry % self.chunk_size)
        carry = flr(carry / self.chunk_size)
    end
end

-- Convert BigInt to a string for display
function BigInt:to_string()
    if #self.chunks == 0 then
        return "0"
    end
    local str = ""
    for i = #self.chunks, 1, -1 do
        local chunk_str = ""
        local chunk = self.chunks[i]
        while chunk > 0 do
            chunk_str = sub("000000000" .. chunk % 1000000000, -9) .. chunk_str
            chunk = flr(chunk / 1000000000)
        end
        str = chunk_str .. str
    end
    return str
end

-- Convert string to a number
function str_to_num(str)
    local num = 0
    local factor = 1
    for i = #str, 1, -1 do
        num = num + (ord(sub(str, i, i)) - ord('0')) * factor
        factor = factor * 10
    end
    return num
end

-- Compare if this BigInt is greater than another BigInt
function BigInt:gt(other)
    if #self.chunks > #other.chunks then
        return true
    elseif #self.chunks < #other.chunks then
        return false
    end
    for i = #self.chunks, 1, -1 do
        if (self.chunks[i] or 0) > (other.chunks[i] or 0) then
            return true
        elseif (self.chunks[i] or 0) < (other.chunks[i] or 0) then
            return false
        end
    end
    return false
end

-- Compare if this BigInt is greater than or equal to another BigInt
function BigInt:gte(other)
    return self:gt(other) or self:eq(other)
end

-- Compare if this BigInt is less than another BigInt
function BigInt:lt(other)
    return not self:gte(other)
end

-- Compare if this BigInt is less than or equal to another BigInt
function BigInt:lte(other)
    return not self:gt(other)
end

-- Compare if this BigInt is equal to another BigInt
function BigInt:eq(other)
    if #self.chunks ~= #other.chunks then
        return false
    end
    for i = 1, #self.chunks do
        if (self.chunks[i] or 0) ~= (other.chunks[i] or 0) then
            return false
        end
    end
    return true
end

-- Idle Game in Pico-8 with BigInt for large numbers
coins = BigInt:new(0)
pps = BigInt:new(1) -- coins per second
upgrade_cost = BigInt:new(10)
accumulated_time = 0

-- Secondary economy
gems = BigInt:new(0)
gems_unlocked = false
gem_upgrade_cost = BigInt:new(5)
gem_upgrade_effect = BigInt:new(5)
coin_to_gem_rate = BigInt:new(100) -- 100 coins for 1 gem

-- Selector
selection = 1
num_options = 3

-- Initialize the game
function _init()
    -- Set up the initial game state
    coins = BigInt:new(0)
    pps = BigInt:new(1)
    upgrade_cost = BigInt:new(10)
    accumulated_time = 0

    -- Initialize secondary economy
    gems = BigInt:new(0)
    gems_unlocked = false
    gem_upgrade_cost = BigInt:new(5)
    gem_upgrade_effect = BigInt:new(5)

    -- Initialize selector
    selection = 1
end

-- Update the game state (60 times per second)
function _update60()
    -- Accumulate coins over time
    accumulated_time = accumulated_time + 1
    if accumulated_time >= 60 then
        coins:add(pps)
        accumulated_time = 0
    end

    -- Unlock gems once coins reach 1000
    if not gems_unlocked and coins:gte(BigInt:new(1000)) then
        gems_unlocked = true
    end

    -- Navigate the menu
    if btnp(2) then -- up
        selection = selection - 1
        if selection < 1 then
            selection = num_options
        end
    elseif btnp(3) then -- down
        selection = selection + 1
        if selection > num_options then
            selection = 1
        end
    end

    -- Purchase upgrades based on selection
    if btnp(4) then -- Z button
        if selection == 1 and coins:gte(upgrade_cost) then
            -- Purchase coin upgrade
            coins:add(upgrade_cost:mul(-1))
            pps:mul(2)
            upgrade_cost:mul(2)
        elseif selection == 2 and gems_unlocked and gems:gte(gem_upgrade_cost) then
            -- Purchase gem upgrade
            gems:add(gem_upgrade_cost:mul(-1))
            pps:add(gem_upgrade_effect)
            gem_upgrade_cost:mul(2)
        elseif selection == 3 and gems_unlocked and coins:gte(coin_to_gem_rate) then
            -- Convert coins to gems
            coins:add(coin_to_gem_rate:mul(-1))
            gems:add(1)
        end
    end
end

-- Draw the game
function _draw()
    cls()
    print("idle game", 40, 10, 7)

    -- Draw coins
    spr(1, 20, 30)
    print("coins: " .. coins:to_string(), 30, 30, 7)
    print("coins per second: " .. pps:to_string(), 30, 40, 7)
    print("upgrade cost: " .. upgrade_cost:to_string(), 30, 50, 7)
    if selection == 1 then
        print(">", 20, 60, 7)
    end
    print("press z to upgrade", 30, 60, 7)

    if gems_unlocked then
        -- Draw gems
        spr(2, 20, 80)
        print("gems: " .. gems:to_string(), 30, 80, 7)
        print("gem upgrade cost: " .. gem_upgrade_cost:to_string(), 30, 90, 7)
        if selection == 2 then
            print(">", 20, 100, 7)
        end
        print("press z to buy gem upgrade", 30, 100, 7)
        if selection == 3 then
            print(">", 20, 120, 7)
        end
        print("convert 100 coins to 1 gem", 30, 120, 7)
        print("press z to convert", 30, 130, 7)
    end
end


-- __gfx__
-- 00000000000aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 0000000000a959a00022220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 000000000a95559a0882288000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 000000000a95999a0888778000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 000000000a95559a0888788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 0000000000a959a00088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 00000000000aaa000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gfx__
00000000000aaa00000000000000000000000aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a959a00022220000000000000a9999a0006666000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a95559a088228800000000000a9aaaa9a066666660000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a95999a088877800000000000a9aaaa9a066676660000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a95559a088878800000000000a9aaaa9a066666660000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a959a00088880000000000000aaa0aaa006660000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaa000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
