pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- constants
local screen_width = 128
local screen_height = 128

-- game variables
local player = {
    x = 20,
    y = 110,
    width = 8,
    height = 8,
    jumping = false,
    jumpspeed = -4,
    gravity = 0.2,
    sprite = 1
}

local charlie = {
    x = 0,
    y = 110,
    width = 8,
    height = 8,
    speed = 1,
    sprite = 2
}

local hoops = {}

-- define a function to create a hoop object with x, y, width, height
function createhoop(x, y)
    return {
        x = x,
        y = y,
        width = 8,
        height = 8
    }
end

local hoopspeed = 1
local hoopinterval = 60
local hooptimer = hoopinterval

local score = 0
local lives = 3
local gamestate = "title"  -- "title", "playing", "gameover"

-- sprites
local sprites = {
    { -- player (lion)
        id = 1,
        data = {
            0x00,0x00,0x70,0x00,0x08,0x30,0x38,0x4c,
            0xc4,0x3c,0x78,0x30,0x78,0x30,0x70,0x1c,
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
        }
    },
    { -- charlie
        id = 2,
        data = {
            0x00,0x00,0x20,0x00,0x50,0x28,0x78,0x44,
            0xc4,0x38,0x78,0x30,0x78,0x38,0x70,0x10,
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
        }
    },
    { -- flaming hoop
        id = 3,
        data = {
            0x00,0x00,0x38,0x00,0x7c,0x00,0xfe,0x00,
            0xff,0x00,0xff,0x00,0xfe,0x00,0x7c,0x00,
            0x38,0x00,0x00,0x00,0x00,0x00,0x00,0x00
        }
    }
}

-- game initialization
function _init()
    initgame()
end

function initgame()
    player.x = 20
    player.y = 110
    charlie.x = 0
    charlie.y = 110
    score = 0
    lives = 3
    gamestate = "title"
    hoops = {}
    add(hoops, createhoop(128, 100))  -- initial hoop
end

-- collision detection function
function checkcollision(obj1, obj2)
    return obj1.x < obj2.x + obj2.width and
           obj1.x + obj1.width > obj2.x and
           obj1.y < obj2.y + obj2.height and
           obj1.y + obj1.height > obj2.y
end

-- update function
function _update()
    if gamestate == "title" then
        updatetitlescreen()
    elseif gamestate == "playing" then
        updateplayingstate()
    elseif gamestate == "gameover" then
        updategameoverscreen()
    end
end

function updatetitlescreen()
    if btnp(4) then  -- z key
        gamestate = "playing"
    end
end

function updateplayingstate()
    -- player controls
    if btn(0) then  -- left arrow key
        player.x = player.x - 1
    elseif btn(1) then  -- right arrow key
        player.x = player.x + 1
    end

    -- player jumping
    if btnp(4) and not player.jumping then  -- z key
        player.jumping = true
        sfx(0)
    end

    -- update player jumping
    if player.jumping then
        player.y = player.y + player.jumpspeed
        player.jumpspeed = player.jumpspeed + player.gravity

        -- check if player has landed
        if player.y >= 110 then
            player.y = 110
            player.jumping = false
            player.jumpspeed = -4
        end
    end

    -- update charlie's movement
    charlie.x = charlie.x + charlie.speed

    -- update flaming hoops
    hooptimer = hooptimer - 1
    if hooptimer <= 0 then
        add(hoops, createhoop(screen_width, 100))  -- spawn new hoop
        hooptimer = hoopinterval
    end

    for i = #hoops, 1, -1 do
        local hoop = hoops[i]
        hoop.x = hoop.x - hoopspeed

        -- check collision with player
        if checkcollision(player, hoop) then
            sfx(1)
            del(hoops, i)
            lives = lives - 1
        end

        -- remove hoop if off-screen
        if hoop.x < -8 then
            del(hoops, i)
        end
    end

    -- check if charlie reaches the goal
    if charlie.x >= screen_width then
        score = score + 100
        charlie.x = 0
        -- add level progression or difficulty increase here
    end

    -- check game over
    if lives <= 0 then
        gamestate = "gameover"
    end
end

function updategameoverscreen()
    if btnp(4) then  -- z key
        initgame()
    end
end

-- draw function
function _draw()
    cls()

    if gamestate == "title" then
        print("press z to start", 40, 50, 7)
    elseif gamestate == "playing" then
        -- draw player (lion)
        spr(sprites[player.sprite].id, player.x, player.y)

        -- draw charlie
        spr(sprites[charlie.sprite].id, charlie.x, charlie.y)

        sprhoop = 3
        -- draw flaming hoops
        for _, hoop in ipairs(hoops) do
            spr(sprites[sprhoop].id, hoop.x, hoop.y)
        end

        -- display score and lives
        print("score: " .. score, 0, 0, 7)
        print("lives: " .. lives, 60, 0, 7)
    elseif gamestate == "gameover" then
        print("game over", 50, 50, 8)
        print("press z to restart", 40, 70, 7)
    end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000800000090000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000800000090000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000800000090000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000800000090000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000090000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
