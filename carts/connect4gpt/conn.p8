pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- Initialize the game state
function _init()
    player_colors = {6, 8} -- Default colors
    selected_color = 1
    init_start_screen()
end

function init_start_screen()
    start_screen = true
end

function init_game_play()
    start_screen = false
    board = {}
    for y = 1, 6 do
        board[y] = {}
        for x = 1, 7 do
            board[y][x] = 0
        end
    end
    current_player = 1
    game_over = false
    winner = 0
    selected_column = 1
    animating = false
    anim_y = 0
    drop_row = 0
    particles = {}
    win_positions = {}
    fire_positions = {}
end

-- Particle class
Particle = {}
Particle.__index = Particle

function Particle.new(x, y, color, dx, dy, life, size)
    local p = setmetatable({}, Particle)
    p.x = x
    p.y = y
    p.dx = dx or rnd({-1, 1})
    p.dy = dy or rnd({-1, -2})
    p.life = life or 20 + rnd(20)
    p.color = color or 7
    p.size = size or 2
    return p
end

function Particle:update()
    self.x += self.dx
    self.y += self.dy
    self.dy -= 0.05 -- Reverse gravity for fire effect
    self.life -= 1
    self.size = max(0.5, self.size - 0.1) -- Diminish in size over time
end

function Particle:draw()
    circfill(self.x, self.y, self.size, self.color)
end

-- Draw the start screen
function draw_start_screen()
    cls()
    print("CONNECT 4", 30, 20, 7)
    print("PRESS X TO START", 20, 50, 7)
    print("SELECT PLAYER COLORS:", 20, 80, 7)
    print("1: RED / 2: YELLOW", 20, 100, 7)
    print("CURRENT PLAYER 1 COLOR: " .. player_colors[1], 20, 110, player_colors[1])
    print("CURRENT PLAYER 2 COLOR: " .. player_colors[2], 20, 120, player_colors[2])
    print("PRESS LEFT/RIGHT TO CHANGE COLORS", 20, 150, 7)
end

-- Draw the board and pieces
function _draw()
    if start_screen then
        draw_start_screen()
        return
    end

    cls()
    -- Draw the board grid
    for y = 1, 6 do
        for x = 1, 7 do
            rectfill(16 * x, 16 * y, 16 * x + 15, 16 * y + 15, 1)
            circfill(16 * x + 8, 16 * y + 8, 6, 7)
        end
    end

    -- Draw the pieces
    for y = 1, 6 do
        for x = 1, 7 do
            if board[y][x] == 1 then
                circfill(16 * x + 8, 16 * y + 8, 6, player_colors[1]) -- Player 1's pieces
            elseif board[y][x] == 2 then
                circfill(16 * x + 8, 16 * y + 8, 6, player_colors[2]) -- Player 2's pieces
            end
        end
    end

    -- Highlight the selected column
    rect(16 * selected_column, 0, 16 * selected_column + 15, 15, 7)

    -- Show the current player's piece above the column if not animating
    if not animating then
        if current_player == 1 then
            circfill(16 * selected_column + 8, 8, 6, player_colors[1])
        else
            circfill(16 * selected_column + 8, 8, 6, player_colors[2])
        end
    end

    -- Animate the falling piece
    if animating then
        if current_player == 1 then
            circfill(16 * selected_column + 8, anim_y, 6, player_colors[1])
        else
            circfill(16 * selected_column + 8, anim_y, 6, player_colors[2])
        end
    end

    -- Draw particles
    for p in all(particles) do
        p:draw()
    end

    -- Display the current player's turn or the winner
    if not game_over then
        print("Player " .. current_player .. "'s turn", 10, 110, 7)
    else
        print("Player " .. winner .. " wins!", 10, 110, 7)
        print("PRESS X TO RESTART", 10, 120, 7)
    end
end

