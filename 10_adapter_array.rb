verbose = ARGV.delete('-v')
adapters = ARGF.map(&method(:Integer)).freeze

chain = adapters.sort.freeze

diffs = chain.each_cons(2).map { |a, b| b - a }.tally
diffs.default = 0
# for the device, rated at 3 higher than the max adapter:
diffs[3] += 1
# for the outlet with 0 jolts vs the first adapter:
diffs[chain[0]] += 1
p diffs if verbose
puts diffs[1] * diffs[3]

# ways[j] = how many ways to make j jolts.
ways_verbose = Hash.new(0)
# We'll discard all elements but the last three.
# Inputs are not large enough to require it, but it's on principle.
# with the window being [prev1, prev2, prev3], with prev3 being the largest adapter:
prev1 = 0
prev2 = 0
prev3 = 1
prevj = 0
chain.each { |j|
  # Based on the difference between this element and the previous,
  # the previous three elements of ways[j] update as follows:
  # In all cases we want to keep the last three elements.
  case j - prevj
  when 1
    # [prev1, prev2, prev3, prev1 + prev2 + prev3]
    ways = prev1 + prev2 + prev3
    prev1 = prev2
    prev2 = prev3
    prev3 = ways
  when 2
    # [prev1, prev2, prev3, 0, prev2 + prev3]
    prev1 = prev3
    prev3 += prev2
    prev2 = 0
  when 3
    # [prev1, prev2, prev3, 0, 0, prev3]
    prev1 = 0
    prev2 = 0
  else raise "invalid gap #{prevj} #{j}"
  end

  ways_verbose[j] = prev3 if verbose && chain.size <= 200
  prevj = j
}
p ways_verbose if verbose
puts prev3
