pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Bird Animation in Pico-8 with Eyes, Beak, Feet, and Multiple Wing Shapes

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
        wing_type = flr(rnd(4)) + 1,  -- Randomly choose a wing type (1 to 4)
    }
end

-- Initialize birds
birds = {}
for i=1,10 do
    add(birds, create_bird())
end

-- Update bird animation (modify this section)
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

        -- Slow down the wing state update to slow the flapping
        bird.wing_state = (bird.wing_state + bird.speed * 0.005) % 1

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
            bird.wing_type = flr(rnd(4)) + 1
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

    -- Replace the existing wing drawing code with this:
    -- Wings (4 variations using arcs with up and down motion)

    if bird.wing_type == 1 then
        -- Wing shape 1: Larger arcs with pronounced up-down flapping
        local wing_offset_x = sin(bird.wing_state * 2) * bird.size
        local wing_offset_y = cos(bird.wing_state * 2) * bird.size * 0.5
        for i=0,3 do
            circ(bird.x - wing_offset_x, bird.y - bird.size + i * 2 + wing_offset_y, 3 + i, bird.color)
            circ(bird.x + wing_offset_x, bird.y - bird.size + i * 2 + wing_offset_y, 3 + i, bird.color)
            circ(bird.x - wing_offset_x, bird.y + bird.size - i * 2 - wing_offset_y, 3 + i, bird.color)
            circ(bird.x + wing_offset_x, bird.y + bird.size - i * 2 - wing_offset_y, 3 + i, bird.color)
        end

    elseif bird.wing_type == 2 then
        -- Wing shape 2: Smaller arcs with quick up-down flapping
        local wing_offset_x = sin(bird.wing_state * 4) * bird.size
        local wing_offset_y = cos(bird.wing_state * 4) * bird.size * 0.5
        for i=0,2 do
            circ(bird.x - wing_offset_x, bird.y - bird.size + i * 3 + wing_offset_y, 2 + i, bird.color)
            circ(bird.x + wing_offset_x, bird.y - bird.size + i * 3 + wing_offset_y, 2 + i, bird.color)
            circ(bird.x - wing_offset_x, bird.y + bird.size - i * 3 - wing_offset_y, 2 + i, bird.color)
            circ(bird.x + wing_offset_x, bird.y + bird.size - i * 3 - wing_offset_y, 2 + i, bird.color)
        end

    elseif bird.wing_type == 3 then
        -- Wing shape 3: Arcs with varying sizes and slight up-down motion
        local wing_offset_x = sin(bird.wing_state * 2) * bird.size
        local wing_offset_y = cos(bird.wing_state * 2) * bird.size * 0.3
        circ(bird.x - wing_offset_x, bird.y - bird.size + wing_offset_y, 4, bird.color)
        circ(bird.x + wing_offset_x, bird.y - bird.size + wing_offset_y, 3, bird.color)
        circ(bird.x - wing_offset_x, bird.y + bird.size - wing_offset_y, 4, bird.color)
        circ(bird.x + wing_offset_x, bird.y + bird.size - wing_offset_y, 3, bird.color)

    elseif bird.wing_type == 4 then
        -- Wing shape 4: Overlapping arcs with more pronounced up-down motion
        local wing_offset_x = sin(bird.wing_state * 2) * bird.size
        local wing_offset_y = cos(bird.wing_state * 2) * bird.size * 0.5
        for i=0,1 do
            circ(bird.x - wing_offset_x + i, bird.y - bird.size + i * 2 + wing_offset_y, 3 + i, bird.color)
            circ(bird.x + wing_offset_x - i, bird.y - bird.size + i * 2 + wing_offset_y, 3 + i, bird.color)
            circ(bird.x - wing_offset_x + i, bird.y + bird.size - i * 2 - wing_offset_y, 3 + i, bird.color)
            circ(bird.x + wing_offset_x - i, bird.y + bird.size - i * 2 - wing_offset_y, 3 + i, bird.color)
        end
    end

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
