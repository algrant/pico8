pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- Constants
grid_size = 5
cell_size = 16
p1_color = 8 -- player 1 color
p2_color = 9 -- player 2 color

-- Board and pieces
board = {}
pieces = {}
view_mode = 'board' -- can be 'board' or 'cards'

-- Card definitions
cards = {
    { name = "tiger", moves = { { 0, -2 }, { 0, 1 } } },
    { name = "dragon", moves = { { -2, 1 }, { 2, 1 }, { -1, -1 }, { 1, -1 } } },
    { name = "frog", moves = { { -2, 0 }, { -1, 1 }, { 1, -1 } } },
    { name = "rabbit", moves = { { 2, 0 }, { 1, 1 }, { -1, -1 } } },
    { name = "crab", moves = { { -2, 0 }, { 2, 0 }, { 0, 1 } } }
    -- More cards can be added here
}

-- Players' cards
p1_cards = { 2, 1 } -- Player 1 starts with cards Tiger and Dragon
p2_cards = { 3, 4 } -- Player 2 starts with cards Frog and Rabbit
center_card = 5 -- Crab card is the center card

selected_piece = nil
selected_card = 1
cursor_x = 1
cursor_y = 1
current_player = 1
game_over = false
winner = nil

-- Initialize the board and pieces
function init_board()
    for x = 1, grid_size do
        board[x] = {}
        for y = 1, grid_size do
            board[x][y] = 0 -- Empty cell
        end
    end

    -- Player 1 pieces
    pieces[1] = { type = 'master', x = 3, y = 1, player = 1 }
    pieces[2] = { type = 'pawn', x = 1, y = 1, player = 1 }
    pieces[3] = { type = 'pawn', x = 2, y = 1, player = 1 }
    pieces[4] = { type = 'pawn', x = 4, y = 1, player = 1 }
    pieces[5] = { type = 'pawn', x = 5, y = 1, player = 1 }

    -- Player 2 pieces
    pieces[6] = { type = 'master', x = 3, y = 5, player = 2 }
    pieces[7] = { type = 'pawn', x = 1, y = 5, player = 2 }
    pieces[8] = { type = 'pawn', x = 2, y = 5, player = 2 }
    pieces[9] = { type = 'pawn', x = 4, y = 5, player = 2 }
    pieces[10] = { type = 'pawn', x = 5, y = 5, player = 2 }
end

-- Draw the board
function draw_board()
    for x = 1, grid_size do
        for y = 1, grid_size do
            colour = (x + y % 2) % 2 == 1 and 7 or 5
            rectfill((x - 1) * cell_size, (y - 1) * cell_size, x * cell_size - 1, y * cell_size - 1, colour)
        end
    end
end

-- Draw the pieces
function draw_pieces()
    for i = 1, #pieces do
        local p = pieces[i]
        local color = p.player == 1 and p1_color or p2_color
        circfill((p.x - 1) * cell_size + cell_size / 2, (p.y - 1) * cell_size + cell_size / 2, 6, color)
        if p.type == 'master' then
            circ((p.x - 1) * cell_size + cell_size / 2, (p.y - 1) * cell_size + cell_size / 2, 4, 0)
        end
    end

    -- Highlight available move positions
    if selected_piece then
        local card = cards[selected_card]
        for i = 1, #card.moves do
            local dx, dy = card.moves[i][1], card.moves[i][2]
            if selected_piece.player == 2 then
                dx = -dx
                dy = -dy
            end
            local nx = selected_piece.x + dx
            local ny = selected_piece.y + dy
            if nx >= 1 and nx <= grid_size and ny >= 1 and ny <= grid_size then
                -- Check if move is valid
                -- if is_valid_move(selected_piece, card, dx, dy) then
                rectfill((nx - 1) * cell_size, (ny - 1) * cell_size, nx * cell_size - 1, ny * cell_size - 1, 14)
                -- end
            end
        end
    end
end
-- Draw the cards
function draw_cards()
    local y_offset = 80
    for i = 1, 2 do
        local card = cards[p1_cards[i]]
        print(card.name, 10, y_offset + (i - 1) * 10, 8)
    end

    for i = 1, 2 do
        local card = cards[p2_cards[i]]
        print(card.name, 100, y_offset + (i - 1) * 10, 9)
    end

    local center = cards[center_card]
    print(center.name, 60, y_offset + 20, 7)
end

-- Draw the cursor on the board
function draw_cursor()
    rect(cursor_x * cell_size - cell_size, cursor_y * cell_size - cell_size, cursor_x * cell_size - 1, cursor_y * cell_size - 1, 11)
end

-- Check if a move is valid
function is_valid_move(piece, card, dx, dy)
    local nx = piece.x + dx
    local ny = piece.y + dy

    if nx < 1 or nx > grid_size or ny < 1 or ny > grid_size then
        return false
    end

    -- Check if the destination cell is occupied by a friendly piece
    for i = 1, #pieces do
        if pieces[i].x == nx and pieces[i].y == ny and pieces[i].player == piece.player then
            return false
        end
    end

    return true
end

