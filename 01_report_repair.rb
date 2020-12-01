VERBOSE = ARGV.delete('-v')

def find_by_combination_sorted(input, input_tally)
  sorted = input.sort
  ans = [p1 = [], p2 = []]

  sorted.each_with_index { |x, i|
    needed = 2020 - x
    # This break will not miss a part 2 solution.
    # It occurs after all possible triplets have occurred.
    # It happens when x (the smaller of the pair) exceeds 2020/2,
    # but if we're starting from 2020/2, no triplet will succeed anyway,
    # since the triplet's smallest value must be no greater than 2020/3,
    # and 2020/2 > 2020/3 of course.
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
puts find_by_combination_sorted(input, input_tally)
