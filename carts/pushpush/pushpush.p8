pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- todo

-- [ ] select stack of blocks
-- [ ] shove entire stack of blocks
-- [ ] shove all connected blocks of same colour

-- [ ] drop blocks off edge
-- [ ] drop player off edge

-- [ ] allow player to pickup stack of cubes
-- [ ] allow player to drop on top of other stacks...

-- fix underline / base

-- log
-- 24/04/07
-- [x] better colours
--     new palette!
-- [x] better sprites -- 2 colours per cube vs 3
-- [x] add camera rotation anim // do in between math...
--     basically added in 8 more camera angles to smooth out in betweens
--     i'm tempted to make these more "midular" as it feels weirdly weighted currently...
--     otoh - jank is jank and looks ok


-- 24/04/04
-- [x] fix camera rotation

-- 24/04/03
-- [x] do collision detection on player and cubes


-->8
-- main
cubes = {}
potter = {
  x = 0,
  y = 0,
  z = 0,
  sox = 0,
  soy = 0,
  ox = 0,
  oy = 0,
  pt = 0,
  c = 10, -- for the sake of order
  flags = 1,
  mov = mov_walk,
  sel = {}
}

t = 0
f = 0
dir = 0
ld = 1

world = {
  ux = 6,
  uy = 3,
  uz = 6
}

function init_rnd_cubes()
  for i = -4, 4, 1 do
    for j = -4, 4, 1 do
      if 1 > rnd(4) and (i != 4 or j != 4) then
        col = flr(rnd(4))
        --(i + j)%6
        sss = false
        --rnd(5) < 1
        for z = 0, flr(rnd(5)) do
          add(
            cubes, {
              id = i + j * 8 + z * 64,
              x = i,
              y = j,
              z = z,
              c = col,
              sel = sss,
              ox = 0,
              oy = 0,
              sox = 0,
              soy = 0,
              flags = 1
            }
          )
        end
      end
    end
  end
end

function _init()
  -- btn(l,r,u,d)
  dirx = { -1, 1, 0, 0 }
  diry = { 0, 0, 1, -1 }
  init_rnd_cubes()

  qsort(cubes, comp_screen_dist)
  _upd_player = update_player
end

function mov_walk()
  potter.ox = potter.sox * (1 - potter.pt)
  potter.oy = potter.soy * (1 - potter.pt)
end

function mov_bump()
  local pt = potter.pt
  if pt >= 0.5 then
    pt = 1 - pt
  end
  potter.ox = potter.sox * pt
  potter.oy = potter.soy * pt
end

function update_pturn()
  potter.pt = min(potter.pt + 0.2, 1)

  potter.mov()

  if potter.pt == 1 then
    _upd_player = update_player
  end
end

function move_player(dx, dy)
  local nx, ny = potter.x + dx, potter.y + dy
  local cube
  for c in all(cubes) do
    if c.x == nx and c.y == ny then
      cube = c
      break
    end
  end

  if cube then
    -- bump
    potter.sox, potter.soy = dx * 3, dy * 3
    potter.ox, potter.oy = 0, 0
    potter.pt = 0
    if cube.sel then
      cube.x += dx
      cube.y += dy
      qsort(cubes, comp_screen_dist)
    end
    cube.sel = not cube.sel

    potter.mov = mov_bump
  else
    -- walk
    potter.x += dx
    potter.y += dy
    potter.sox, potter.soy = -dx * 4, -dy * 4
    potter.ox, potter.oy = potter.sox, potter.soy
    potter.pt = 0

    potter.mov = mov_walk
  end
  _upd_player = update_pturn
end

function update_player()
  for i = 0, 3 do
    if btnp(i) then
      local dx, dy = camera_xy(dirx[i + 1], diry[i + 1])
      -- flip controls when viewing from some directions (manual test)
      if (dir + 2) % 8 > 3 then
        dx = -dx
        dy = -dy
      end
      move_player(dx, dy)
      return
    end
  end
end

function _update60()
  _upd_player()
  if btnp(4) then
    rotate_z(1)
  end
  if btnp(5) then
    rotate_z(-1)
  end
end

--dirs
-- ortho 0, 2, 4, 6
--    z
--    |     cy
--    |  -
--     -
--       -
--          cx

function rotate_z(d)
  -- in theory we have 15 directions now...
  dir = (dir + 1*d) % 16
  qsort(cubes, comp_screen_dist)
  log({dir, flr((dir + 2) / 4) % 4})
end

function camera_xy(_x, _y)
  local dirss = { _x, _y, -_x, -_y, _x }
  -- only works when dir is 0,2,4,6 -- haven't implemented any tweening yet...
  local idx = flr((dir + 2) / 4) % 4
  return dirss[idx + 1], dirss[idx + 2]
