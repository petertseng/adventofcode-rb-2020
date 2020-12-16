require_relative 'lib/bipartite_matching'

def validate_tickets(valid_for_field, tickets, verbose: false)
  # Didn't actually *need* to merge the intervals,
  # but I thought the code might come in handy.
  intervals = valid_for_field.values.flatten.map { |r| [r.min, r.max] }
  valid_for_any_field = merge_intervals(intervals.sort).map { |a, b| Range.new(a, b) }
  puts "merged into #{valid_for_any_field.size} intervals: #{valid_for_any_field}" if verbose

  error = 0
  valids = tickets.select { |ticket|
    invalid_fields = ticket.select { |field| valid_for_any_field.none? { |r| r.cover?(field) } }
    error += invalid_fields.sum
    ticket.freeze if invalid_fields.empty?
  }.freeze
  [error, valids]
end

# Assumes without checking that input intervals are sorted by start time.
def merge_intervals(intervals, merge_adjacent: true)
  prev_min, prev_max = intervals.first
  (intervals.each_with_object([]) { |r, merged|
    min, max = r
    if min > prev_max + (merge_adjacent ? 1 : 0)
      merged << [prev_min, prev_max].freeze
      prev_min, prev_max = r
    else
      prev_max = [prev_max, max].max
    end
  } << [prev_min, prev_max].freeze).freeze
end

def solve_indices_for_fields(valid_for_field, tickets, verbose: false)
  fields_matching_index = fields_matching_indices(valid_for_field, tickets).each_with_index.to_h { |fs, i| [i, fs] }
  pretty_print_grid(fields_matching_index) if verbose
  BipartiteMatching.match(fields_matching_index, verbose: verbose)
end

# Returns array where each element is the fields that could match at that index.
def fields_matching_indices(valid_for_field, tickets)
  num_fields = tickets.map(&:size).uniq
  raise "inconsistent number of fields #{num_fields}" if num_fields.size != 1
  num_fields = num_fields[0]
  # Using Set(valid_for_field.keys) doesn't seem to make this faster,
  # and a bitfield is significantly harder to read and not faster enough to make it worth it.
  # So we'll just go with arrays.
  tickets.each_with_object(Array.new(num_fields) { valid_for_field.keys }) { |ticket, match|
    ticket.each_with_index { |v, i|
      match[i] &= valid_for_field.select { |f, rs|
        rs.any? { |r| r.cover?(v) }
      }.keys
    }
  }
end

def pretty_print_grid(fields_matching_index)
  indices_for_field = BipartiteMatching.invert(fields_matching_index)
  longest_field = indices_for_field.keys.map(&:size).max
  num_fields = fields_matching_index.size

  indices_for_field.each { |field, is|
    xs = (0...num_fields).map { |i| is.include?(i) ? ?# : ' ' }.join.rstrip
    puts "%#{longest_field}s #{xs}" % field
  }
end

def ticket(line)
  line.split(?,).map(&method(:Integer))
end

verbose = ARGV.delete('-v')

fields, (mine_header, mine, *bad), (nearby_header, *nearby) = ARGF.each("\n\n", chomp: true).map(&:lines)
raise "bad #{mine_header} before mine" unless mine_header.start_with?('your')
raise "bad #{bad} after mine" unless bad.empty?
raise "bad #{nearby_header} before nearby" unless nearby_header.start_with?('nearby')

valid_for_field = fields.to_h { |fl|
  name, ranges = fl.split(?:, 2)
  ranges = ranges.split(' or ').map { |r| Range.new(*r.split(?-).map(&method(:Integer))) }
  [name.freeze, ranges.freeze]
}.freeze

error, valid_nearby = validate_tickets(valid_for_field, nearby.map(&method(:ticket)), verbose: verbose)
puts "#{valid_nearby.size} valid / #{nearby.size} nearby" if verbose
puts error

field_for_index = solve_indices_for_fields(valid_for_field, valid_nearby, verbose: verbose)
puts "deduced #{field_for_index.size} / #{valid_for_field.size} fields" if verbose
mine = ticket(mine)
puts field_for_index.map { |i, f|
  f.start_with?('departure') ? mine[i] : 1
}.reduce(:*)
