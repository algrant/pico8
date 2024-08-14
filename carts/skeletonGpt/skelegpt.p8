pico-8 cartridge // http://www.pico-8.com
version 42

__lua__
-- Skeleton Animation in Pico-8
-- Initial setup
skeleton = {}

-- Constants
NUM_BONES = 2
BONE_LENGTH = 5
TORSO_LENGTH = 15
ARM_LENGTH = BONE_LENGTH * NUM_BONES
LEG_LENGTH = BONE_LENGTH * NUM_BONES

-- Create a bone
function create_bone(x, y, length, angle)
    return {x = x, y = y, length = length, angle = angle}
end

-- Create skeleton structure
function create_skeleton(x, y)
    local s = {}

    -- Torso
    s.torso = {
        create_bone(x, y, TORSO_LENGTH, 0)
    }

    -- Head
    s.head = {
        x = x, y = y - TORSO_LENGTH
    }

    -- Arms
    s.left_arm = {
        create_bone(x, y, BONE_LENGTH, -0.5),
        create_bone(x - BONE_LENGTH, y - BONE_LENGTH, BONE_LENGTH, -1)
    }
    s.right_arm = {
        create_bone(x, y, BONE_LENGTH, 0.5),
        create_bone(x + BONE_LENGTH, y - BONE_LENGTH, BONE_LENGTH, 1)
    }

    -- Legs
    s.left_leg = {
        create_bone(x, y + TORSO_LENGTH, BONE_LENGTH, 0.5),
        create_bone(x - BONE_LENGTH, y + TORSO_LENGTH + BONE_LENGTH, BONE_LENGTH, 1)
    }
    s.right_leg = {
        create_bone(x, y + TORSO_LENGTH, BONE_LENGTH, -0.5),
        create_bone(x + BONE_LENGTH, y + TORSO_LENGTH + BONE_LENGTH, BONE_LENGTH, -1)
    }

    return s
end

-- Draw a bone
function draw_bone(bone)
    local x2 = bone.x + cos(bone.angle) * bone.length
    local y2 = bone.y + sin(bone.angle) * bone.length
    line(bone.x, bone.y, x2, y2, 7)
end

-- Draw the skeleton
function draw_skeleton(s)
    -- Draw torso
    for bone in all(s.torso) do
        draw_bone(bone)
    end

    -- Draw head
    circfill(s.head.x, s.head.y, 3, 7)

    -- Draw arms
    for bone in all(s.left_arm) do
        draw_bone(bone)
    end
    for bone in all(s.right_arm) do
        draw_bone(bone)
    end

    -- Draw legs
    for bone in all(s.left_leg) do
        draw_bone(bone)
    end
    for bone in all(s.right_leg) do
        draw_bone(bone)
    end
end

-- Animate skeleton (simple example)
function animate_skeleton(s, t)
    -- Wiggle arms
    s.left_arm[1].angle = -0.5 + sin(t) * 0.2
    s.right_arm[1].angle = 0.5 + sin(t) * 0.2

    -- Wiggle legs
    s.left_leg[1].angle = 0.5 + sin(t + 1) * 0.2
    s.right_leg[1].angle = -0.5 + sin(t + 1) * 0.2
end

-- Init
function _init()
    skeleton = create_skeleton(64, 64)
end

-- Update
function _update()
    animate_skeleton(skeleton, t())
end

-- Draw
function _draw()
    cls()
    draw_skeleton(skeleton)
end