-- Move the selected piece
function move_piece(piece, card_index)
    local card = cards[card_index]

    -- Loop through card moves to find a valid one
    for i = 1, #card.moves do
        local dx, dy = card.moves[i][1], card.moves[i][2]

        -- Adjust movement based on player
        if piece.player == 2 then
            dx = -dx
            dy = -dy
        end

        if is_valid_move(piece, card, dx, dy) then
            -- Update the piece's position
            piece.x = piece.x + dx
            piece.y = piece.y + dy

            -- Swap the used card with the center card
            if current_player == 1 then
                del(p1_cards, card_index)
                add(p1_cards, center_card)
                center_card = card_index
            else
                del(p2_cards, card_index)
                add(p2_cards, center_card)
                center_card = card_index
            end
            center_card = card_index

            -- Switch turns
            current_player = 3 - current_player
            return
        end
    end
end

-- Select a piece to move
function select_piece_at_cursor()
    for i = 1, #pieces do
        local p = pieces[i]
        if p.x == cursor_x and p.y == cursor_y and p.player == current_player then
            selected_piece = p
            return
        end
    end
    selected_piece = nil
end

-- Toggle view mode between board and cards
function toggle_view_mode()
    view_mode = view_mode == 'board' and 'cards' or 'board'
end

-- Select the card or piece based on view mode
function select()
    if view_mode == 'board' then
        select_piece_at_cursor()
    elseif view_mode == 'cards' then
        -- Update selected card based on position
        selected_card = mid(1, selected_card + (cursor_y - 80) / 10, 2)
    end
end

-- Update cursor movement based on view mode
function move_cursor(dx, dy)
    if view_mode == 'board' then
        cursor_x = mid(1, cursor_x + dx, grid_size)
        cursor_y = mid(1, cursor_y + dy, grid_size)
    elseif view_mode == 'cards' then
        -- Move cursor within card selection area (assuming 2 cards per player and 1 center card)
        local card_index = selected_card + (current_player - 1) * 2
        local card_y = 80 + (card_index - 1) * 10
        if cursor_x == 1 then
            cursor_y = mid(80, cursor_y + dy, 90)
        end
    end
end

-- Execute the player's move
function execute_move()
    if selected_piece then
        move_piece(selected_piece, selected_card)
        selected_piece = nil
    end
end

-- Victory Conditions
function check_victory()
    for i = 1, #pieces do
        local p = pieces[i]
        if p.type == 'master' then
            -- Check if a master is captured
            if p.x == cursor_x and p.y == cursor_y and p.player ~= current_player then
                game_over = true
                winner = current_player
                return true
            end
            -- Check if the master reached the opponent's starting position
            if p.player == 1 and p.y == grid_size then
                game_over = true
                winner = 1
                return true
            elseif p.player == 2 and p.y == 1 then
                game_over = true
                winner = 2
                return true
            end
        end
    end
    return false
end

-- Reset the game
function reset_game()
    game_over = false
    winner = nil
    selected_piece = nil
    cursor_x = 1
    cursor_y = 1
    current_player = 1
    p1_cards = { 1, 2 }
    p2_cards = { 3, 4 }
    center_card = 5
    init_board()
end

-- Display the game-over screen
function draw_game_over()
    cls()
    print("Player " .. winner .. " wins!", 40, 50, 7)
    print("Press X to restart", 30, 70, 7)
end

-- Update function
-- Update function
function _update()
    if game_over then
        if btnp(5) then
            -- X button to restart
            reset_game()
        end
    else
        if btnp(5) then toggle_view_mode() end -- Toggle view mode

        if view_mode == 'board' then
            if btnp(0) then move_cursor(-1, 0) end -- left
            if btnp(1) then move_cursor(1, 0) end -- right
            if btnp(2) then move_cursor(0, -1) end -- up
            if btnp(3) then move_cursor(0, 1) end -- down
        elseif view_mode == 'cards' then
            if btnp(2) then cursor_y = max(80, cursor_y - 10) end -- up
            if btnp(3) then cursor_y = min(100, cursor_y + 10) end -- down
        end

        if btnp(4) then select() end -- O button to confirm selection

        if view_mode == 'board' and selected_piece then
            if btnp(5) then
                -- Confirm move
                execute_move()
            end
        end

        if check_victory() then
            game_over = true
        end
    end
end

-- Draw function
function _draw()
    if game_over then
        draw_game_over()
    else
        cls()
        draw_board()
        draw_pieces()
        draw_cards()

        if view_mode == 'board' then
            draw_cursor()
        elseif view_mode == 'cards' then
            -- Draw cursor in card selection area
            rect(cursor_x * cell_size - cell_size, cursor_y - 5, cursor_x * cell_size - 1, cursor_y + 5, 10)
        end

        -- Highlight selected card
        if view_mode == 'cards' then
            local y_offset = 80 + (selected_card - 1) * 10
            rect(8, y_offset - 1, 48, y_offset + 7, 7)
        end

        -- Highlight selected piece
        if selected_piece and view_mode == 'board' then
            rect(selected_piece.x * cell_size - cell_size, selected_piece.y * cell_size - cell_size, selected_piece.x * cell_size - 1, selected_piece.y * cell_size - 1, 11)
        end
    end
end

-- Initialization
function _init()
    init_board()
end
