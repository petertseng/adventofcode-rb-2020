require 'benchmark'
require_relative '../14_docking_data'

bench_candidates = %i(run2)

bench_candidates << def run2_no_write(insts)
  mask_ones = nil
  mask_xs = nil

  writes = []

  insts.each { |inst, arg|
    case inst
    when :mask
      _, mask_ones, mask_xs = arg
    when :mem
      addr, val = arg
      addr |= mask_ones
      writes << {
        fixed: addr & ~mask_xs,
        floats: mask_xs,
        cached_expansion: nil,
        val: val,
      }
    else raise "bad #{inst} #{arg}"
    end
  }

  expand = ->w {
    w[:cached_expansion] ||= begin
      # You'd think a hash or Set would be faster...
      # but it turns out not to be?
      pats = []
      fixed = w[:fixed]
      floats = w[:floats]
      n = 0
      while true
        pats << (fixed | n)
        n = (n + ~floats + 1) & floats
        break if n == 0
      end
      pats.freeze
    end
  }

  writes.each_with_index.sum { |write, i|
    # A fixed (not floating) 0 can't overlap with a fixed 1.
    could_overlap = writes[(i + 1)..].reject { |w|
      # Make sure we are only comparing positions where both are fixed.
      # (both fixed = neither are floating)
      float_in_either = w[:floats] | write[:floats]
      (w[:fixed] ^ write[:fixed]) & ~float_in_either != 0
    }
    write[:val] * if could_overlap.empty?
      2 ** write[:floats].to_s(2).count(?1)
    else
      uncollided = expand[write]
      could_overlap.each { |overlap|
        uncollided -= expand[overlap]
      }
      uncollided.size
    end
  }#.tap { |x| puts "#{writes.count { |w| w[:cached_expansion] }} / #{writes.size} were expanded" }
end

# This isn't even close to being a contender;
# the access pattern doesn't have enough locality for this,
# since the floating bits could be anywhere.
bench_candidates << def run2_page_table(insts)
  mask_ones = nil
  mask_xs = nil
  pages = Hash.new { |h, k| h[k] = [] }
  addr_in_page_bits = 10
  page_index_bits = 36 - addr_in_page_bits
  addr_in_page_mask = (1 << addr_in_page_bits) - 1
  page_index_mask = ((1 << page_index_bits) - 1) << addr_in_page_bits

  insts.each { |inst, arg|
    case inst
    when :mask
      _, mask_ones, mask_xs = arg
    when :mem
      addr, val = arg
      addr |= mask_ones
      addr &= ~mask_xs
      n = 0
      while true
        dest = addr | n

        # Could shift page_index >> addr_in_page_bits so that it starts at 0,
        # but no point since pages are stored sparsely anyway.
        pages[dest & page_index_mask][dest & addr_in_page_mask] = val

        n = (n + ~mask_xs + 1) & mask_xs
        break if n == 0
      end
    else raise "bad #{inst} #{arg}"
    end
  }

  pages.sum { |_, v| v.compact.sum }
end

insts = @insts

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { results[f] = send(f, insts) }
  }
}

sum_if_h = ->h { h.is_a?(Hash) ? h.values.sum : h }

# Obviously the benchmark would be useless if they got different answers.
if results.values.map(&sum_if_h).uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
