pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- todo
-- [ ] fix directions / turning
-- [ ] do collision detection on player and world
-- [ ] allow player to pickup stack of cubes
-- [ ] allow player to drop on top of other stacks...

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
  flags = 1,
  mov = mov_walk
}

bump = nil
t = 0
f = 0
dir = 0
ld = 1
debug = {}

function log(_text)
  if #debug > 2 then
    local v = debug[1]
    del(debug, v)
  end

  add(debug,_text)
end

-- comparison by distance to camera
function comp_screen_dist(a, b)
  ad = a.x + a.ox/4 - a.y - a.oy/4
  bd = b.x + b.ox/4 - b.y - b.oy/4
  if ad == bd then
    return a.z < b.z
  else
    return ad < bd
  end
end

function _init()
  -- btn(l,r,u,d)
  dirx = { -1, 1, 0, 0 }
  diry = { 0, 0, 1, -1 }

  for i = 0, 8, 1 do
    for j = 0, 8, 1 do
      if 1 > rnd(5) and (i != 4 or j != 4) then
        col = ceil(rnd(3)) --(i + j)%6
        sss = rnd(5) < 1
        for z = 0, flr(rnd(3)) do
          add(
            cubes, {
              id = i + j * 8 + z * 64,
              x = i * 2 - 8,
              y = j * 2 - 8,
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

  qsort(cubes, comp_screen_dist)
  x = 'no'
  _upd_player = update_player
end

function mov_walk()
  potter.ox = potter.sox * (1 - potter.pt)
  potter.oy = potter.soy * (1 - potter.pt)
end

function mov_bump()
  local pt = potter.pt
  if (pt >= 0.5) then
    pt = 1-pt
  end
  potter.ox = potter.sox*pt
  potter.oy = potter.soy*pt
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
    potter.sox, potter.soy = dx*3, dy*3
    potter.ox, potter.oy = 0, 0
    potter.pt = 0

    potter.mov = mov_bump
  else
    -- walk
    potter.x += dx
    potter.y += dy
    potter.sox, potter.soy = -dx*4, -dy*4
    potter.ox, potter.oy = potter.sox, potter.soy
    potter.pt = 0

    potter.mov = mov_walk
  end
  _upd_player = update_pturn
end

function update_player()
  for i = 0, 3 do
    if btnp(i) then
      local dx, dy = dirx[i + 1], diry[i + 1]
      move_player(dx, dy)
      return
    end
  end
end

function _update60()
  _upd_player()
  if btnp(4) then
    rotateZ(1)
  end
  if btnp(5) then
    rotateZ(-1)
  end
end

function rotateZ(d)
  ld = d
  if dir % 2 == 0 then
    if d == 1 then
      for cube in all(cubes) do
        local x, y = cube.y, -cube.x
        cube.x, cube.y = x, y
      end
      local x = potter.y
      local y = -potter.x
      potter.x = x
      potter.y = y
    elseif d == -1 then
      local x = -potter.y
      local y = potter.x
      potter.x = x
      potter.y = y
      for cube in all(cubes) do
        local x = -cube.y
        local y = cube.x
        cube.x = x
        cube.y = y
      end
    end
  end
  dir = (dir + d) % 2

  qsort(cubes, comp_screen_dist)
end

function v2D(x, y, z)
  local p = {}
  if dir % 2 == 0 then
    p.x = 64 + (x + y) * 4
    p.y = 64 + (x - z - y) * 3
  elseif ld == 1 then
    p.x = 64 + x * 6
    p.y = 64 - z * 3 - y * 4
  else
    p.x = 64 + y * 6
    p.y = 64 - z * 3 + x * 4
  end
  return p
end

function draw_cube(cube)
  local c2D = v2D(cube.x, cube.y, cube.z)
  local sp = cube.c
  if dir % 2 != 0 then
    sp += 32
  end
  spr(sp, c2D.x, c2D.y)

  if cube.sel then
    local sel_ani = { 38, 39, 40, 41 }
    spr(getframe(sel_ani), c2D.x, c2D.y)
  end
end

function draw_potter()
  local pp = v2D(potter.x + potter.ox / 4, potter.y + potter.oy / 4, potter.z)
  local y = pp.y - 2
  if dir % 2 != 0 then
    y += 1
  end
  spr(16, pp.x, y)
end

function _draw()
  t += 1
  f = flr(t / 2.5)
  rectfill(0, 0, 127, 127, 1)
  rectfill(1, 1, 126, 126, 0)
  pd = false
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
  for p, d in pairs(debug) do
    print(p, 0, 30 + p * 10, 9)
    print(d, 30, 30 + p * 10, 9)
  end
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

function getframe(ani)
  return ani[flr(t / 2.5) % #ani + 1]
end

-->8
-- sort

-- common comparators
function ascending(a, b) return a < b end
function descending(a, b) return a > b end

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

__gfx__
00000000000dd000000ee000000330000009900000066000000aa000000000000000a00000000000000000000000000000000000000000000000000000000000
000000000dddddd00eeeeee00333333009999990066666600aa00aa000a00a000a00000000000000000000000000000000000000000000000000000000000000
00000000ddddddddeeeeeeee333333339999999966666666a000000a0000000a0000000a00000000000000000000000000000000000000000000000000000000
000000001ddddddc2eeeeee85333333b4999999a56666667a000000aa0000000a000000000000000000000000000000000000000000000000000000000000000
00000000111ddccc222ee88855533bbb44499aaa55566777a000000a000000000000000066000000000000000000000000000000000000000000000000000000
000000001111cccc222288885555bbbb4444aaaa55557777a000000a0000000a0000000a66600000000000000000000000000000000000000000000000000000
000000000111ccc0022288800555bbb00444aaa0055577700aa00aa00a0000000a00000066700000000000000000000000000000000000000000000000000000
000000000001c000000280000005b0000004a00000057000000aa0000000a0000000a00057760000000000000055550000000000000000000000000000000000
000000000000000000000000000000000000000000000000000a0000000aa000000aa0000000a000000000005559955500000000000000000000000000000000
0004400000040000044000000004000000c40c00000000000aa00aa000a000a00a000a000aa00aa0000000055999999550000000000000000000000000000000
0079970000797000049700000044400000c97c00000000000000000aa000000aa000000aa0000000000000059999999950000000000000000000000000000000
0044440000444000049400000044400000c94c0000000000a0000000a000000aa000000a0000000a000000054999999a50000000000000000000000000000000
0c5445c00c545c0004c4c0000c545c0000cc400000000000a000000aa00000000000000aa000000a0000000544499aaa50000000000000000000000000000000
0c5555c00c555c0000c500000c555c00000cc00000000000a000000a0000000aa0000000a000000a000000054444aaaa50000000000000000000000000000000
00555500005550000055000000555000000550000000000000a000a00aa00aa00aa00aa00a000a00000000055444aaa550000000000000000000000000000000
005005000050500000505000005050000005050000000000000aa000000a00000000a000000aa000000000005554a55500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000a0000000aa0000000a000000000000055550000000000000000000000000000000000
0000000001111110022222200555555004444440055555500aa00aa000a000a0000000000a000a00000000000000000000000000000000000000000000000000
000000000111111002222220055555500444444005555550000000000000000aa000000aa0000000000000000000000000000000000000000000000000000000
00000000011111100222222005555550044444400555555000000000a0000000a000000a0000000a000000000000000000000000000000000000000000000000
0000000001d1d1d002e2e2e0035353500949494006565650a000000aa0000000000000000000000a000000000000000000000000000000000000000000000000
000000000dcdcdc00e8e8e800b3b3b300a9a9a9007676760a000000a0000000a00000000a0000000000000000000000000000000000000000000000000000000
000000000cccccc0088888800bbbbbb00aaaaaa0077777700000000000a000a00aa00aa00a000a00000000000000000000000000000000000000000000000000
000000000cccccc0088888800bbbbbb00aaaaaa007777770000aa000000a0000000000000000a000000000000000000000000000000000000000000000000000
000000000000000000444000000ee000000330000009900000000000000000000000055557777000000000000000000000000000000000000000000000000000
0004400000444000004797000eeeeee0033333300999999000000000000000000000005557700000000000000000000000000000000000000000000000000000
007997000047970000444400eeeeeeee333333339999999900000000000000000000000057000000000000000000000000000000000000000000000000000000
004444000044440000c44dc02eeeeee85333333b4999999a00000000000000000000000000000000000000000000000000000000000000000000000000000000
0cd44dc000c44dc000cdddc0222ee88855533bbb44499aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000
0cddddc000cdddc0000dddd0222288885555bbbb4444aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd00000ddd00000d00d0022288800555bbb00444aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d00d00000d0d00000d0000000280000005b0000004a00000000000000000000000000000000000000000000000000000000000000000000000000000000000
