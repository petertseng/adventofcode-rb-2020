# Take advantage of symmetry in the non-XY dimensions:
# All dimensions are interchangeable so can be reordered,
# and the starting state has no components in non-XY, so coordinates can be negated.
def step(now_active, dimensions, weights, ybits, wzbits)
  # (neighbour count << 1) | self
  neigh_and_self = Hash.new(0)
  wzshift = wzbits * (dimensions - 2)
  wzmask = (1 << wzshift) - 1
  pos_per_dy = 1 << wzshift
  pos_per_dx = pos_per_dy << ybits
  dxys = [0, -1, 1].repeated_permutation(2).map { |dx, dy|
    dx * pos_per_dx + dy * pos_per_dy
  }.freeze

  now_active.each { |pos|
    weights[pos & wzmask].each { |nwz, weight|
      npos = pos & ~wzmask | nwz
      dxys.each { |dxy|
        neigh_and_self[npos + dxy] += weight << 1
      }
    }
    # for e.g. [x, y, z, w] -> [x + 1, y, z, w]
    # NOTE that if a cell is a representative of one of its own neighbours,
    # e.g, [x, y, 0, 1] -> [x, y, 1, 0] (which is represented by [x, y, 0, 1]),
    # the above weights will already have included that fact.
    # This is only for the single extra neighbour for nonequal [x, y].
    dxys[1..].each { |dxy|
      neigh_and_self[pos + dxy] += 1 << 1
    }
    neigh_and_self[pos] += 1
  }

  neigh_and_self.filter_map { |pos, count|
    # alive if:
    # 101 (2 neigh + self) 5
    # 110 (3 neigh)        6
    # 111 (3 neigh + self) 7
    pos if 5 <= count && count <= 7
  }
end

# Pack the entire coordinate vector into a single int.
def compress(x, y, wz, xyoffset, wzoffset, ybits, wzbits)
  # Ah, unfortunately | won't work with negative arguments (as passed in by neigh)
  # Add instead.
  wz.reduce(((x + xyoffset) << ybits) + y + xyoffset) { |a, coord| (a << wzbits) + coord + wzoffset }
end

def decompress(pos, dimensions, xyoffset, wzoffset, ybits, wzbits)
  wz = pos.digits(1 << wzbits)[0, dimensions - 2].reverse
  xy = pos >> (wzbits * (dimensions - 2))
  y = xy & ((1 << ybits) - 1)
  x = xy >> ybits
  [x - xyoffset, y - xyoffset] + wz.map { |c| c - wzoffset }
end

# Precomputing this is the part that takes most of the time.
# Speeding this up would help.
# An implementation has sped this up by considering counts of 0..6,
# rather than 3**n -1..1.
# https://www.reddit.com/r/adventofcode/comments/kfb6zx/day_17_getting_to_t6_at_for_higher_spoilerss/ggsx9e9
def neigh_weights(dimensions, rounds, wzbits)
  ds = [0, -1, 1].repeated_permutation(dimensions - 2).to_a
  ds.shift
  return Hash.new([].freeze).freeze if dimensions <= 2

  weights = Hash.new { |h, k| h[k] = Hash.new(0) }

  prefix = Array.new(dimensions - 2)
  # rule: May only mutate at index n and above.
  build_if_representative = ->n {
    if n == dimensions - 2
      neigh_weights_for(prefix, ds, rounds, wzbits, weights)
    else
      (prefix[n - 1]..rounds).each { |x|
        prefix[n] = x
        build_if_representative[n + 1]
      }
    end
  }
  (0..rounds).each { |x|
    prefix[0] = x
    build_if_representative[1]
  }

  weights.transform_values { |h| h.to_a.map(&:freeze).freeze }.freeze
end

def neigh_weights_for(pt, ds, rounds, wzbits, h)
  raise "non-representative #{pt}" unless representative?(pt)
  # Use a zero xyoffset since this weight map doesn't have xy component.
  comp_pt = compress(0, 0, pt, 0, 1, 0, wzbits)
  ds.each { |d|
    # We do need to calculate the representative,
    # so either we can pass in the dpos and decompress in here,
    # or we can pass in the full dcoords and compress in here.
    npt = pt.zip(d).map(&:sum)
    # points with any coordinate equal to # rounds only appear in the last iteration,
    # so we don't need to compute their outgoing neighbours
    next if npt.any? { |n| n.abs >= rounds }
    # Use a zero xyoffset since this weight map doesn't have xy component.
    comp_neigh_rep = compress(0, 0, representative(npt), 0, 1, 0, wzbits)
    h[comp_neigh_rep][comp_pt] += 1
  }
