# Only works for 32-bit integers,
# but since there are only 26 letters, it's fine.
def popcount32(v)
  v = v - ((v >> 1) & 0x55555555)
  v = (v & 0x33333333) + ((v >> 2) & 0x33333333)
  (((v + (v >> 4) & 0x0F0F0F0F) * 0x01010101) >> 24) & 0x3f
end

verboses = if ARGV.delete('-v')
  [true, true]
elsif ARGV.delete('-v1')
  [true, false]
elsif ARGV.delete('-v2')
  [false, true]
end

a = ?a.ord

groups = ARGF.each_line(chomp: true).slice_before(&:empty?).map { |group_lines|
  group_lines.reject(&:empty?).map { |line|
    # We could just store the chars,
    # since | and & work on arrays,
    # but I decided to use bitfields on principle.
    line.chars.sum { |c| 1 << (c.ord - a) }
  }.freeze
}

if verboses
  puts "#{groups.size} groups"
  puts "#{groups.map(&:size).tally}"
end

puts %i(| &).zip(verboses || [false, false]).map { |sym, verbose|
  groups.sum { |group|
    v = popcount32(group.reduce(sym))
    p v if verbose
    v
  }
}
