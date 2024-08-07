pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Connect 4 in Pico-8

-- Initialize the board
function _init()
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

  function Particle.new(x, y, color, dx, dy, life)
    local p = setmetatable({}, Particle)
    p.x = x
    p.y = y
    p.dx = dx or rnd({-1, 1})
    p.dy = dy or rnd({-1, -2})
    p.life = life or 20 + rnd(20)
    p.color = color or 7
    return p
  end

  function Particle:update()
    self.x += self.dx
    self.y += self.dy
    self.dy += 0.1
    self.life -= 1
  end

  function Particle:draw()
    local c = self.color
    if self.life < 10 then
      c = 7 -- Fade to white
    elseif self.life < 20 then
      c = 9 -- Fade to yellow
    elseif self.life < 30 then
      c = 8 -- Fade to orange
    end
    circfill(self.x, self.y, 2, c)
  end

  -- Draw the board and pieces
  function _draw()
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
          circfill(16 * x + 8, 16 * y + 8, 6, 8) -- Player 1's pieces
        elseif board[y][x] == 2 then
          circfill(16 * x + 8, 16 * y + 8, 6, 9) -- Player 2's pieces
        end
      end
    end

    -- Highlight the selected column
    rect(16 * selected_column, 0, 16 * selected_column + 15, 15, 7)

    -- Show the current player's piece above the column if not animating
    if not animating then
      if current_player == 1 then
        circfill(16 * selected_column + 8, 8, 6, 8)
      else
        circfill(16 * selected_column + 8, 8, 6, 9)
      end
    end

    -- Animate the falling piece
    if animating then
      if current_player == 1 then
        circfill(16 * selected_column + 8, anim_y, 6, 8)
      else
        circfill(16 * selected_column + 8, anim_y, 6, 9)
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
          local color = current_player == 1 and 8 or 9
          add(particles, Particle.new(16 * selected_column + 8, anim_y - 8, color, rnd({-1, 1}), -rnd(2), 10))
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
        if rnd() < 0.2 then -- Emit particles occasionally
          local color = rnd({8, 9, 10}) -- Use orange, yellow, and white for fire effect
          add(particles, Particle.new(16 * pos.x + 8, 16 * pos.y + 8, color, rnd({-1, 1}), rnd({-1, -2}), 20 + rnd(20)))
        end
      end
    end
  end