end

def representative(pt)
  pt.map(&:abs).sort
end

def representative?(pt)
  pt[0] >= 0 && pt.each_cons(2).all? { |a, b| a <= b }
end

def test_neigh_weights(dim)
  dc = ->pt { decompress(pt, dim, 0, 1, 0, 4)[2..] }
  weights = neigh_weights(dim, 6, 4)
  puts weights.size
  weights.each { |pt, neighs|
    neighs.each { |neigh, w|
      puts "#{pt} #{dc[pt]} -> #{neigh} #{dc[neigh]}: #{w}"
    }
    puts
  }
  puts weights.size
end

#test_neigh_weights(3)
#exit 0

def size(compressed, dimensions, wzbits)
  perms_wz = fact(dimensions - 2)
  compressed.sum { |pos|
    wz = pos.digits(1 << wzbits)[0, dimensions - 2]
    perms_pos = wz.tally.map { |_, v| fact(v) }.reduce(1, :*)
    # Since we're only storing non-negative wz,
    # points count double for each non-zero wz coordinate they have.
    # remember wz coordinates are offset by 1, so compare to 1.
    2 ** wz.count { |c| c != 1 } * perms_wz / perms_pos
  }
end

def fact(n)
  (1..n).reduce(1, :*)
end

def print_grids(poses, dimensions, rounds, ybits, wzbits)
  coords = poses.map { |pos| decompress(pos, dimensions, rounds, 1, ybits, wzbits) }.freeze

  chr = poses.to_h { |pos| [pos, ?#.freeze] }
  chr.default = ?..freeze
  chr.freeze

  ranges = coords.transpose.map { |lim| Range.new(*lim.minmax).to_a }

  (ranges[2] || [0]).product(*ranges[3..]) { |high_dims|
    next if high_dims.each_cons(2).any? { |a, b| a > b }
    p high_dims
    ranges[1].each { |y|
      ranges[0].each { |x|
        coord = compress(x, y, dimensions > 2 ? high_dims : [], rounds, 1, ybits, wzbits)
        print chr[coord]
      }
      puts
    }
    puts
  }
  puts
end

verbose = if ARGV.delete('-vv')
  2
elsif ARGV.delete('-v')
  1
else
  0
end
rounds = if (arg = ARGV.find { |a| a.start_with?('-t') })
  ARGV.delete(arg)
  Integer(arg[2..])
else
  6
end
dims = if (arg = ARGV.find { |a| a.start_with?('-d') })
  ARGV.delete(arg)
  [Integer(arg[2..])].freeze
else
  [3, 4].freeze
end

height = 0
init_active = []
ARGF.each_with_index { |row, y|
  row.chomp.each_char.with_index { |c, x|
    if c == ?#
      # Contrary to usual, I have decided to go x, y here.
      # That makes an [x, y, z] ordering look better.
      # I don't know why [x, y, z, w] has w at the end though.
      init_active << [x, y].freeze
    elsif c != ?.
      raise "bad char #{c} at #{y} #{x} in #{row}"
    end
  }
  height += 1
}
# because of only storing non-negatives,
# w and z only span 0..rounds, which is rounds + 1 values.
# However, we'll offset them by 1 so we can detect zeroes
wzbits = (rounds + 2).bit_length
# y, on the other hand, stores both positives and negatives,
# can be -rounds to rounds, which is 2 * rounds + 1 values.
ybits = (height + 2 * rounds + 1).bit_length
init_active.freeze
puts "ybits #{ybits} wzbits #{wzbits}" if verbose > 0

dims.each { |dim|
  t = Time.now
  weights = neigh_weights(dim, rounds, wzbits)
  puts "neigh weights took #{Time.now - t}" if verbose > 0 || dim > 4
  zs = [0] * (dim - 2)
  active = init_active.map { |pos| compress(*pos, zs, rounds, 1, ybits, wzbits) }

  rounds.times { |t|
    active = step(active, dim, weights, ybits, wzbits).freeze
    if verbose > 0
      puts "t=#{t + 1} pop=#{size(active, dim, wzbits)}"
      print_grids(active, dim, rounds, ybits, wzbits) if verbose > 1
    end
  }
  puts size(active, dim, wzbits)
}
