pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

cube_pals = {
  [0] = { [5] = 5, [6] = 6, [7] = 7 }, -- original
  { [5] = 14, [6] = 8, [7] = 2 }, -- red
  { [5] = 4, [6] = 10, [7] = 9 }, -- yellow
  { [5] = 5, [6] = 11, [7] = 3 }, -- green
  { [5] = 5, [6] = 12, [7] = 15 } -- blue
}

function draw_scene_cube(cube)
  local c2D = camera:screen_xy(cube.l[1], cube.l[2], cube.l[3])
  local rp = camera.render_params[camera.dir % 8]

  local sid = rp[1]

  if not cube.selected then
    --   if cube.sel and flr(t/3)%2 == 0 then
    pal(cube_pals[cube.c + 1])
  end
  spr(sid, c2D.x, c2D.y, 2, 2, rp[7])

  -- reset cube palette
  pal(cube_pals[0])

  -- underline base
  if cube.z == 0 then
    local hspr, hflip = rp[8], rp[9]
    spr(hspr, c2D.x, c2D.y, 2, 2, hflip)
  end
end

scene = {
  last_cube_id = 0,
  cubes = {},
  player = {},
  ordered = {},
  locations = {},
  add_cube = function(self, x, y, z, c)
    local id = self.last_cube_id + 1
    -- add to cubes
    self.cubes[id] = {
      id = id,
      l = { x, y, z },
      o = { 0, 0, 0 }, -- current offset = mo * mt
      mo = { 0, 0, 0 }, -- move offset (initial diff to tween from)
      mt = 0, -- move time 0-1 (time left until offset should be zero'd out)
      md = 0, -- move duriation (how long it should take us to get from 0 - 1)
      z = z,
      c = c,
      selected = false,
      update = nil,
      screen_distance = function(self)
        return camera:camera_dist(self.l[1], self.l[2], self.l[3])
      end
    }

    add(self.ordered, id)

    self.locations[loc_hash(x, y, z)] = id

    self.last_cube_id = id
  end,

  compare_cubes = function(self)
    local this = self
    return function(a, b)
      local ad, bd = this.cubes[a]:screen_distance(), this.cubes[b]:screen_distance()
      return ad - bd < 0
    end
  end,

  sort_cubes = function(self)
    log("sorting:" .. camera.dir)
    qsort(self.ordered, self:compare_cubes())
    log("sorted:" .. ins(self.ordered))
  end,

  connected = function(self, lochash)
    local brick, unvisited = {}, { [lochash] = true }
    local cube = self.cubes[self.locations[lochash]]
    local colour = cube.c


    while next(unvisited) do
      local nuv = {}
      for uv, _ in pairs(unvisited) do
        brick[uv] = true
        log({uv, brick, unvisited})

        local ns = { uv + 1024, uv - 1024, uv + 32, uv - 32, uv + 1, uv - 1 }
        for ne in all(ns) do
          local cube = self.cubes[self.locations[ne]]
          if not brick[ne] and not unvisited[ne] and cube and cube.c == colour then
            nuv[ne] = true
          end
        end
      end
      unvisited = nuv
    end

    local locs = {}

    for b, _ in pairs(brick) do
      add(locs, b)
    end

    return locs
  end,

  try_push = function(self, px, py, dx, dy)
    local lh = loc_hash(px, py, 0)

    -- if nothing in the way return true
    if not self.locations[lh] then return true end

    local push_cube = self.cubes[self.locations[lh]]
    local connected_locs = self:connected(lh)

    -- if something in the way and not same colour we can't move them
    for loc in all(connected_locs) do
      local pushed_loc = loc + dx + dy*32
      local overlap_cube = self.cubes[self.locations[pushed_loc]]
      if overlap_cube and overlap_cube.c != push_cube.c then
        -- can't move something in the way!
        return false
      end
    end

    -- move all cubes
    for loc in all(connected_locs) do
      local this_cube = self.cubes[self.locations[loc]]
      this_cube.l = { this_cube.l[1] + dx, this_cube.l[2] + dy, this_cube.l[3]}
    end

    self:reset_locations()
    self:sort_cubes()
    -- we moved!
    return true
  end,

  reset_locations = function(self)
    local new_locations = {}
    for id, cube in pairs(self.cubes) do
      new_locations[loc_hash(cube.l[1], cube.l[2], cube.l[3])] = cube.id
    end

    self.locations = new_locations
  end
}


function loc_hash(x, y, z)
  -- board - x, y, z in [-32, 32]
  return x + y * 32 + z * 1024
end



--dirs
-- ortho 0, 2, 4, 6
--    z
--    |     cy
--    |  -
--     -
--       -
--          cx
camera = {
  -- between 0 & 15
  dir = 0,

  -- {spr, xx, yx, xy, yy, zy, flip, hspr, hflip, flr }
  render_params = {
    [0] = { 192, 6, 6, 3, -3, -6, false, 202, false, 224 },
    { 196, 3, 8, 3, -2, -6, false, 204, true, 228 }, --1
    { 198, 9, 0, 0, -4, -6, false, 206, false, 230 }, --2
    { 196, 8, 3, 2, -3, -6, true, 204, false, 226 }, --3
    { 192, 6, 6, 3, -3, -6, true, 202, true, 224 }, --4
    { 194, 3, 8, 3, -2, -6, true, 204, true, 228 }, --5
    { 200, 9, 0, 0, -4, -6, true, 206, true, 230 }, --6
    { 194, 8, 3, 2, -3, -6, false, 204, false, 226 } --7
  },

  rp = function(self)
    return self.render_params[self.dir % 8]
  end,

  rotate_z = function(self, dx)
    self.dir = (self.dir + dx) % 16
    scene:sort_cubes()
  end,

  -- returns a normalized x, y wrt the camera orientation
  -- such that x is always forwards right & y is always backwards right
  normalized_xy = function(self, _x, _y)
    local rotate_dirs = { _x, _y, -_x, -_y, _x }
    local idx = flr((self.dir + 2) / 4) % 4
    return rotate_dirs[idx + 1], rotate_dirs[idx + 2]
  end,

  -- distance to camera, used for sort functions
  camera_dist = function(self, _x, _y, z)
    local x, y = self.normalized_xy(self, _x, _y)
    return (x - y) * 32 + z
  end,

  screen_xy = function(self, x, y, z)
    local p = {}
    local rp = self.render_params[self.dir % 4]
    local cx, cy = self:normalized_xy(x, y)

    return {
      x = 64 - 9 + rp[2] * cx + rp[3] * cy,
      y = 64 + rp[4] * cx + rp[5] * cy + rp[6] * z
    }
  end
}
