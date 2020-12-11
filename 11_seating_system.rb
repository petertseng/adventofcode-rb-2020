OCCUPIED = ?#.ord
EMPTY = ?L.ord
FLOOR = ?..ord

def seat_in_direction(seats, height, width, y, x, dy, dx)
  ny = y + dy
  nx = x + dx
  pos = ny * width + nx
  size = height * width
  dpos = dy * width + dx
  return :no_seat unless (0...size).cover?(pos)
  return :no_seat unless (0...width).cover?(nx)
  while seats[pos] == FLOOR
    pos += dpos
    nx += dx
    return :no_seat unless (0...size).cover?(pos)
    return :no_seat unless (0...width).cover?(nx)
  end
  pos
end

def neighs(seats, height, width, vision: false)
  Array.new(seats.size) { |pos|
    next if seats[pos] == FLOOR

    y, x = pos.divmod(width)
    min_dy = y == 0 ? 0 : -1
    min_dx = x == 0 ? 0 : -1
    max_dy = y == height - 1 ? 0 : 1
    max_dx = x == width - 1 ? 0 : 1
    dxrange = min_dx..max_dx

    (min_dy..max_dy).flat_map { |dy|
      dxrange.filter_map { |dx|
        next if dy == 0 && dx == 0

        if vision
          n = seat_in_direction(seats, height, width, y, x, dy, dx)
          next if n == :no_seat
          n
        else
          n = (y + dy) * width + x + dx
          n if seats[n] != FLOOR
        end
      }
    }.freeze
  }.freeze
end

# Let's apply some logic that doesn't work in general,
# but actually does work for inputs given.
#
# Reason as follows:
#
# For any seat with too few neighbours (corners, etc),
# once they become occupied, they stay that way forever,
# since they will never have occupied neighbours >= threshold.
#
# Thus, the seats adjacent to them, once they become free, will stay that way forever,
# since they will never have zero occupied neighbours.
#
# That in turns makes it some that more seats have too few neighbours and stay occupied forever,
# and the cycle repeats.
#
# This doesn't work in general because the statements above say "once they become occupied/free",
# but there's no guarantee that they actually become that way.
def equilibrium_logic(_, neighs, occupy_threshold, verbose: false)
  seats = neighs.map.with_index { |neigh, i| neigh && Seat.new(i, neigh) }.freeze
  can_lock_occupied = seats.select { |seat| seat && seat.max_occupied_neigh < occupy_threshold }
  t = 0

  until can_lock_occupied.empty?
    t += 1
    puts "t=#{t} Locking #{can_lock_occupied.uniq.size} occupied" if verbose
    can_lock_empty = can_lock_occupied.flat_map { |seat| seat.lock_occupied(seats) }

    t += 1
    puts "t=#{t} Locking #{can_lock_empty.uniq.size} empty" if verbose
    can_lock_occupied = can_lock_empty.flat_map { |seat| seat.lock_empty(seats, occupy_threshold) }
  end

  unknowns = seats.count { |seat| seat && seat.locked_known.nil? }
  raise "#{unknowns} unknowns" if unknowns != 0
  seats.count { |seat| seat&.locked_known == OCCUPIED }
end

class Seat
  attr_reader :pos, :locked_known

  def initialize(pos, neighs)
    @pos = pos
    @locked_known = nil
    @neighs = neighs.freeze
    @known_occupied_neigh = 0
    @unknown_neigh = neighs.size
  end

  # Ideally the lock_* would raise if @locked_known is already the opposite type.
  # However, seats about to be locked know nothing about each other,
  # therefore they may mistakely say that a seat about to be marked as their own type is lockable as the other type.

  # Returns any neighbours that can now known to be locked empty.
  def lock_occupied(seats)
    return [] if @locked_known
    @locked_known = OCCUPIED
    @neighs.filter_map { |npos|
      neigh = seats[npos]
      next if neigh.locked_known
      old_min = neigh.min_occupied_neigh
      neigh.known_occupied_neigh += 1
      neigh.unknown_neigh -= 1
      neigh if old_min == 0
    }
  end

  # Returns any neighbours that can now known to be locked occupied.
  def lock_empty(seats, occupy_threshold)
    return [] if @locked_known
    @locked_known = EMPTY
    @neighs.filter_map { |npos|
      neigh = seats[npos]
      next if neigh.locked_known
      old_max = neigh.max_occupied_neigh
      neigh.unknown_neigh -= 1
      neigh if old_max == occupy_threshold
    }
  end

  def min_occupied_neigh
    @known_occupied_neigh
  end

  def max_occupied_neigh
    @known_occupied_neigh + @unknown_neigh
  end

  protected
  attr_accessor :unknown_neigh
  attr_accessor :known_occupied_neigh
end

def equilibrium_sim(seats, neighs, occupy_threshold, verbose: false)
  seats = seats.dup
  occupied = seats.each_index.filter_map { |i| [i, true] if seats[i] == OCCUPIED }.to_h
  non_floors = seats.each_index.select { |i| seats[i] != FLOOR }.freeze
  t = 0

  while true
    occupied_neighs = Array.new(seats.size, 0)
    occupied.each_key { |pos|
      neighs[pos].each { |npos|
        occupied_neighs[npos] += 1
      }
    }

    changed = false
    non_floors.each { |pos|
      seat = seats[pos]
      if seat == EMPTY && occupied_neighs[pos] == 0
        changed = true
        occupied[pos] = true
        seats[pos] = OCCUPIED
      elsif seat == OCCUPIED && occupied_neighs[pos] >= occupy_threshold
        changed = true
        occupied.delete(pos)
        seats[pos] = EMPTY
      end
    }

    # kinda bad, verbose is the width
    if verbose
      t += 1
      puts "t=#{t}"
      puts seats.map(&:chr).each_slice(verbose).map(&:join)
      puts
    end

    return occupied.size if !changed
  end
end

if ARGV.delete('-s')
  alias :equilibrium :equilibrium_sim
else
  alias :equilibrium :equilibrium_logic
end
verbose = ARGV.delete('-v')
seats = ARGF.map(&:chomp).map(&:freeze).freeze
widths = seats.map(&:size).uniq
raise "wrong widths #{widths}" if widths.size != 1
width = widths[0]
height = seats.size
seats = seats.join.chars.map(&:ord).freeze

neighs = neighs(seats, height, width)
puts equilibrium(seats, neighs, 4, verbose: verbose && width)

neighs = neighs(seats, height, width, vision: true)
puts equilibrium(seats, neighs, 5, verbose: verbose && width)

# exporting for benchmark
@seats = seats
@height = height
@width = width
