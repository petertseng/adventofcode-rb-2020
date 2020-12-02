verbose = if ARGV.delete('-v')
  [1, 2]
elsif ARGV.delete('-v1')
  [1]
elsif ARGV.delete('-v2')
  [2]
end

entries = ARGF.map { |line|
  nums, c, pw = line.split
  l, r = nums.split(?-).map(&method(:Integer))
  {
    l: l,
    r: r,
    c: c = c[0].freeze,
    pw: pw = pw.chomp.freeze,
    good: {
      1 => (l..r).cover?(pw.count(c)),
      2 => (pw[l - 1] == c) != (pw[r - 1] == c),
    }.freeze,
  }.freeze
}.freeze

puts entries.count { |e| e[:good][1] }
puts entries.count { |e| e[:good][2] }
puts entries.map.with_index { |e, i| "#{i} #{e[:good].values_at(*verbose).join(' ')}" } if verbose
