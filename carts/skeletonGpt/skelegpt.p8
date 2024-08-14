pico-8 cartridge // http://www.pico-8.com
version 42

__lua__

-- Skeleton structure
skeleton = {}

function create_bone(x, y)
    return {
        x = x,
        y = y,
        px = x, -- Previous position for Verlet integration
        py = y,
        vx = 0,
        vy = 0 -- Ensure vy is initialized
    }
end

function create_joint(bone1, bone2, length)
    return {
        b1 = bone1,
        b2 = bone2,
        length = length
    }
end

-- Create skeleton bones
function init_skeleton()
    local spine = {}
    for i = 1, 5 do
        add(spine, create_bone(64, 32 + i * 8))
    end

    local head = create_bone(64, 24)
    local left_arm = { create_bone(56, 40), create_bone(48, 48) }
    local right_arm = { create_bone(72, 40), create_bone(80, 48) }
    local left_leg = { create_bone(60, 64), create_bone(56, 72) }
    local right_leg = { create_bone(68, 64), create_bone(72, 72) }

    skeleton = {
        spine = spine,
        head = head,
        left_arm = left_arm,
        right_arm = right_arm,
        left_leg = left_leg,
        right_leg = right_leg,
        joints = {}
    }

    -- Create joints
    for i = 2, #spine do
        add(skeleton.joints, create_joint(spine[i - 1], spine[i], 8))
    end
    add(skeleton.joints, create_joint(spine[1], head, 8))
    add(skeleton.joints, create_joint(spine[2], left_arm[1], 8))
    add(skeleton.joints, create_joint(spine[2], right_arm[1], 8))
    add(skeleton.joints, create_joint(left_arm[1], left_arm[2], 8))
    add(skeleton.joints, create_joint(right_arm[1], right_arm[2], 8))
    add(skeleton.joints, create_joint(spine[#spine], left_leg[1], 8))
    add(skeleton.joints, create_joint(spine[#spine], right_leg[1], 8))
    add(skeleton.joints, create_joint(left_leg[1], left_leg[2], 8))
    add(skeleton.joints, create_joint(right_leg[1], right_leg[2], 8))
end

-- Physics simulation
function update_skeleton()
    -- Apply gravity
    for _, part in pairs(skeleton) do
        if type(part) == "table" then
            for _, b in ipairs(part) do
                b.vy += 0.2
            end
        else
            part.vy += 0.2
        end
    end

    -- Update bone positions using Verlet integration
    for _, part in pairs(skeleton) do
        if type(part) == "table" then
            for _, b in ipairs(part) do
                local nx = b.x + b.x - b.px + b.vx
                local ny = b.y + b.y - b.py + b.vy
                b.px = b.x
                b.py = b.y
                b.x = nx
                b.y = ny
            end
        else
            local b = part
            local nx = b.x + b.x - b.px + b.vx
            local ny = b.y + b.y - b.py + b.vy
            b.px = b.x
            b.py = b.y
            b.x = nx
            b.y = ny
        end
    end

    -- Apply constraints
    for _, joint in ipairs(skeleton.joints) do
        local dx = joint.b2.x - joint.b1.x
        local dy = joint.b2.y - joint.b1.y
        local dist = sqrt(dx * dx + dy * dy)
        local diff = (dist - joint.length) / dist * 0.5
        local offsetX = dx * diff
        local offsetY = dy * diff

        joint.b1.x += offsetX
        joint.b1.y += offsetY
        joint.b2.x -= offsetX
        joint.b2.y -= offsetY
    end
end

-- Draw the skeleton
function draw_skeleton()
    -- Draw bones as lines
    for _, joint in ipairs(skeleton.joints) do
        line(joint.b1.x, joint.b1.y, joint.b2.x, joint.b2.y, 7)
    end
end

-- Draw the scene (stairs, walls)
function draw_scene()
    -- Draw stairs
    for i = 0, 5 do
        rectfill(32 + i * 16, 96 - i * 16, 96 + i * 16, 112 - i * 16, 8)
    end
end

-- Initialization
function _init()
    init_skeleton()
end

-- Update loop
function _update()
    update_skeleton()
end

-- Draw loop
function _draw()
    cls()
    draw_scene()
    draw_skeleton()
end