end

function camera_dist_xy(a)
  local au, av = camera_xy(a.x + a.ox / 4, a.y + a.oy / 4)
  return au - av
end

-- comparison by distance to camera
function comp_screen_dist(a, b)
  local ad, bd = camera_dist_xy(a), camera_dist_xy(b)

  if ad == bd then
    if a.z == b.z then
      return a.c < b.c
    end
    return a.z < b.z
  else
    return ad < bd
  end
end

-- {spr, xx, yx, xy, yy, zy, flip}
render_params = {
  [0] = { 192,  6, 6, 3, -3, -6, false },
        { 196, 3, 8, 3, -2, -6, false }, --1
        { 198, 9, 0, 0, -4, -6, false }, --2
        { 196, 8, 3, 2, -3, -6, true },  --3
        { 192,  6, 6, 3, -3, -6, true }, --4
        { 194, 3, 8, 3, -2, -6, true },  --5
        { 200, 9, 0, 0, -4, -6, true },  --6
        { 194, 8, 3, 2, -3, -6, false }  --7
}

function v2d(x, y, z)
  local p = {}
  local rp = render_params[(dir % 4)]
  local cx, cy = camera_xy(x, y)

  return {
    x = 64 - 9 + rp[2] * cx + rp[3] * cy,
    y = 64+rp[4] * cx + rp[5] * cy + rp[6] * z
  }
end

-- get rid of nasty pink and add in pretty blue
pal({ [15] = 140 }, 1)
-- cube palettes
cpals = {
  [0] = { [5] = 5, [6] = 6, [7] = 7 }, -- original
  { [5] = 14, [6] = 8, [7] = 2 }, -- red
  { [5] = 4, [6] = 10, [7] = 9 }, -- yellow
  { [5] = 5, [6] = 11, [7] = 3 }, -- green
  { [5] = 5, [6] = 12, [7] = 15 } -- blue
}

function draw_cube(cube)
  local c2D = v2d(cube.x, cube.y, cube.z)
  local rp = render_params[dir % 8]
  local sid = rp[1]
  if not cube.sel then
    --   if cube.sel and flr(t/3)%2 == 0 then
    pal(cpals[cube.c + 1])
  end
  spr(sid, c2D.x, c2D.y, 2, 2, rp[7])

  pal(cpals[0])

  -- underline base
  if cube.z == 0 then
    spr(64, c2D.x - 1, c2D.y, 2, 2)
  end
end

function draw_potter()
  local pp = v2d(potter.x + potter.ox / 4, potter.y + potter.oy / 4, potter.z)
  local y = pp.y + 1

  if dir % 2 != 0 then
    y -= 2
  end
  spr(16, pp.x + 2, y)
end

function draw_board()
  for i = -4, 4 do
    for j = -4, 4 do
      local c2d = v2d(i, j, -1)
      spr(68 + 2 * ((flr(i / 2) + flr(j / 2)) % 2), c2d.x, c2d.y, 2, 2)
    end
  end
end

function _draw()
  t += 1
  f = flr(t / 2.5)
  rectfill(0, 0, 127, 127, 1)
  rectfill(1, 1, 126, 126, 0)
  local pd = false

  draw_board()

  for cube in all(cubes) do
    if not pd and comp_screen_dist(potter, cube) then
      draw_potter()
      pd = true
    end
    draw_cube(cube)
  end
  if not pd then draw_potter() end
  print(potter.x, 0, 0, 9)
  print(potter.y, 10, 0, 9)
  print(potter.ox, 25, 0, 9)
  print(potter.oy, 35, 0, 9)
  draw_debug()
end

-->8
-- updates

function update_start()
end

function update_game()
end

function update_gameover()
end
-->8
-- draws

-->8
-- tools

