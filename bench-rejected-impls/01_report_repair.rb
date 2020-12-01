require 'benchmark'

VERBOSE = false

# For all of these, they could terminate early when they find the first answer,
# but I'll make them look for all answers for fairness
# (even though they'll all only find one each)

bench_candidates = []

# Straightforward. But we can do better.
bench_candidates << def find_by_combination(input, _)
  [2, 3].map { |sz|
    input.combination(sz).filter_map { |xs|
      xs.reduce(:*) if xs.sum == 2020
    }
  }
end

# All of these solutions that say `next if needed < xs.max` (or a variant of it) are all wrong
# ... but it's equally wrong to use <=
# ... but neither matters for Advent of Code inputs.
#
# Specifically they'll do the wrong thing on input [1010, 1010].
# You should include 1010*1010 in the output exactly once.
# < would include it twice, and <= would include it zero times.
# Also the wrong thing on [20, 1000, 1000] for similar reasons.
#
# Neither thing ever happens for Advent of Code inputs, so it's fine.

# The last element is determined by the others.
# Can check whether it exists w/ constant-time check.
bench_candidates << def find_by_combination_minus_one(input, input_tally)
  [1, 2].map { |sz|
    input.combination(sz).filter_map { |xs|
      needed = 2020 - xs.sum
      next if needed < xs.max
      required_count = xs.count(needed) + 1
      xs.reduce(:*) * needed if input_tally[needed] &.>= required_count
    }
  }
end

# As above, but unroll.
bench_candidates << def find_by_combination_unrolled(input, input_tally)
  [
    input.filter_map { |x|
      needed = 2020 - x
      next if needed < x
      required_count = x == needed ? 2 : 1
      x * needed if input_tally[needed] &.>= required_count
    },
    input.combination(2).filter_map { |x, y|
      needed = 2020 - x - y
      next if needed < x || needed < y
      required_count = (x == needed ? 1 : 0) + (y == needed ? 1 : 0) + 1
      x * y * needed if input_tally[needed] &.>= required_count
    }
  ]
end

# Advent of Code inputs only had 200 elements,
# and iterating those should be faster than 2021 elements...
# But in practice, this one's faster.
# It takes advantage of the fact that we're scanning the numbers in order,
# and therefore we can stop when the first two numbers are too big.
# (Note that stopping is still such that we find all solutions)
# This implies we can improve on the above solutions by sorting.
bench_candidates << def find_over_input_range(input, input_tally)
  ans = [p1 = [], p2 = []]

  min, max = input.minmax
  (min..max).each { |a|
    next unless input_tally[a] &.>= 1
    b = 2020 - a
    # This break will not miss a part 2 solution.
    # Same reasoning as in current.
    break if b < a
    required_count = a == b ? 2 : 1
    p1 << a * b if input_tally[b] &.>= required_count

    (a..max).each { |b|
      required_count = a == b ? 2 : 1
      next unless input_tally[b] &.>= required_count
      c = 2020 - a - b
      break if c < b
      required_count = (a == c ? 1 : 0) + (b == c ? 1 : 0) + 1
      p2 << a * b * c if input_tally[c] &.>= required_count
    }
  }

  ans
end

# Just some quick checks to make sure it's not because filter_map or combinations are slow.
# This does help a little, but not enough to catch up to find_over_input_range.
bench_candidates << def find_by_combination_no_filter_map(input, input_tally)
  ans = [p1 = [], p2 = []]

  input.each { |x|
    needed = 2020 - x
    next if needed < x
    required_count = x == needed ? 2 : 1
    p1 << x * needed if input_tally[needed] &.>= required_count
  }

  input.combination(2) { |x, y|
    needed = 2020 - x - y
    next if needed < x || needed < y
    required_count = (x == needed ? 1 : 0) + (y == needed ? 1 : 0) + 1
    p2 << x * y * needed if input_tally[needed] &.>= required_count
  }

  ans
end

# And this helps a little more, but find_over_input_range is still better,
# so sorting is really the way to go here.
bench_candidates << def find_by_combination_no_combination(input, input_tally)
  input.each_with_index.with_object([[], []]) { |(x, i), (p1, p2)|
    needed = 2020 - x
    if needed >= x
      required_count = x == needed ? 2 : 1
      p1 << x * needed if input_tally[needed] &.>= required_count
    end

    ((i + 1)...input.size).each { |j|
      y = input[j]
      needed = 2020 - x - y
      next if needed < x || needed < y
      required_count = (x == needed ? 1 : 0) + (y == needed ? 1 : 0) + 1
      p2 << x * y * needed if input_tally[needed] &.>= required_count
    }
  }
end

# Use the fact that the numbers tend to be large (otherwise there'd be many solutions),
# sort them and end loops at earliest opportunity.
# (Note that stopping is still such that we find all solutions)
# Theoretically not an asymptotic improvement:
# askalski thinks the worst input is 1-673, 675, 2019,
# for which the early `break` have almost no effect.
# However, given the sorts of inputs we actually see, a pretty good improvement.
bench_candidates << def current(input, input_tally)
  sorted = input.sort
  ans = [p1 = [], p2 = []]

  sorted.each_with_index { |x, i|
    needed = 2020 - x
    # This break will not miss a part 2 solution.
    # Same reasoning as in find_over_input_range.
    break if needed < x
    required_count = x == needed ? 2 : 1
    if input_tally[needed] &.>= required_count
      p [x, needed] if VERBOSE
      p1 << x * needed
    end

    ((i + 1)...sorted.size).each { |j|
      y = sorted[j]
      needed = 2020 - x - y
      break if needed < y
      required_count = (x == needed ? 1 : 0) + (y == needed ? 1 : 0) + 1
      if input_tally[needed] &.>= required_count
        p [x, y, needed] if VERBOSE
        p2 << x * y * needed
      end
    }
  }

  ans
end

input = ARGF.map(&method(:Integer)).freeze
input_tally = input.tally.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { results[f] = send(f, input, input_tally) }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
