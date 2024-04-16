pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

pipe_types = {
  straight = {
    sprs = { 1, 3, 1, 3 },
    flpx = { 0, 0, 0, 0 },
    flpy = { 0, 0, 0, 0 },
    inlets = { { 1, 2 }, { 3, 4 }, { 1, 2 }, { 3, 4 } }
  },
  bent = {
    sprs = { 7, 7, 7, 7 },
    flpx = { 0, 0, 1, 1 },
    flpy = { 0, 1, 1, 0 },
    inlets = { { 4, 1 }, { 1, 3 }, { 3, 2 }, { 2, 4 } }
  },
  splitfour = {
    sprs = { 5, 5, 5, 5 },
    flpx = { 0, 0, 0, 0 },
    flpy = { 0, 0, 0, 0 },
    inlets = { { 1, 2, 3, 4 }, { 1, 2, 3, 4 }, { 1, 2, 3, 4 }, { 1, 2, 3, 4 } }
  },
  splittee = {
    sprs = { 9, 11, 9, 11 },
    flpx = { 0, 0, 0, 1 },
    flpy = { 0, 0, 1, 0 },
    inlets = { { 1, 2, 4 }, { 1, 3, 4 }, { 1, 2, 3 }, { 2, 3, 4 } }
  },
  doublecross = {
    sprs = { 1, 3, 1, 3 },
    flpx = { 0, 0, 0, 0 },
    flpy = { 0, 0, 0, 0 },
    inlets = { { 1, 2 }, { 3, 4 }, { 1, 2 }, { 3, 4 } },
    double = 1
  },
  doublebent = {
    sprs = { 7, 7, 7, 7 },
    flpx = { 0, 0, 1, 1 },
    flpy = { 0, 1, 1, 0 },
    inlets = { { 4, 1 }, { 1, 3 }, { 3, 2 }, { 2, 4 } },
    double = 2
  }
}

function log(_smthng)
  printh(ins(_smthng), "log")
end

local black, dark_blue, dark_purple, dark_green, brown, dark_grey, light_grey, white, red, orange, yellow, green, blue, lavender, pink, light_peach = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15

ppal = {
  -- pipe outline, pipe interior, liquid main, liquid low, liquid dark
  { [11] = green, [3] = dark_green, [5] = black, [6] = light_grey },
  { [11] = blue, [3] = dark_blue, [5] = black, [6] = light_grey },
  { [11] = red, [3] = dark_purple, [5] = black, [6] = light_grey },
  { [11] = orange, [3] = brown, [5] = black, [6] = light_grey },
  { [11] = yellow, [3] = orange, [5] = black, [6] = light_grey }
}
new_pipe = function(type, x, y, rot, vel, fill, flows)
  type = type or pipe_types.lr
  return {
    type = type or pipe_types.lr,
    x = x or 1,
    y = y or 1,
    rot = rot or 0,
    fill = fill or 0, -- how full is our flow (0,16)
    vel = vel or 1,
    fint = function(self) return flr(self.fill) end,
    flows = flows or {}, -- nil or table with count matching inlets table, if double make two tables...
    col = 0,
    add_flow = function(self, dir, col)
      -- handle already having flow / not having an inlet
      for i in all(self.type.inlets[self.rot]) do
        printh("wtf" .. i, "log")
        if i == dir then
          self.flows[dir] = col
          self.col = col
          return true
        end
      end

      return false
    end,
    draw = function(self)
      pal(ppal[self.col])
      local rots = { rot }
      -- add a rotated version of the pipe when necessary
      if self.type.double != nil then
        add(rots, (self.rot + self.type.double - 1) % 4 + 1)
      end

      for r in all(rots) do
        local fx, fy = self.type.flpx[r] == 1, self.type.flpy[r] == 1
        local tx, ty = self.x * 16, self.y * 16
        -- draw fluids
        -- draw incoming fluids
        for inlet in all(self.type.inlets[r]) do
          local xos = { 0, 8, 4, 4 }
          local yos = { 4, 4, 0, 8 }
          local sp, x, y = 111 + inlet, tx + xos[inlet], ty + yos[inlet]
          spr(sp, x, y)

          if self.flows[inlet] != nil then
            sp = 115 + inlet
            if self:fint() < 8 then
              local cxs = { x, x + 8 - self:fint(), x, x }
              local cys = { y, y, y, y + 8 - self:fint() }
              local cws = { self:fint(), self:fint(), 8, 8 }
              local chs = { 8, 8, self:fint(), self:fint() }

              local cx, cy, cw, ch = cxs[inlet], cys[inlet], cws[inlet], chs[inlet]
              clip(cx, cy, cw, ch)
            end
            spr(sp, x, y)
            clip()
          elseif next(self.flows) != nil and self:fint() >= 8 then
            -- connected flows...
            sp = 115 + inlet

            -- left [x + 8 - self:fint(), self:fint(), 8, y]
            local fff = self:fint() - 8
            local cxs = { x + 8 - fff, x, x, x }
            local cws = { fff, fff, 8, 8 }

            local cys = { y, y, y + 8 - fff, y }
            local chs = { 8, 8, fff, fff }

            local cx, cy, cw, ch = cxs[inlet], cys[inlet], cws[inlet], chs[inlet]
            clip(cx, cy, cw, ch)
            spr(sp, x, y)
            clip()
          end

          -- piece outline
          spr(self.type.sprs[r], tx, ty, 2, 2, fx, fy)
        end
      end
      pal()
    end,
    update = function(self)
      if next(self.flows) != nil then
        if self.fill < 16 then
          self.fill = min(16, self.fill + self.vel)
        elseif self.fill == 16 then
          self.fill = 17
          log("ok")
          return true -- outlets which are now triggering..?
        end
      end

      return false
    end,
    neighbors = function(self)
      local xs = { -1, 1, 0, 0 }
      local ys = { 0, 0, -1, 1 }
      local opp_dir = { 2, 1, 4, 3 }
      out = {}
      for i in all(self.type.inlets[self.rot]) do
        log({ loc_hash(self.x + xs[i], self.y + ys[i]), opp_dir[i], 1 })

        if self.flows[i] == nil then
          -- this needs work...
          local col = 1
          add(out, { loc_hash(self.x + xs[i], self.y + ys[i]), opp_dir[i], self.col })
        end
      end
      return out
    end
  }
