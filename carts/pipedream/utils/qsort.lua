
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
