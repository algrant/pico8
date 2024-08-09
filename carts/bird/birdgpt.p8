pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- Bird Animation in Pico-8

-- Bird structure
function create_bird()
    return {
        x = -10,  -- Start off-screen
        y = rnd(120),  -- Random y position
        size = rnd(2) + 1,  -- Random size (1-3)
        speed = rnd(2) + 1,  -- Random speed
        wing_state = 0,  -- Wing animation state
        color = flr(rnd(15)) + 1,  -- Random color
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
        bird.x += bird.speed
        bird.wing_state = (bird.wing_state + bird.speed * 0.1) % 1

        -- Reset bird position when it goes off-screen
        if bird.x > 130 then
            bird.x = -10
            bird.y = rnd(120)
            bird.size = rnd(2) + 1
            bird.speed = rnd(2) + 1
            bird.color = flr(rnd(15)) + 1
        end
    end
end

-- Draw bird animation
function draw_bird(bird)
    -- Body
    circfill(bird.x, bird.y, bird.size, bird.color)

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