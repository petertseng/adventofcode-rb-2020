require 'benchmark'
require 'set'
require_relative '../11_seating_system'

# 4 bits for neighbour count, 2 bits for state, 1 bit for active
FLOOR_T = 0
EMPTY_T = 0x10
OCCUPIED_T = 0x20
TYPE = 0x30
TYPE_AND_NEIGH = TYPE | 0xf
ACTIVE = 0x40

bench_candidates = %i(equilibrium_logic equilibrium_sim)

bench_candidates << def equilibrium_occupied_set(seats, neighs, occupy_threshold, verbose: false)
  seats = seats.dup
  occupied = Set.new(seats.each_index.select { |i| seats[i] == OCCUPIED })
  non_floors = seats.each_index.select { |i| seats[i] != FLOOR }.freeze

  while true
    occupied_neighs = Array.new(seats.size, 0)
    occupied.each { |pos|
      neighs[pos].each { |npos|
        occupied_neighs[npos] += 1
      }
    }

    changed = false
    non_floors.each { |pos|
      seat = seats[pos]
      if seat == EMPTY && occupied_neighs[pos] == 0
        changed = true
        occupied << pos
        seats[pos] = OCCUPIED
      elsif seat == OCCUPIED && occupied_neighs[pos] >= occupy_threshold
        changed = true
        occupied.delete(pos)
        seats[pos] = EMPTY
      end
    }
    return occupied.size if !changed
  end
end

bench_candidates << def equilibrium_occupied_no_mut(seats, neighs, occupy_threshold, verbose: false)
  occupied = Set.new(seats.each_index.select { |i| seats[i] == OCCUPIED })
  non_floors = seats.each_index.select { |i| seats[i] != FLOOR }.freeze

  while true
    occupied_neighs = Array.new(seats.size, 0)
    occupied.each { |pos|
      neighs[pos].each { |npos|
        occupied_neighs[npos] += 1
      }
    }

    changed = false
    non_floors.each { |pos|
      was_occupied = occupied.include?(pos)
      if !was_occupied && occupied_neighs[pos] == 0
        changed = true
        occupied << pos
      elsif was_occupied && occupied_neighs[pos] >= occupy_threshold
        changed = true
        occupied.delete(pos)
      end
    }
    return occupied.size if !changed
  end
end

bench_candidates << def equilibrium_occupied_h_no_mut(seats, neighs, occupy_threshold, verbose: false)
  occupied = seats.each_index.filter_map { |i| [i, true] if seats[i] == OCCUPIED }.to_h
  non_floors = seats.each_index.select { |i| seats[i] != FLOOR }.freeze

  while true
    occupied_neighs = Array.new(seats.size, 0)
    occupied.each_key { |pos|
      neighs[pos].each { |npos|
        occupied_neighs[npos] += 1
      }
    }

    changed = false
    non_floors.each { |pos|
      was_occupied = occupied[pos]
      if !was_occupied && occupied_neighs[pos] == 0
        changed = true
        occupied[pos] = true
      elsif was_occupied && occupied_neighs[pos] >= occupy_threshold
        changed = true
        occupied.delete(pos)
      end
    }
    return occupied.size if !changed
  end
end

bench_candidates << def equilibrium_cache_neighbour_count(seats, neighs, occupy_threshold, verbose: false)
  seats = seats.dup
  if seats.any? { |seat| seat == OCCUPIED }
    raise 'initially-occupied seats are completely untested'
    # We should increment the neighbour counts of each.
  end

  occupied_neighs = Array.new(seats.size, 0)

  while true
    to_change = seats.each_index.select { |pos|
      seat = seats[pos]
      seat == EMPTY && occupied_neighs[pos] == 0 || seat == OCCUPIED && occupied_neighs[pos] >= occupy_threshold
    }

    return seats.count(OCCUPIED) if to_change.empty?

    to_change.each { |pos|
      seat = seats[pos]
      delta = seat == EMPTY ? 1 : -1
      seats[pos] = seat == EMPTY ? OCCUPIED : EMPTY

      neighs[pos].each { |npos|
        occupied_neighs[npos] += delta
      }
    }
  end
end

bench_candidates << def equilibrium_active(seats, neighs, occupy_threshold)
  # Since 0 neighbours triggers change, initially empty seats are active.
  seats = seats.map { |c|
    case c
    when OCCUPIED; OCCUPIED_T
    when EMPTY; EMPTY_T | ACTIVE
    when FLOOR; FLOOR_T
    else raise "bad #{c}"
    end
  }

  if seats.any? { |seat| seat & TYPE == OCCUPIED_T }
    raise "initially-occupied seats are completely untested"
    # We should increment the neighbour counts of each.
  end

  active = Set.new(seats.each_index.select { |i| seats[i] & TYPE == EMPTY_T })

  t = 0
  while true
    # Find active cells that will change.
    t += 1

    prev_active_size = active.size
    active.select! { |pos|
      seat = seats[pos]
      type_and_neigh = seat & TYPE_AND_NEIGH
      # empty and 0 neighbour, or occupied and >= thresh
      changed = type_and_neigh == EMPTY_T || type_and_neigh >= (OCCUPIED_T + occupy_threshold)
      seats[pos] &= ~ACTIVE if !changed
      changed
    }

    STDERR.puts("t #{t}: #{active.size} changed / #{prev_active_size} active") if false

    return seats.count { |s| s & TYPE == OCCUPIED_T } if active.empty?

    new_actives = []
    # These are the cells that have been confirmed to be changing.
    active.each { |pos|
      seat = seats[pos]
      was_empty = seat & TYPE == EMPTY_T
      neighbour_delta = was_empty ? 1 : -1
      seats[pos] = seat ^ TYPE

      neighs[pos].each { |npos|
        # Change their neighbours' neighbour counts,
        new_state = seats[npos] + neighbour_delta
        # mark all their neighbours as active
        if new_state & ACTIVE == 0
          new_actives << pos
          new_state |= ACTIVE
        end
        seats[npos] = new_state
      }
    }
    active |= new_actives

    if false
      t += 1
      puts "t = #{t}"
      seats.each_slice(width) { |row|
        puts row.map { |seat|
          case seat & TYPE
          when FLOOR_T; FLOOR
          when EMPTY_T; EMPTY
          when OCCUPIED_T; OCCUPIED
          end
        }.join
      }
      puts
    end
  end
end

seats = @seats
height = @height
width = @width

{
  adjacent: [neighs(seats, height, width), 4],
  vision: [neighs(seats, height, width, vision: true), 5],
}.each { |name, args|
  puts name

  results = {}

  Benchmark.bmbm { |bm|
    bench_candidates.each { |f|
      bm.report(f) { results[f] = send(f, seats, *args) }
    }
  }

  # Obviously the benchmark would be useless if they got different answers.
  if results.values.uniq.size != 1
    results.each { |k, v| puts "#{k} #{v}" }
    raise 'differing answers'
  end
}
