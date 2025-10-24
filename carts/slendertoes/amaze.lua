
-- Slendertoes Maze Game

-- Pico-8 version
-- version 42
-- __lua__
-- Maze game where the player navigates through a maze to reach a goal
-- __gfx__
--
--
-- Maze represented as a 2D array
maze = {
  {1, 1, 1, 1, 1, 1, 1, 1},
  {1, 0, 0, 0, 0, 0, 2, 1},
  {1, 0, 1, 1, 1, 0, 0, 1},
  {1, 0, 0, 0, 1, 0, 1, 1},
  {1, 1, 1, 0, 1, 0, 0, 1},
  {1, 2, 0, 0, 0, 0, 0, 1},
  {1, 1, 1, 1, 1, 1, 3, 1},
}
-- Player position
player = {x = 1, y = 1} -- starting position
-- Goal position
goal = {x = 6, y = 6} -- goal position
-- Player movement speed
player_speed = 1
-- Player sprite index
player_sprite = 2
-- Goal sprite index
goal_sprite = 3
-- Wall sprite index
wall_sprite = 0
-- Empty space sprite index
empty_sprite = 1
-- Player movement function
function move_player(dx, dy)
  local new_x = player.x + dx
  local new_y = player.y + dy

  -- Check bounds and walls
  if new_x >= 0 and new_x < #maze[1] and new_y >= 0 and new_y < #maze then
    if maze[new_y][new_x] ~= 1 then -- not a wall
      player.x = new_x
      player.y = new_y
    end
  end

  -- Check if player reached the goal
  if player.x == goal.x and player.y == goal.y then
    print("You reached the goal!")
    -- Reset player position or implement game over logic here
    player.x = 1
    player.y = 1
  end
end
-- pico 8 update
function _update()
  -- Player movement input
  if (btn(0)) then move_player(-player_speed, 0) end -- left
  if (btn(1)) then move_player(player_speed, 0) end -- right
  if (btn(2)) then move_player(0, -player_speed) end -- up
  if (btn(3)) then move_player(0, player_speed) end -- down
end


-- pico 8 draw

function _draw()
  cls(0)
  -- draw maze
  for y=0,7 do
    for x=0,7 do
      if (maze[y][x] == 1) then
        spr(0, x*8, y*8)
      elseif (maze[y][x] == 2) then
        spr(1, x*8, y*8)
      end
    end
  end

  -- draw player
  spr(2, player.x * 8, player.y * 8)

  -- draw goal
  spr(3, goal.x * 8, goal.y * 8)
end