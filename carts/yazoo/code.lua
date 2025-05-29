
-- yahtzee esque game
-- 5 dice
-- 3 rolls
-- score based on dice values
-- 13 categories
-- 6 upper section categories
-- 7 lower section categories
-- upper section: 1s, 2s, 3s, 4s, 5s, 6s
-- lower section: 3 of a kind, 4 of a kind, full house, small straight, large straight, yahtzee, chance
-- yahtzee: all dice are the same value
-- full house: 3 of one value and 2 of another
-- small straight: 4 sequential values (1,2,3,4 or 2,3,4,5 or 3,4,5,6)
-- large straight: 5 sequential values (1,2,3,4,5 or 2,3,4,5,6)
-- chance: sum of all dice values

-- game flow
-- player rolls 5 dice
-- player can choose to hold some dice and re-roll the rest up to 2 times
-- after 3 rolls, player must choose a category to score in
-- scoring is based on the final dice values
-- player can choose which category to score in after each roll
-- once a category is scored, it cannot be scored again
-- player with highest total score wins

-- define categories
local categories = {
    upper = {
        {name = "ones", description = "Sum of all 1s", value = 1},
        {name = "twos", description = "Sum of all 2s", value = 2},
        {name = "threes", description = "Sum of all 3s", value = 3},
        {name = "fours", description = "Sum of all 4s", value = 4},
        {name = "fives", description = "Sum of all 5s", value = 5},
        {name = "sixes", description = "Sum of all 6s", value = 6}
    },
    lower = {
        {name = "three of a kind", description = "Sum of all dice"},
        {name = "four of a kind", description = "Sum of all dice"},
        {name = "full house", description = "25 points"},
        {name = "small straight", description = "30 points"},
        {name = "large straight", description = "40 points"},
        {name = "yahtzee", description = "50 points"},
        {name = "chance", description = "Sum of all dice"}
    }
}

local dice_types = {
    regular = {1, 2, 3, 4, 5, 6},
}

-- define player scores
local player1 = { upper = {}, lower = {}, total = 0 }
local player2 = { upper = {}, lower = {}, total = 0 }

-- state --> current player, current roll, dice values, scores
local current_player = player1
local roll_count = 0
local dice = {}
local held_dice = {}
local state = "start"  -- can be "start", "rolling", "hold"
local selector = { dice = nil, category = nil, action = nil } -- for selecting a category to score in or dice to hold, action can be "roll", "score"

-- "rolling" --> player has rolled the dice, animation is playing
-- "hold" --> player has rolled the dice, can choose to hold some dice and re-roll the rest (or select to score now)
-- "scoring" --> player has chosen to score (or run out of rolls), must choose a category to score in
-- "game_over" --> both players have completed all turns, game is over

function _init()
    -- initialize player scores
    player1.upper = {}
    player1.lower = {}
    player1.total = 0
    player2.upper = {}
    player2.lower = {}
    player2.total = 0

    -- set current player to player 1
    current_player = player1
    state = "start"
    dice = {}
    held_dice = {}
    roll_count = 0
end

function roll_dice()
    for i = 1, 5 do
        if not held_dice[i] then
            dice[i] = rnd(6) + 1
        end
    end
    -- set state to rolling
    state = "rolling"
end

function _update()
    if state == "start" then
        roll_dice()
        time = 0
    elseif state == "rolling" then
        -- animate rolling dice
        time += 1
        if time > 30 then
            state = "hold"
            -- default to selecting first dice
            selector = { dice = 1, category = nil, action = nil }
        end
    elseif state == "hold" then
        -- player can choose to hold some dice and re-roll or score
        -- options for btnp are "⬆️" to move up, "⬇️" to move down, "➡️" to move right, "⬅️" to move left
        -- "a" to select an action (either "hold/unhold", "roll" or "score")



    elseif state == "scoring" then
        -- player can choose to score in a category or continue rolling
        -- if a category is scored, update player scores and switch to other player
        -- if player chooses to continue rolling, reset roll count and dice
        -- if player has completed all turns, game over
    end
end



-- define function to check if a category has been scored
local function category_scored(player, category)
    for _, cat in ipairs(player.upper) do
        if cat == category then
            return true
        end
    end
    for _, cat in ipairs(player.lower) do
        if cat == category then
            return true
        end
    end
    return false
end

-- define dice values
function draw_dice()
    for i, die in ipairs(dice) do
        local x = 8 + i * 8
        local y = 100
        printh(i)
        spr(die-1, x, y)
    end
end

-- pico8 draw function
function _draw()
    cls()

    -- draw player name (Player 1 or Player 2)
    print("player " .. (current_player == player1 and "1" or "2"), 8, 0, 15)

    -- draw upper section
    for i, category in ipairs(categories.upper) do
        local y = 6 + i * 8
        local x = 8
        local score = current_player.upper[i] or "-"
        print(category.name, x, y, 7)
        print(score, 50, y, 15)
    end

    -- draw lower section
    for i, category in ipairs(categories.lower) do
        local y = 6 + i * 8
        local x = 60
        local score = current_player.lower[i] or "-"
        print(category.name, x, y, 7)
        print(score, 122, y, 15)
    end
    -- draw total score
    print("total: " .. current_player.total, 8, 120, 15)
    draw_dice()
end

