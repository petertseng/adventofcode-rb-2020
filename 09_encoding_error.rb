def not_sum_of_prev(data, win_size)
  prevs = []
  freq = Hash.new(0)

  data.find { |x|
    if prevs.size < win_size
      prevs << x
      freq[x] += 1
      next
    end
    prevs.none? { |prev| prev * 2 != x && freq[x - prev] > 0 }.tap {
      removed = prevs.shift
      freq[removed] -= 1
      freq.delete(removed) if freq[removed] == 0

      prevs << x
      freq[x] += 1
    }
  }
end

def window_summing_to(data, target)
  # Sum of elements strictly to the left.
  # With no negatives, strictly increasing.
  sum = 0
  cumulative_sum = [0] + data.map { |x| sum += x }

  # sliding window over the cumulative sums
  left_i = 0
  left = 0
  left_bsearch = true
  right_i = 0
  right = 0
  right_bsearch = true

  diff = target

  while diff != 0
    if diff > 0
      # Window too small; expand window's right side
      diff += right
      if right_bsearch
        cmps = 0
        old_i = right_i
        right_i = ((right_i + 1)...cumulative_sum.size).bsearch { |i|
          cmps += 1
          diff - cumulative_sum[i] <= 0
        }
        # Only keep using binary search if it's giving benefit
        right_bsearch &&= right_i - old_i > cmps
        #puts "right moved #{right_i - old_i} in #{cmps} cmps, will we keep using it? #{right_bsearch}"
      else
        right_i += 1
      end
      diff -= right = cumulative_sum[right_i]
    else
      # Window too large; shrink window's left side
      diff -= left
      if left_bsearch
        cmps = 0
        old_i = left_i
        left_i = ((left_i + 1)...cumulative_sum.size).bsearch { |i|
          cmps += 1
          diff + cumulative_sum[i] >= 0
        }
        # Only keep using binary search if it's giving benefit
        left_bsearch &&= left_i - old_i > cmps
        #puts "left moved #{left_i - old_i} in #{cmps} cmps, will we keep using it? #{left_bsearch}"
      else
        left_i += 1
      end
      diff += left = cumulative_sum[left_i]
    end
  end

  [left_i, right_i]
end

verbose = ARGV.delete('-v')
prefix_len = if (arg = ARGV.find { |a| a.start_with?('-n') })
  ARGV.delete(arg)
  Integer(arg[2..])
else
  25
end

data = ARGF.map(&method(:Integer)).freeze
raise "Can't handle negatives #{data.select(&:negative?)}" if data.any?(&:negative?)

target = not_sum_of_prev(data, prefix_len)
puts "#{target}#{" @ #{data.index(target)}" if verbose}"

left_i, right_i = window_summing_to(data, target)
# data[left_i...right_i].sum == target
minmax = data[left_i...right_i].minmax
puts "#{"#{left_i}...#{right_i} #{minmax} " if verbose}#{minmax.sum}"
