pico-8 cartridge // http://www.pico-8.com
version 42

__lua__

Bone = {}
Bone.__index = Bone

function Bone.create(x, y)
    local b = setmetatable(
        {
            x = x,
            y = y,
            px = x,
            py = y,
            vx = 0,
            vy = 0
        }, Bone
    )
    return b
end

Skeleton = {}
Skeleton.__index = Skeleton

function Skeleton.create()
    local s = setmetatable(
        {
            bones = {},
            joints = {}
        }, Skeleton
    )
    return s
end

function Skeleton:add_bone(bone)
    add(self.bones, bone)
end

function Skeleton:add_joint(b1, b2, length)
    local joint = {
        b1 = b1,
        b2 = b2,
        length = length
    }
    add(self.joints, joint)
end

StaticObject = {}
StaticObject.__index = StaticObject

function StaticObject.create(x1, y1, x2, y2)
    local obj = setmetatable(
        {
            x1 = x1,
            y1 = y1,
            x2 = x2,
            y2 = y2
        }, StaticObject
    )
    return obj
end

function StaticObject:check_collision(bone)
    -- Simple AABB (Axis-Aligned Bounding Box) collision detection
    local bx1 = min(bone.x, bone.px)
    local by1 = min(bone.y, bone.py)
    local bx2 = max(bone.x, bone.px)
    local by2 = max(bone.y, bone.py)

    return not bx2 < self.x1 or bx1 > self.x2 or by2 < self.y1 or by1 > self.y2
end

function init_scene()
    stairs = {}
    for i = 0, 5 do
        add(
            stairs, StaticObject.create(
                32 + i * 16, 96 - i * 16,
                96 + i * 16, 112 - i * 16
            )
        )
    end
end

-- Create skeleton bones
function init_skeleton()
    local s = Skeleton.create()
    local spine = {}
    for i = 1, 5 do
        add(spine, Bone.create(64, 32 + i * 8))
    end

    local head = Bone.create(64, 24)
    local left_arm = { Bone.create(56, 40), Bone.create(48, 48) }
    local right_arm = { Bone.create(72, 40), Bone.create(80, 48) }
    local left_leg = { Bone.create(60, 64), Bone.create(56, 72) }
    local right_leg = { Bone.create(68, 64), Bone.create(72, 72) }

    for _, bone in ipairs(spine) do
        s:add_bone(bone)
    end
    s:add_bone(head)
    for _, bone in ipairs(left_arm) do
        s:add_bone(bone)
    end
    for _, bone in ipairs(right_arm) do
        s:add_bone(bone)
    end
    for _, bone in ipairs(left_leg) do
        s:add_bone(bone)
    end
    for _, bone in ipairs(right_leg) do
        s:add_bone(bone)
    end

    -- Create joints
    for i = 2, #spine do
        s:add_joint(spine[i - 1], spine[i], 8)
    end
    s:add_joint(spine[1], head, 8)
    s:add_joint(spine[2], left_arm[1], 8)
    s:add_joint(spine[2], right_arm[1], 8)
    s:add_joint(left_arm[1], left_arm[2], 8)
    s:add_joint(right_arm[1], right_arm[2], 8)
    s:add_joint(spine[#spine], left_leg[1], 8)
    s:add_joint(spine[#spine], right_leg[1], 8)
    s:add_joint(left_leg[1], left_leg[2], 8)
    s:add_joint(right_leg[1], right_leg[2], 8)

    skeleton = s
end

function update_skeleton()
    -- Apply gravity
    for _, bone in ipairs(skeleton.bones) do
        bone.vy += 0.2
    end

    -- Update bone positions using Verlet integration
    for _, bone in ipairs(skeleton.bones) do
        local nx = bone.x + bone.x - bone.px + bone.vx
        local ny = bone.y + bone.y - bone.py + bone.vy
        bone.px = bone.x
        bone.py = bone.y
        bone.x = nx
        bone.y = ny
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

    -- Check collisions with stairs
    for _, bone in ipairs(skeleton.bones) do
        for _, stair in ipairs(stairs) do
            if stair:check_collision(bone) then
                -- Handle collision response
                bone.y = bone.py -- Reset to previous position
                bone.vy = 0 -- Stop falling
            end
        end
    end
end

function draw_skeleton()
    -- Draw bones as lines
    for _, joint in ipairs(skeleton.joints) do
        line(joint.b1.x, joint.b1.y, joint.b2.x, joint.b2.y, 7)
    end
end

function draw_scene()
  -- Draw stairs
  for _, stair in ipairs(stairs) do
    rectfill(stair.x1, stair.y1, stair.x2, stair.y2, 8)
  end
end

-- Initialization
function _init()
    init_skeleton()
    init_scene()
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