-- given ani as a table of spr indices, return the "current" one based on frame & time
function getframe(ani)
  return ani[flr(t / 2.5) % #ani + 1]
end

debug = {}
debug_count = 1

function log(_text)
  debug_count += 1
  if #debug > 2 then
    local v = debug[1]
    del(debug, v)
  end

  add(debug, ins(_text))
end

function draw_debug()
  for _count, _text in pairs(debug) do
    print(debug_count - 2 + _count, 0, 80 + _count * 10, 8)
    print(_text, 25, 80 + _count * 10, 9)
  end
end

-->8
-- sort

-- common comparators
function ascending(a, b)
  return a < b
end
function descending(a, b)
  return a > b
end

-- a: array to be sorted in-place
-- c: comparator (optional, defaults to ascending)
-- l: first index to be sorted (optional, defaults to 1)
-- r: last index to be sorted (optional, defaults to #a)
function qsort(a, c, l, r)
  c, l, r = c or ascending, l or 1, r or #a
  if l < r then
    if c(a[r], a[l]) then
      a[l], a[r] = a[r], a[l]
    end
    local lp, rp, k, p, q = l + 1, r - 1, l + 1, a[l], a[r]
    while k <= rp do
      if c(a[k], p) then
        a[k], a[lp] = a[lp], a[k]
        lp += 1
      elseif not c(a[k], q) then
        while c(q, a[rp]) and k < rp do
          rp -= 1
        end
        a[k], a[rp] = a[rp], a[k]
        rp -= 1
        if c(a[k], p) then
          a[k], a[lp] = a[lp], a[k]
          lp += 1
        end
      end
      k += 1
    end
    lp -= 1
    rp += 1
    a[l], a[lp] = a[lp], a[l]
    a[r], a[rp] = a[rp], a[r]
    qsort(a, c, l, lp - 1)
    qsort(a, c, lp + 1, rp - 1)
    qsort(a, c, rp + 1, r)
  end
end

-->8
-- inspect
do
  -- commented out qsort as I have it defined globally...
  -- could be that this implementation is better/worse in some way? so much smaller...
  -- local function qsort(t, f, l, r)
  --   if r - l < 1 then return end
  --   local p = l
  --   for i = l + 1, r do
  --     if f(t[i], t[p]) then
  --       if i == p + 1 then
  --         t[p], t[p + 1] = t[p + 1], t[p]
  --       else
  --         t[p], t[p + 1], t[i] = t[i], t[p], t[p + 1]
  --       end
  --       p = p + 1
  --     end
  --   end
  --   qsort(t, f, l, p - 1)
  --   qsort(t, f, p + 1, r)
  -- end

  local typew = {
    number = 1, boolean = 2, string = 3,
    table = 4, ['function'] = 5,
    userdata = 6, thread = 7
  }

  local function cmpkey(a, b)
    local ta, tb = type(a), type(b)
    if ta == tb
        and (ta == 'string' or ta == 'number') then
      return a < b
    end
    local wa, wb = typew[ta] or 32767, typew[tb] or 32767
    return wa == wb
        and ta < tb or wa < wb
  end

  local function getkeys(_t)
    local slen = 0
    while _t[slen + 1] ~= nil do
      slen = slen + 1
    end

    local keys, klen = {}, 0
    for k, _ in next, _t do
      klen = klen + 1
      keys[klen] = k
    end
    qsort(keys, cmpkey, 1, klen)
    return keys, slen, klen
  end

  local function countref(x, ref)
    if type(x) ~= 'table' then
      return
    end
    ref[x] = (ref[x] or 0) + 1
    if ref[x] == 1 then
      for k, v in next, x do
        countref(k, ref)
        countref(v, ref)
      end
      countref(getmetatable(x), ref)
    end
  end

  local function getid(x, ids)
    local id = ids[x]
    if not id then
      local _t = type(x)
      id = (ids[_t] or 0) + 1
      ids[_t], ids[x] = id, id
    end
    return id
  end

  local typesn = {
    table = "t",
    ["function"] = "f",
    thread = "th",
    userdata = "ud"
  }

  local function isident(x)
    if type(x) ~= "string"
        or x == "" then
      return false
    end
    for i = 1, #x do
      local c = ord(x, i)
      if (i == 1 or c < 48 or c > 57)
          --0-9
          and (c < 65 or c > 90)
          --lc a-z
          and (c < 97 or c > 122)
          --uc a-z
          and c ~= 95 then
        -- _
        return false
      end
    end
    return true
  end

  local function tab(lvl)
    local s = "\n"
    for _ = 1, lvl do
      s = s .. " "
    end
    return s
  end

  local function x2s(x, d, lvl, ids, ref)
    local tx = type(x)

    if tx == 'string' then
      return '"' .. x .. '"'
    end

    if tx == 'number' or tx == 'nil'
        or tx == 'boolean' then
      return tostr(x)
    end

    if tx == 'table'
        and not ids[x] then
      if lvl >= d then
        return '{_}'
      end

      local s = ""
      if ref[x] > 1 then
        s = s .. '<' .. getid(x, ids) .. '>'
      end
      s = s .. '{'

      local ks, slen, klen = getkeys(x)

      for i = 1, klen do
        if i > 1 then
          s = s .. ','
        end
        if i <= slen then
          s = s
              .. x2s(x[i], d, lvl + 1, ids, ref)
        else
          local k = ks[i]
          s = s .. tab(lvl + 1)
              .. (isident(k) and k
                or "["
                .. x2s(k, d, lvl + 1, ids, ref)
                .. "]")
              .. "="
              .. x2s(x[k], d, lvl + 1, ids, ref)
        end
      end

      local mt = getmetatable(x)
      if type(mt) == 'table' then
        if klen > 0 then
          s = s .. ','
        end
        s = s .. tab(lvl + 1) .. '<mt>='
            .. x2s(mt, d, lvl + 1, ids, ref)
      end

      if klen > slen
          or type(mt) == 'table' then
        s = s .. tab(lvl)
        -- last }
      end

      return s .. '}'
    end

    -- function, userdata, thread,
    -- or previously visited table
    return '<'
        .. (typesn[tx] or tx)
        .. getid(x, ids)
        .. '>'
  end

  ins = function(root, depth)
    depth = depth or 32767

    local ref = {}
    countref(root, ref)
    return x2s(
      root, depth,
      0, {}, ref
    )
  end
end

__gfx__
00000000000dd000000ee000000330000009900000066000000aa000000000000000a00000000000000000000000000000000000000000000000000000000000
000000000dddddd00eeeeee00333333009999990066666600aa00aa000a00a000a00000000000000088888800000000009999990000000000333333000000000
00000000ddddddddeeeeeeee333333339999999966666666a000000a0000000a0000000a00000000088888800000000009999990000000000333333000000000
000000001ddddddc2eeeeee85333333b4999999a56666667a000000aa0000000a000000000000000088888800000000009999990000000000333333000000000
00000000111ddccc222ee88855533bbb44499aaa55566777a000000a000000000000000066000000085858500000000009595950000000000353535000000000
000000001111cccc222288885555bbbb4444aaaa55557777a000000a0000000a0000000a6660000005e5e5e00000000005a5a5a00000000005b5b5b000000000
000000000111ccc0022288800555bbb00444aaa0055577700aa00aa00a0000000a000000667000000eeeeee0000000000aaaaaa0000000000bbbbbb000000000
000000000001c000000280000005b0000004a00000057000000aa0000000a0000000a000577600000eeeeee0000000000aaaaaa0000000000bbbbbb000000000
000000000000000000000000000000000000000000000000000a0000000aa000000aa0000000a000000000000000000000000000000000000000000000000000
0004400000040000044000000004000000c40c00000000000aa00aa000a000a00a000a000aa00aa0000000000000000000000000000000000000000000000000
0079970000797000049700000044400000c97c00000000000000000aa000000aa000000aa0000000000000000000000000000000000000000000000000000000
0044440000444000049400000044400000c94c0000000000a0000000a000000aa000000a0000000a000000000000000000000000000000000000000000000000
0c5445c00c545c0004c4c0000c545c0000cc400000000000a000000aa00000000000000aa000000a000000000000000000000000000000000000000000000000
0c5555c00c555c0000c500000c555c00000cc00000000000a000000a0000000aa0000000a000000a000000000000000000000000000000000000000000000000
00555500005550000055000000555000000550000000000000a000a00aa00aa00aa00aa00a000a00000000000000000000000000000000000000000000000000
005005000050500000505000005050000005050000000000000aa000000a00000000a000000aa000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000a0000000aa0000000a000000088880000000000009999000000000000333300000000
0000000001111110022222200555555004444440055555500aa00aa000a000a0000000000a000a00008888888800000000999999990000000033333333000000
000000000111111002222220055555500444444005555550000000000000000aa000000aa0000000888888888888000099999999999900003333333333330000
00000000011111100222222005555550044444400555555000000000a0000000a000000a0000000a2288888888ee00004499999999aa00005533333333bb0000
0000000001d1d1d002e2e2e0035353500949494006565650a000000aa0000000000000000000000a22228888eeee000044449999aaaa000055553333bbbb0000
000000000dcdcdc00e8e8e800b3b3b300a9a9a9007676760a000000a0000000a00000000a0000000222222eeeeee0000444444aaaaaa0000555555bbbbbb0000
000000000cccccc0088888800bbbbbb00aaaaaa0077777700000000000a000a00aa00aa00a000a00222222eeeeee0000444444aaaaaa0000555555bbbbbb0000
000000000cccccc0088888800bbbbbb00aaaaaa007777770000aa000000a0000000000000000a000222222eeeeee0000444444aaaaaa0000555555bbbbbb0000
00000000000000000044400000000000000000000000000000000000000000000000000000000000222222eeeeee0000444444aaaaaa0000555555bbbbbb0000
00044000004440000047970000eeee00009999000033330000000000000000000000000000000000002222eeee000000004444aaaa000000005555bbbb000000
007997000047970000444400eeeeeeee999999993333333300000000000000000000000000000000000022ee00000000000044aa00000000000055bb00000000
004444000044440000c44dc055eeee88559999aa553333bb00000000000000000000000000000000000000000000000000000000000000000000000000000000
0cd44dc000c44dc000cdddc0555588885555aaaa5555bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
0cddddc000cdddc0000dddd0555588885555aaaa5555bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd00000ddd00000d00d0555588885555aaaa5555bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
00d00d00000d0d00000d0000005588000055aa000055bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000566500000000000011110000000000003131000000000000000000000000000066660000000000666660000000000666666666600000
00000000000000000056111165000000001111111100000000531513530000000000000000000000006666666600000000666666666000000666666666600000
00000000000000005611111111650000111111111111000031313131313100000000000000000000666666666666000006666666667000000666666666600000
00000000000000006511111111560000111111111111000053151353151300000000000000000000556666666677000005555666667000000666666666600000
00000000000000000065111156000000001111111100000000313131310000000000000000000000555566667777000005555555577000000555555555500000
00000000000000000000655600000000000011110000000000005315000000000000000000000000555555777777000005555555577000000555555555500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000555555777777000005555555577000000555555555500000
60000000000006000000000000000000000000000000000000000000000000000000000000000000555555777777000005555555577000000555555555500000
60000000000006000000000000000000000000000000000000000000000000000000000000000000555555777777000005555555570000000555555555500000
06600000000660000000000000000000000000000000000000000000000000000000000000000000005555777700000000000555570000000555555555500000
00066000066000000000000000000000000000000000000000000000000000000000000000000000000055770000000000000000000000000555555555500000
00000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000000000000000
00000000000000666600000000006666000000000000666600000000000066660000000000000000000066666000000000000006666600000006666666660000
00000000000066666666000000666666660000000066666666000000006666666600000000000000000066666666600000066666666600000006666666660000
00000000006666666666660066666666666600006666666666660000666666666666000000000000000666666666700000066666666660000006666666660000
00000000007666666666770076666666667700007666666666770000766666666677000000000000000777666666700000076666677770000006666666660000
00000000006776666677770067766666777700006676666677770000677666667777000000000000000666777767700000067777777770000007777777770000
00000000007667767777670076677677776700007666767777770000766776777777000000000000000777666677700000076777777770000007777777770000
00000000006776677677770067766776777700006676667777770000677667777777000000000000000666777767700000067777777770000007777777770000
00000000007667767777770076677677777700007666767777770000766776777777000000000000000777666677700000076777777770000007777777770000
00000000006776677677770067766777777700006676667777770000677667777777000000000000000666777767000000007777777770000007777777770000
00000000000067767777000000677676770000000066767777000000006776777700000000000000000000066677000000006777700000000007777777770000
00000000000000677700000000006777000000000000667700000000000067770000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00067676767600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077767776700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00067676767700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00076777676700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00067676777600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077767676700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066660000000000666660000000000000066666000000066666666600000006666666660000000000000000000000000000000000000000000000000000
00006666666600000000666666666000000666666666000000066666666600000006666666660000000000000000000000000000000000000000000000000000
00666666666666000006666666667000000666666666600000066666666600000006666666660000000000000000000000000000000000000000000000000000
00766666666677000007776666667000000766666777700000066666666600000006666666660000000000000000000000000000000000000000000000000000
00677666667777000006667777677000000677777776700000077777777700000006767676760000000000000000000000000000000000000000000000000000
00766776777767000007776666777000000767767777700000076777776700000007776777670000000000000000000000000000000000000000000000000000
00677667767777000006667777677000000677777777700000077777777700000006767676770000000000000000000000000000000000000000000000000000
00766776777777000007776666777000000767777777700000077777777700000007677767670000000000000000000000000000000000000000000000000000
00677667767777000006667777670000000077767777700000076777777700000006767677760000000000000000000000000000000000000000000000000000
00006776777700000000000666770000000067777000000000077777777700000007776767670000000000000000000000000000000000000000000000000000
00000067770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011110000000000111110000000000000011111000000011111111100000001111111110000000000000000000000000000000000000000000000000000
00001111111100000000111111111000000111111111000000011111111100000001111111110000000000000000000000000000000000000000000000000000
00111111111111000001111111110000000111111111100000011111111100000001111111110000000000000000000000000000000000000000000000000000
00011111111100000000001111110000000011111000000000011111111100000001111111110000000000000000000000000000000000000000000000000000
00000111110000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
