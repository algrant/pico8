pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Bird Animation in Pico-8 with Eyes, Beak, Feet, and Collision Avoidance

-- Bird structure
function create_bird()
    local angle = rnd(1)
    return {
        x = -20,  -- Start off-screen
        y = rnd(120),  -- Random y position
        size = rnd(2) + 4,  -- Random size (4-6)
        speed = rnd(2) + 1,  -- Random speed
        wing_state = 0,  -- Wing animation state
        color = flr(rnd(15)) + 1,  -- Random color
        angle = angle,  -- Initial flight angle
        path_amplitude = rnd(20) + 10,  -- Amplitude of the flight path
        path_frequency = rnd(0.05) + 0.05,  -- Frequency of the flight path
    }
end

-- Initialize birds
birds = {}
for i=1,10 do
    add(birds, create_bird())
end

-- Update bird animation
function update_birds()
    for bird in all(birds) do
        -- Calculate new position based on the sine wave
        bird.angle += bird.path_frequency
        bird.y += cos(bird.angle) * bird.path_amplitude * 0.1
        bird.x += bird.speed

        -- Collision avoidance
        for other_bird in all(birds) do
            if other_bird != bird then
                local dist = sqrt((bird.x - other_bird.x)^2 + (bird.y - other_bird.y)^2)
                if dist < bird.size * 2 then
                    -- Adjust position to avoid collision
                    bird.y += (bird.y - other_bird.y) * 0.1
                    bird.x += (bird.x - other_bird.x) * 0.1
                end
            end
        end

        bird.wing_state = (bird.wing_state + bird.speed * 0.1) % 1

        -- Reset bird position when it goes off-screen
        if bird.x > 130 then
            bird.x = -20
            bird.y = rnd(120)
            bird.size = rnd(2) + 4
            bird.speed = rnd(2) + 1
            bird.color = flr(rnd(15)) + 1
            bird.angle = rnd(1)
            bird.path_amplitude = rnd(20) + 10
            bird.path_frequency = rnd(0.05) + 0.05
        end
    end
end

-- Draw bird animation
function draw_bird(bird)
    -- Body
    circfill(bird.x, bird.y, bird.size, bird.color)

    -- Eyes
    circfill(bird.x + bird.size/2, bird.y - bird.size/3, bird.size/5, 7)  -- Right eye
    circfill(bird.x + bird.size/4, bird.y - bird.size/3, bird.size/5, 0)  -- Left eye

    -- Beak (using lines to form a triangle)
    local beak_x = bird.x + bird.size + 1
    local beak_y = bird.y
    line(beak_x, beak_y, beak_x + bird.size/3, beak_y - bird.size/6, 10)
    line(beak_x, beak_y, beak_x + bird.size/3, beak_y + bird.size/6, 10)
    line(beak_x + bird.size/3, beak_y - bird.size/6, beak_x + bird.size/3, beak_y + bird.size/6, 10)

    -- Feet
    local feet_y = bird.y + bird.size + 1
    line(bird.x - bird.size/3, feet_y, bird.x - bird.size/3, feet_y + bird.size/2, bird.color)
    line(bird.x + bird.size/3, feet_y, bird.x + bird.size/3, feet_y + bird.size/2, bird.color)

    -- Wings (flapping effect)
    local wing_offset = sin(bird.wing_state * 2) * bird.size
    line(bird.x - wing_offset, bird.y - bird.size, bird.x + wing_offset, bird.y - bird.size, bird.color)
    line(bird.x - wing_offset, bird.y + bird.size, bird.x + wing_offset, bird.y + bird.size, bird.color)
end

-- Main loop
function _update()
    update_birds()
end

function _draw()
    cls(0)
    for bird in all(birds) do
        draw_bird(bird)
    end
end