-- Check for a win
function check_win()
    win_positions = {}
    -- Check horizontal, vertical and diagonal lines for a win
    for y = 1, 6 do
        for x = 1, 4 do
            if board[y][x] > 0 and board[y][x] == board[y][x+1] and board[y][x] == board[y][x+2] and board[y][x] == board[y][x+3] then
                for i = 0, 3 do
                    add(win_positions, {x = x+i, y = y})
                end
                return board[y][x]
            end
        end
    end
    for y = 1, 3 do
        for x = 1, 7 do
            if board[y][x] > 0 and board[y][x] == board[y+1][x] and board[y][x] == board[y+2][x] and board[y][x] == board[y+3][x] then
                for i = 0, 3 do
                    add(win_positions, {x = x, y = y+i})
                end
                return board[y][x]
            end
        end
    end
    for y = 1, 3 do
        for x = 1, 4 do
            if board[y][x] > 0 and board[y][x] == board[y+1][x+1] and board[y][x] == board[y+2][x+2] and board[y][x] == board[y+3][x+3] then
                for i = 0, 3 do
                    add(win_positions, {x = x+i, y = y+i})
                end
                return board[y][x]
            end
            if board[y][x+3] > 0 and board[y][x+3] == board[y+1][x+2] and board[y][x+3] == board[y+2][x+1] and board[y][x+3] == board[y+3][x] then
                for i = 0, 3 do
                    add(win_positions, {x = x+3-i, y = y+i})
                end
                return board[y][x+3]
            end
        end
    end
    return 0
end

-- Drop a piece into the board with animation
function drop_piece(col)
    if not game_over and not animating then
        -- Find the first empty spot in the selected column
        for y = 6, 1, -1 do
            if board[y][col] == 0 then
                drop_row = y
                anim_y = 8
                animating = true
                break
            end
        end
    end
end

-- Update the animation and game state
function _update()
    if start_screen then
        -- Player color selection
        if btnp(4) then
            init_game_play() -- Initialize game state
        end

        -- Change colors for player 1
        if btnp(2) then
            player_colors[1] = (player_colors[1] % 15) + 1
        end

        -- Change colors for player 2
        if btnp(3) then
            player_colors[2] = (player_colors[2] % 15) + 1
        end

        return
    end

    if not game_over then
        -- Move the selection left or right
        if not animating then
            if btnp(0) then selected_column = max(1, selected_column - 1) end
            if btnp(1) then selected_column = min(7, selected_column + 1) end

            -- Drop the piece in the selected column
            if btnp(4) then drop_piece(selected_column) end
        else
            -- Animate the falling piece
            anim_y += 4
            -- Add speed particles
            for i = 1, 3 do
                local color = current_player == 1 and player_colors[1] or player_colors[2]
                add(particles, Particle.new(16 * selected_column + 8, anim_y - 8, color, rnd({-1, 1}), -rnd(2), 10, 2))
            end
            if anim_y >= 16 * drop_row + 8 then
                board[drop_row][selected_column] = current_player
                if check_win() > 0 then
                    game_over = true
                    winner = current_player
                    -- Mark winning positions as on fire
                    fire_positions = win_positions
                else
                    current_player = 3 - current_player -- Switch player
                end
                animating = false
            end
        end
    else
        -- Restart the game
        if btnp(4) then
            init_start_screen() -- Reinitialize game state
        end
    end

    -- Update particles
    for p in all(particles) do
        p:update()
        if p.life <= 0 then
            del(particles, p)
        end
    end

    -- Emit fire particles from winning positions
    if game_over and #fire_positions > 0 then
        for _, pos in ipairs(fire_positions) do
            if rnd() < 0.5 then -- Emit particles occasionally
                local color = winner == 1 and player_colors[1] or player_colors[2] -- Match the color of the winning player's pieces
                add(particles, Particle.new(16 * pos.x + 8, 16 * pos.y + 8, color, 2*(rnd() - 0.5), (rnd() - 1)/2, 20 + rnd(10), 3))
            end
        end
    end
end
