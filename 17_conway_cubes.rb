# Take advantage of symmetry in the non-XY dimensions,
# by only storing non-negative points in those dimensions.
# (offset by 1)
def step(now_active, dimensions, dposes, wzbits)
  # (neighbour count << 1) | self
  neigh_and_self = Hash.new(0)
  now_active.each { |pos|
    wz = pos.digits(1 << wzbits)[0, dimensions - 2]
    dposes.each { |dpos|
      npos = pos + dpos
      nwz = npos.digits(1 << wzbits)[0, dimensions - 2]
      next if nwz.any? { |c| c == 0 }
      # Since negative w and z aren't stored,
      # the points at w=1 and z=1 need to double-count toward neighbours at w=0 and z=0!
      # (offset by 1, so orig 2, neigh 1)
      neigh_and_self[npos] += 2 * 2 ** wz.zip(nwz).count { |origc, neighc|
        origc == 2 && neighc == 1
      }
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

def neigh(dimensions, ybits, wzbits)
  ds = [0, -1, 1].repeated_permutation(dimensions).to_a
  ds.shift
  # Zero offset for compression here, of course.
  # Otherwise we'd move by the offset amount in each direction.
  ds.map { |dx, dy, *dwz| compress(dx, dy, dwz, 0, 0, ybits, wzbits) }
end

def size(compressed, dimensions, wzbits)
  compressed.sum { |pos|
    wz = pos.digits(1 << wzbits)[0, dimensions - 2]
    # Since we're only storing non-negative wz,
    # points count double for each non-zero wz coordinate they have.
    # remember wz coordinates are offset by 1, so compare to 1.
    2 ** wz.count { |c| c != 1 }
  }
end

def print_grids(poses, dimensions, rounds, ybits, wzbits)
  coords = poses.map { |pos| decompress(pos, dimensions, rounds, 1, ybits, wzbits) }.freeze

  chr = poses.to_h { |pos| [pos, ?#.freeze] }
  chr.default = ?..freeze
  chr.freeze

  ranges = coords.transpose.map { |lim| Range.new(*lim.minmax).to_a }

  (ranges[2] || [0]).product(*ranges[3..]) { |high_dims|
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
  dposes = neigh(dim, ybits, wzbits).freeze
  puts "dpos #{dposes.size}: #{dposes}" if verbose > 0
  zs = [0] * (dim - 2)
  active = init_active.map { |pos| compress(*pos, zs, rounds, 1, ybits, wzbits) }

  rounds.times { |t|
    active = step(active, dim, dposes, wzbits).freeze
    if verbose > 0
      puts "t=#{t + 1} pop=#{size(active, dim, wzbits)}"
      print_grids(active, dim, rounds, ybits, wzbits) if verbose > 1
    end
  }
  puts size(active, dim, wzbits)
}
