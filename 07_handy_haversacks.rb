require_relative 'lib/search'

contain = Hash.new { |h, k| h[k] = [] }
contained_by = Hash.new { |h, k| h[k] = [] }

verbose = ARGV.delete('-v')

ARGF.each_line(chomp: true) { |line|
  l, r = line.split(' contain ')
  containing_bag = l.delete_suffix(' bags').freeze

  r.split(', ').each { |contained|
    next if contained == 'no other bags.'

    words = contained.split
    raise "bad bag #{contained}" unless words[-1].start_with?('bag')

    quantity = Integer(words[0])
    contained = words[1..-2].join(' ').freeze

    contain[containing_bag] << [quantity, contained].freeze
    contained_by[contained] << containing_bag
  }
}

[contain, contained_by].each { |h|
  h.default_proc = nil
  h.default = [].freeze
  h.each_value(&:freeze)
  h.freeze
}

my_bag = 'shiny gold'.freeze

puts Search.bfs(my_bag, neighbours: contained_by, goal: ->bag { bag != my_bag })[:goals].size

@rcb_cache = {}
def recursively_contained_by(contain, bag)
  @rcb_cache[bag] ||= contain[bag].sum { |qnt, contained_bag|
    qnt * (1 + recursively_contained_by(contain, contained_bag))
  }
end

puts recursively_contained_by(contain, my_bag)

if verbose
  recursively_contained_by = contain.keys.to_h { |k| [k, recursively_contained_by(contain, k)] }
  recursively_contained_by.sort_by(&:last).each { |k, v|
    puts "#{k} #{v}"
  }
end
