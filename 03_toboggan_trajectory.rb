SLOPES = [1, 3, 5, 7, Rational(1, 2)].freeze

def by_each_slice_conditional(input)
  SLOPES.to_h { |dx_per_dy|
    trees = if dx_per_dy.to_i == dx_per_dy
      input.each_with_index.count { |row, y|
        row[(dx_per_dy * y) % row.size]
      }
    else
      dx_per_slice = dx_per_dy.numerator
      input.each_slice(dx_per_dy.denominator).with_index.count { |(row, _), i|
        row[(i * dx_per_slice) % row.size]
      }
    end
    [dx_per_dy, trees]
  }
end

verbose = ARGV.delete('-v')
cs = {?# => true, ?. => false}.freeze
input = ARGF.map { |l| l.chomp.chars.map { |c| cs.fetch(c) } }.freeze

trees = by_each_slice_conditional(input)
puts trees if verbose
puts trees[3]
puts trees.values.reduce(:*)
