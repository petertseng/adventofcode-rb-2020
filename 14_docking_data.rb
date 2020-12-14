# Could move the common parts of run1 + run2 into a run
# yielding on addr to account for the differences there.
# But it is a little slower and doesn't help readability that much.
def run1(insts)
  mask_zeroes = nil
  mask_ones = nil

  insts.each_with_object(Hash.new(0)) { |(inst, arg), mem|
    case inst
    when :mask
      mask_zeroes, mask_ones, _ = arg
    when :mem
      addr, val = arg
      mem[addr] = (val | mask_ones)  & ~mask_zeroes
    else raise "bad #{inst} #{arg}"
    end
  }
end

def run2(insts)
  mask_ones = nil
  mask_xs = nil

  insts.each_with_object(Hash.new(0)) { |(inst, arg), mem|
    case inst
    when :mask
      _, mask_ones, mask_xs = arg
    when :mem
      addr, val = arg
      addr |= mask_ones
      addr &= ~mask_xs
      n = 0
      # Iterate over all bit patterns that are a subpattern of mask_xs
      # This is indeed faster than precomputing them all and storing the list,
      # because it iterates over the same number of elements,
      # but doesn't have to create a large number of lists.
      while true
        mem[addr | n] = val
        n = (n + ~mask_xs + 1) & mask_xs
        break if n == 0
      end
    else raise "bad #{inst} #{arg}"
    end
  }
end

too_many_floating_bits = false

verbose = ARGV.delete('-v')
t = Time.now
insts = ARGF.map { |l|
  if l.start_with?('mask')
    mask_ones = 0
    mask_zeroes = 0
    mask_xs = 0
    mask_xs_popcount = 0
    mask_str = l.split.last
    mask_str.reverse.each_char.with_index { |c, i|
      case c
      when ?0; mask_zeroes |= 1 << i
      when ?1; mask_ones |= 1 << i
      when ?X
        mask_xs |= 1 << i
        mask_xs_popcount += 1
      else raise "bad mask #{mask_str} has #{c} at #{i}"
      end
    }
    # Nobody says to reject too many Xs,
    # but the part 1 example has too many,
    # and the actual inputs won't.
    too_many_floating_bits ||= mask_xs_popcount >= 10
    [:mask, [mask_zeroes, mask_ones, mask_xs].freeze].freeze
  elsif l.start_with?('mem')
    nums = l.scan(/\d+/).map(&method(:Integer))
    raise "bad #{l}" if nums.size != 2
    [:mem, nums.freeze].freeze
  else
    raise "bad inst #{l}"
  end
}.freeze
puts "parse #{Time.now - t}" if verbose

t = Time.now
mem1 = run1(insts)
puts mem1.values.sum
puts "#{mem1.size} addrs in #{Time.now - t}" if verbose

if too_many_floating_bits
  puts 'too many floating bits'
else
  t = Time.now
  mem2 = run2(insts)
  puts mem2.values.sum
  puts "#{mem2.size} addrs in #{Time.now - t}" if verbose
end

# export for benchmark
@insts = insts