end
loc_hash = function(x, y) return x + y * 32 end

add_pipe = function(pipe)
  pipes[loc_hash(pipe.x, pipe.y)] = pipe
end

pipes = {}
pipe_locs = {}

local x, y = 1, 0
ordered_types = {
  pipe_types.straight,
  pipe_types.bent,
  pipe_types.splitfour,
  pipe_types.splittee
  -- pipe_types.doublecross,
  -- pipe_types.doublebent,
}

for y = 1, 7 do
  for x = 0, 7 do
    local type, rot = rnd(ordered_types), ceil(rnd(4))
    if y == 1 and x == 0 then
      type, rot = pipe_types.splittee, 1
    end
    if y == 7 and x == 7 then
      type, rot = pipe_types.splittee, 3
    end
    add_pipe(new_pipe(
      type,
      x,
      y,
      rot,
      2 + rnd(2)
    ))
  end
end

pipes[loc_hash(0, 1)]:add_flow(1, ceil(rnd(#ppal)))
pipes[loc_hash(7, 7)]:add_flow(2, ceil(rnd(#ppal)))

function init_some_pipes()
  for type in all(ordered_types) do
    y += 1
    for rot = 1, 4 do
      local pipe = new_pipe(
        type,
        rot,
        y,
        rot,
        1
      )
      local rotdirs = { 1, 3, 2, 4 }

      pipe:add_flow(rotdirs[rot], 1)

      add_pipe(pipe)
    end
  end
end

function _init()
  curr_ppal = rnd(ppal)
  --ppal[rnd({"red", "green", "blue"})]
  pal(curr_ppal)
end
function _draw()
  rectfill(0, 0, 128, 128, 7)

  for loc, pipe in pairs(pipes) do
    pipe:draw()
  end
end

function _update()
  if btnp(5) then pal(rnd(ppal)) end

  for loc, pipe in pairs(pipes) do
    if pipe:update() then
      -- pipe overflowed, start flow in neighbours
      for n in all(pipe:neighbors()) do
        local nloc, dir, col = n[1], n[2], n[3]
        if pipes[nloc] != nil then
          -- add_flow should fail...
          pipes[nloc]:add_flow(dir, col)
        end
      end
    end
  end
end
