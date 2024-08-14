pico-8 cartridge // http://www.pico-8.com
version 42

__lua__
function _init()
    -- Initialize the ragdoll
    ragdoll = {
        bones = {
            {p1 = {x=64, y=32, vx=0, vy=0}, p2 = {x=64, y=48, vx=0, vy=0}}, -- torso
            {p1 = {x=64, y=48, vx=0, vy=0}, p2 = {x=60, y=64, vx=0, vy=0}}, -- left leg
            {p1 = {x=64, y=48, vx=0, vy=0}, p2 = {x=68, y=64, vx=0, vy=0}}, -- right leg
            {p1 = {x=64, y=32, vx=0, vy=0}, p2 = {x=60, y=24, vx=0, vy=0}}, -- left arm
            {p1 = {x=64, y=32, vx=0, vy=0}, p2 = {x=68, y=24, vx=0, vy=0}}, -- right arm
        },
        gravity = 0.2
    }
    for bone in all(ragdoll.bones) do
        local dx = bone.p2.x - bone.p1.x
        local dy = bone.p2.y - bone.p1.y
        bone.length = sqrt(dx*dx + dy*dy)
    end

    -- Initialize static walls
    walls = {
        {x1 = 10, y1 = 10, x2 = 118, y2 = 10},
        {x1 = 10, y1 = 10, x2 = 10, y2 = 118},
        {x1 = 118, y1 = 10, x2 = 118, y2 = 118},
        {x1 = 10, y1 = 118, x2 = 118, y2 = 118},
    }

    -- Initialize moving balls
    balls = {
        {x = 20, y = 20, vx = 1.5, vy = 1.0, r = 5},
        {x = 40, y = 40, vx = -1.0, vy = 1.5, r = 6},
    }

    -- Initialize blocks
    blocks = {
        {x = 80, y = 30, w = 16, h = 8},
        {x = 30, y = 80, w = 8, h = 16},
    }
end

function update_bone(bone)
    local p1 = bone.p1
    local p2 = bone.p2

    -- Apply gravity
    p1.vy = p1.vy + ragdoll.gravity
    p2.vy = p2.vy + ragdoll.gravity

    -- Verlet integration
    local temp_x = p1.x
    local temp_y = p1.y
    p1.x = p1.x + (p1.x - (p1.px or p1.x)) + p1.vx
    p1.y = p1.y + (p1.y - (p1.py or p1.y)) + p1.vy
    p1.px = temp_x
    p1.py = temp_y

    temp_x = p2.x
    temp_y = p2.y
    p2.x = p2.x + (p2.x - (p2.px or p2.x)) + p2.vx
    p2.y = p2.y + (p2.y - (p2.py or p2.y)) + p2.vy
    p2.px = temp_x
    p2.py = temp_y
end

function constrain_bone(bone)
    local p1 = bone.p1
    local p2 = bone.p2
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local dist = sqrt(dx*dx + dy*dy)
    local difference = (dist - bone.length) / dist
    local offset_x = dx * 0.5 * difference
    local offset_y = dy * 0.5 * difference
    p1.x = p1.x + offset_x
    p1.y = p1.y + offset_y
    p2.x = p2.x - offset_x
    p2.y = p2.y - offset_y
end

function update_balls()
    for ball in all(balls) do
        ball.x += ball.vx
        ball.y += ball.vy

        -- Check collision with walls
        if ball.x - ball.r < 10 or ball.x + ball.r > 118 then
            ball.vx *= -1
        end
        if ball.y - ball.r < 10 or ball.y + ball.r > 118 then
            ball.vy *= -1
        end
    end
end

function check_collision(p, b)
    return p.x > b.x and p.x < b.x + b.w and p.y > b.y and p.y < b.y + b.h
end

function constrain_bones_to_scene()
    for bone in all(ragdoll.bones) do
        local p1, p2 = bone.p1, bone.p2
        for p in all({p1, p2}) do
            for b in all(blocks) do
                if check_collision(p, b) then
                    p.vx, p.vy = 0, 0
                    if p.y > b.y then
                        p.y = b.y + b.h
                    else
                        p.y = b.y
                    end
                end
            end

            -- Constrain to screen bounds
            if p.x < 10 then p.x = 10 end
            if p.x > 118 then p.x = 118 end
            if p.y < 10 then p.y = 10 end
            if p.y > 118 then p.y = 118 end
        end
    end
end

function _update()
    -- Update each bone
    for bone in all(ragdoll.bones) do
        update_bone(bone)
    end

    -- Constrain each bone to its original length
    for bone in all(ragdoll.bones) do
        constrain_bone(bone)
    end

    -- Constrain bones to scene (blocks, walls)
    constrain_bones_to_scene()

    -- Update balls
    update_balls()
end

function _draw()
    cls()

    -- Draw walls
    for wall in all(walls) do
        line(wall.x1, wall.y1, wall.x2, wall.y2, 7)
    end

    -- Draw balls
    for ball in all(balls) do
        circfill(ball.x, ball.y, ball.r, 8)
    end

    -- Draw blocks
    for block in all(blocks) do
        rectfill(block.x, block.y, block.x + block.w, block.y + block.h, 9)
    end

    -- Draw ragdoll
    for bone in all(ragdoll.bones) do
        line(bone.p1.x, bone.p1.y, bone.p2.x, bone.p2.y, 7)
    end
end
