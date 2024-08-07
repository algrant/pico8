pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- Initialize the game state
function _init()
    player_colors = {3, 12} -- Default colors
    selected_color = 1
    init_start_screen()
end

function init_start_screen()
    start_screen = true
    menu_option = 1 -- Current selected menu option
    max_menu_option = 3
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

function get_menu_text(option)
    if option == 1 then
        return "player 1 color: " .. player_colors[1]
    elseif option == 2 then
        return "player 2 color: " .. player_colors[2]
    elseif option == 3 then
        return "start game"
    end
end

function get_menu_color(option)
    if option == 3 then
        return 7
    else
        return player_colors[option]
    end
end

-- Draw the start screen
function draw_start_screen()
    cls()
    print("connect 4", 30, 20, 7)

    -- Draw menu options
    for i=1,max_menu_option do
        local y = 40 + (i-1) * 20
        if i == menu_option then
            print("> " .. get_menu_text(i), 20, y, get_menu_color(i))
        else
            print("  " .. get_menu_text(i), 20, y, get_menu_color(i))
        end
    end
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
        print("player " .. current_player .. "'s turn", 10, 110, 7)
    else
        print("player " .. winner .. " wins!", 10, 110, 7)
        print("press x to restart", 10, 120, 7)
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
        -- Navigate menu
        if btnp(2) then menu_option = max(1, menu_option - 1) end
        if btnp(3) then menu_option = min(max_menu_option, menu_option + 1) end
        -- Select menu option
        if menu_option == 1 or menu_option == 2 then
            -- Change colors for player 1 or player 2
            local color_index = menu_option
            if btnp(0) then
                player_colors[color_index] = (player_colors[color_index] % 15) + 1
            end
            if btnp(1) then
                player_colors[color_index] = (player_colors[color_index] % 15) - 1
            end
        end

        if btnp(4) and menu_option == 3 then
            init_game_play() -- Start the game
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
