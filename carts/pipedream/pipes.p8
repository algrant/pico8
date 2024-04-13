pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- btn(l,r,u,d)
-- types
--  lrudlrud bitmap, always favour first bits...
--  11000000 --> lr connection only
--  10100101 --> lu and rd connections
--
-- "lr", "lu", "ld", "ru", "rd", "ud", "lru", "lrd", ""
--

pipe_types = {
    lr = {
      sprs = {
        { 0, false, false },
        { 0, true, false },
        { 0, false, true },
        { 0, true, true }
      }
    },
    ud = {
      sprs = {
        { 1, false, false },
        { 1, true, false },
        { 1, false, true },
        { 1, true, true }
      }
    },
    lru = {
      sprs = {
        { 2, false, false },
        { 2, true, false },
        { 0, false, true },
        { 0, true, true }
      }
    }
}

pipe = {
  new = function()
    return {
      type = pipe_types.lr
    }
  end
}

function _draw()
  rectfill(0,0,128,128,3)
  local x,y = -1,1
  for _, type in pairs(pipe_types) do
    x += 2
    for i,s in ipairs(type.sprs) do
      local sx, sy = (i-1)%2, flr((i-1)/2)
      spr(s[1] + 128, (x + sx)*8, (y + sy)*8, 1, 1, s[2], s[3])
      printh(ins({s[1] + 128, x + sx, y + sy, 1, 1, s[2], s[3]}), "log")
    end
  end


end