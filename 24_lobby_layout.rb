dir_regex = /[ns]?[ew]/
dirs_regex = /^(#{dir_regex})+$/

verbose = ARGV.delete('-v')

coords = ARGF.map { |line|
  y = 0
  x = 0
  raise "bad #{line}" unless dirs_regex.match?(line)
  line.chomp.scan(dir_regex) { |dir|
    case dir
    when 'ne'
      y += 1
    when 'sw'
      y -= 1
    when 'se'
      x += 1
    when 'nw'
      x -= 1
    when 'e'
      y += 1
      x += 1
    when 'w'
      y -= 1
      x -= 1
    else
      raise "unknown #{dir}"
    end
  }
  [y, x].freeze
}.freeze

steps = 100

xmin, xmax = coords.map(&:last).minmax
ymin = coords.map(&:first).min
width = (xmin..xmax).size + steps * 2

flips = coords.map { |y, x| (y - ymin + steps) * width + x - xmin + steps }.tally
black = flips.filter_map { |pos, n| pos if n % 2 == 1 }
puts black.size

steps.times { |t|
  puts "#{t + 1}: #{black.size}" if verbose

  # (neigh_count << 1) | self
  neigh_and_self = Hash.new(0)

  black.each { |pos|
    neigh_and_self[pos - 1] += 2
    neigh_and_self[pos + 1] += 2
    neigh_and_self[pos - width] += 2
    neigh_and_self[pos + width] += 2
    neigh_and_self[pos - width - 1] += 2
    neigh_and_self[pos + width + 1] += 2
    neigh_and_self[pos] += 1
  }

  black = neigh_and_self.filter_map { |pos, count_and_self|
    # 3 011 count 1, black
    # 4 100 count 2, white
    # 5 101 count 2, black
    pos if 3 <= count_and_self && count_and_self <= 5
  }
}

puts black.size
