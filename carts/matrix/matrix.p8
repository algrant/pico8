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

chars = {"a", "b", "c", "d", "e", "f", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "x", "y", "z"}
drops = {}
story_pos = 1
story_line = 1
story_delay = 0
story_active = false
active_drops = {}

function init_drops()
    for i=1, 128 do
        add(drops, {x=rnd(128), y=rnd(128), speed=rnd(2)+1, char=chars[flr(rnd(#chars))+1]})
    end
end

function activate_story_drops(line)
    active_drops = {}
    for i=1, #line do
        local drop = {char=sub(line, i, i), x=16+(i-1)*4, y=-flr(rnd(32)), target_y=64, speed=rnd(2)+1, active=true}
        add(active_drops, drop)
    end
    story_active = true
end

function update_drops()
    for drop in all(drops) do
        drop.y += drop.speed
        if drop.y > 128 then
            drop.y = 0
            drop.x = rnd(128)
            drop.char = chars[flr(rnd(#chars))+1]
        end
    end

    if story_active then
        local all_in_place = true
        for drop in all(active_drops) do
            if drop.y < drop.target_y then
                drop.y += drop.speed * 0.5
                all_in_place = false
            else
                drop.y = drop.target_y
            end
        end
        if all_in_place then
            story_delay += 1
            if story_delay > 50 then
                for drop in all(active_drops) do
                    drop.speed = rnd(2)+1
                    drop.target_y = 128 + flr(rnd(32))
                end
                story_delay = 0
                story_active = false
                story_line += 1
            end
        end
    else
        if story_line <= #story and #active_drops == 0 then
            activate_story_drops(story[story_line])
        end
    end
end

function draw_drops()
    for drop in all(drops) do
        print(drop.char, drop.x, drop.y, 11)
    end
    for drop in all(active_drops) do
        print(drop.char, drop.x, drop.y, 7)
    end
end

-- Initialize
init_drops()

-- Update
function _update()
    update_drops()
end

-- Draw
function _draw()
    cls(0)
    draw_drops()
end
