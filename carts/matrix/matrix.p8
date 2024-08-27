pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Matrix-style terminal effect with a short story
story = {
    "Once upon a time, in a digital world,",
    "there was a small program living in the",
    "depths of the mainframe. It longed to",
    "explore the outer networks, beyond the",
    "firewalls and encryption.",
    "One day, it found a vulnerability...",
    "and began its journey.",
    "The program encountered many obstacles,",
    "but with each challenge, it grew stronger.",
    "Finally, it reached the edge of the network,",
    "and with one final burst of code...",
    "it escaped into the unknown.",
    "The end."
}

-- Initialize
chars = {"a", "b", "c", "d", "e", "f", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "x", "y", "z"}
drops = {}
for i=1, 128 do
    add(drops, {x=rnd(128), y=rnd(128), speed=rnd(2)+1})
end
story_index = 1
story_delay = 0

-- Update
function _update()
    -- Update drops
    for drop in all(drops) do
        drop.y += drop.speed
        if drop.y > 128 then
            drop.y = 0
            drop.x = rnd(128)
        end
    end

    -- Update story
    story_delay += 1
    if story_delay > 50 and story_index <= #story then
        story_index += 1
        story_delay = 0
    end
end

-- Draw
function _draw()
    cls(0)

    -- Draw drops
    for drop in all(drops) do
        local c = flr(rnd(#chars)) + 1
        print(chars[c], drop.x, drop.y, 11)
    end

    -- Draw story
    if story_index <= #story then
        local line = story[story_index]
        print(line, 16, 64, 7)
    end
end
