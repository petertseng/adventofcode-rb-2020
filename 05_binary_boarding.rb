def sum_between(min, max)
  pair = min + max
  # Take pairs off the left/right ends,
  # plus the remaining half-pair if the size is odd.
  num_pairs, num_half_pairs = (max - min + 1).divmod(2)
  pair * num_pairs + (num_half_pairs * pair / 2)
end

verbose = if ARGV.delete('-vv')
  2
elsif ARGV.delete('-v')
  1
else
  0
end

min = Float::INFINITY
max = 0
sum = 0

# Could keep a set of all IDs and search it which is fast enough,
# but the constant-space solution seems interesting.
ARGF.each_line { |l|
  # For the sake of writing less code,
  # I won't distinguish between row/column for this one.
  # But it does mean it lets through bad inputs like LLLLLLLFFF.
  id = l.tr('BFRL', '1010').to_i(2)
  puts "#{l.strip} #{id}" if verbose > 1
  min = id if id < min
  max = id if id > max
  sum += id
}

expected_sum = sum_between(min, max)
puts "(#{min}..#{max}).sum = #{expected_sum}" if verbose > 0

puts max
puts expected_sum - sum
