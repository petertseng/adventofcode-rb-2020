require 'benchmark'

SLOPES = [1, 3, 5, 7, Rational(1, 2)].freeze

bench_candidates = []

bench_candidates << def by_slope_then_input(input)
  SLOPES.to_h { |dx_per_dy|
    [dx_per_dy, input.each_with_index.count { |row, y|
      x = dx_per_dy * y
      x.to_i == x && row[x % row.size]
    }]
  }
end

bench_candidates << def by_slope_then_input_index(input)
  SLOPES.to_h { |dx_per_dy|
    y_stride = dx_per_dy.to_i == dx_per_dy ? 1 : dx_per_dy.denominator
    [dx_per_dy, ((input.size + y_stride - 1) / y_stride).times.count { |i|
      y = i * y_stride
      x = dx_per_dy * y
      row = input[y]
      row[x % row.size]
    }]
  }
end

bench_candidates << def by_pos_set(input)
  rows = input.map { |row|
    [row.size, row.each_with_index.flat_map { |c, i|
      if c
        # need to support lookup by both integer and rational forms.
        [[i, true], [Rational(i, 1), true]]
      else
        []
      end
    }.to_h.freeze]
  }.freeze
  SLOPES.to_h { |dx_per_dy|
    [dx_per_dy, rows.each_with_index.count { |(width, row), y|
      row[(dx_per_dy * y) % width]
    }]
  }
end

bench_candidates << def by_pos_set_pre_expanded(input)
  rows = input.map.with_index { |row, y|
    mult_needed = Rational(SLOPES.max * y, row.size).ceil + 1
    row.each_with_index.flat_map { |c, i|
      if c
        mult_needed.times.flat_map { |j|
          # need to support lookup by both integer and rational forms.
          [[j * row.size + i, true], [j * row.size + Rational(i, 1), true]]
        }
      else
        []
      end
    }.to_h.freeze
  }.freeze
  SLOPES.to_h { |dx_per_dy|
    [dx_per_dy, rows.each_with_index.count { |row, y|
      row[dx_per_dy * y]
    }]
  }
end

bench_candidates << def by_each_slice_conditional(input)
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

bench_candidates << def by_each_slice_unconditional(input)
  SLOPES.to_h { |dx_per_dy|
    if dx_per_dy.to_i == dx_per_dy
      dx_per_slice = dx_per_dy
      slice_size = 1
    else
      dx_per_slice = dx_per_dy.numerator
      slice_size = dx_per_dy.denominator
    end
    [dx_per_dy, input.each_slice(slice_size).with_index.count { |(row, _), i|
      row[(i * dx_per_slice) % row.size]
    }]
  }
end

bench_candidates << def by_input_then_slope(input)
  input.each_with_index.with_object(Hash.new(0)) { |(row, y), trees|
    SLOPES.each { |dx_per_dy|
      x = dx_per_dy * y
      trees[dx_per_dy] += 1 if x.to_i == x && row[x % row.size]
    }
  }.freeze
end

bench_candidates << def by_input_then_slope_manual_pos(input)
  xs = SLOPES.map { 0 }
  input.each_with_index.with_object(Hash.new(0)) { |(row, y), trees|
    SLOPES.zip(xs) { |dx_per_dy, x|
      trees[dx_per_dy] += 1 if x.to_i == x && row[x % row.size]
    }
    SLOPES.each_with_index { |dx_per_dy, i|
      xs[i] += dx_per_dy
    }
  }.freeze
end

cs = {?# => true, ?. => false}.freeze
input = ARGF.map { |l| l.chomp.chars.map { |c| cs.fetch(c) } }.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { results[f] = send(f, input) }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
