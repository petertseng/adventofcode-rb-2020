def step(now_active, dposes)
  # (neighbour count << 1) | self
  neigh_and_self = Hash.new(0)
  now_active.each { |pos|
    dposes.each { |dpos|
      neigh_and_self[pos + dpos] += 2
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
def compress(x, y, wz, offset, ybits, wzbits)
  # Ah, unfortunately | won't work with negative arguments (as passed in by neigh)
  # Add instead.
  wz.reduce(((x + offset) << ybits) + y + offset) { |a, coord| (a << wzbits) + coord + offset  }
end

def decompress(pos, dimensions, offset, ybits, wzbits)
  wz = pos.digits(1 << wzbits)[0, dimensions - 2].reverse
  xy = pos >> (wzbits * (dimensions - 2))
  y = xy & ((1 << ybits) - 1)
  x = xy >> ybits
  ([x, y] + wz).map { |c| c - offset }
end

def neigh(dimensions, ybits, wzbits)
  ds = [0, -1, 1].repeated_permutation(dimensions).to_a
  ds.shift
  # Zero offset for compression here, of course.
  # Otherwise we'd move by the offset amount in each direction.
  ds.map { |dx, dy, *dwz| compress(dx, dy, dwz, 0, ybits, wzbits) }
end

def print_grids(poses, dimensions, rounds, ybits, wzbits)
  coords = poses.map { |pos| decompress(pos, dimensions, rounds, ybits, wzbits) }.freeze

  chr = poses.to_h { |pos| [pos, ?#.freeze] }
  chr.default = ?..freeze
  chr.freeze

  ranges = coords.transpose.map { |lim| Range.new(*lim.minmax).to_a }

  (ranges[2] || [0]).product(*ranges[3..]) { |high_dims|
    p high_dims
    ranges[1].each { |y|
      ranges[0].each { |x|
        coord = compress(x, y, dimensions > 2 ? high_dims : [], rounds, ybits, wzbits)
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
wzbits = (2 * rounds + 1).bit_length
ybits = (height + 2 * rounds + 1).bit_length
init_active.freeze
puts "ybits #{ybits} wzbits #{wzbits}" if verbose > 0

dims.each { |dim|
  dposes = neigh(dim, ybits, wzbits).freeze
  puts "dpos #{dposes.size}: #{dposes}" if verbose > 0
  zs = [0] * (dim - 2)
  active = init_active.map { |pos| compress(*pos, zs, rounds, ybits, wzbits) }

  rounds.times { |t|
    active = step(active, dposes).freeze
    if verbose > 0
      puts "t=#{t + 1} pop=#{active.size}"
      print_grids(active, dim, rounds, ybits, wzbits) if verbose > 1
    end
  }
  puts active.size
}
