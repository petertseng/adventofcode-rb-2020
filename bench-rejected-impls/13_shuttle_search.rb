require 'benchmark'

bench_candidates_1 = []

bench_candidates_1 << def depart_matching_id_iter_mod0(t0, buses)
  t0.step { |t|
    if (bus = buses.find { |busid| t % busid == 0 })
      return [t - t0, bus]
    end
  }
end

bench_candidates_1 << def depart_matching_id_neg_mod(t0, buses)
  buses.map { |busid| [-t0 % busid, busid] }.min_by(&:first)
end

bench_candidates_2 = []

bench_candidates_2 << def depart_matching_offset_search(buses)
  step = 1
  t = 0
  buses.map { |busid, bus_offset|
    t = t.step(by: step).find { |tt|
      tt % busid == -bus_offset % busid
    }
    step = step.lcm(busid)
    t
  }
end

bench_candidates_2 << def depart_matching_offset_search_asc(buses)
  step = 1
  t = 0
  buses.sort_by(&:first).map { |busid, bus_offset|
    t = t.step(by: step).find { |tt|
      tt % busid == -bus_offset % busid
    }
    step = step.lcm(busid)
    t
  }
end

bench_candidates_2 << def depart_matching_offset_search_desc(buses)
  step = 1
  t = 0
  buses.sort_by(&:first).reverse.map { |busid, bus_offset|
    t = t.step(by: step).find { |tt|
      tt % busid == -bus_offset % busid
    }
    step = step.lcm(busid)
    t
  }
end

bench_candidates_2 << def depart_matching_offset_crt(buses)
  step = 1
  t = 0
  buses.map { |busid, bus_offset|
    raise "can't #{step} #{busid}" unless (inv = inverse(step, busid))

    initial_diff = (-bus_offset - t) % busid
    t += step * ((initial_diff * inv) % busid)
    step = step.lcm(busid)
    t
  }
end

# Modify the above to handle non-coprimes.
# I haven't worked out yet why this is correct,
# but the diff is pretty small.
# Just divide by the gcd at the appropriate time.
bench_candidates_2 << def depart_matching_offset_non_coprime(buses)
  step = 1
  t = 0
  buses.map { |busid, bus_offset|
    gcd, x = egcd(step, busid)

    initial_diff = -bus_offset - t
    raise "can't #{step} #{busid} because offset #{initial_diff} vs gcd #{gcd}" if initial_diff % gcd != 0
    t += step * (((initial_diff % busid) * x) % busid) / gcd
    step = step.lcm(busid)
    t
  }
end

bench_candidates_2 << def depart_matching_offset_crt_all_at_once(buses)
  lcm = buses.reduce(1) { |acc, (busid, _)| acc.lcm(busid) }
  t = buses.sum { |busid, bus_offset|
    raise "can't #{step} #{busid}" unless (inv = inverse(lcm / busid, busid))
    -bus_offset * lcm * inv / busid
  } % lcm
  # bench candidates return an array for uniformity
  [t]
end

def egcd(a, n)
  t, newt = [0, 1]
  r, newr = [n, a]
  until newr == 0
    q = r / newr
    t, newt = [newt, t - q * newt]
    r, newr = [newr, r - q * newr]
  end
  [r, t]
end

def inverse(a, n)
  r, t = egcd(a, n)
  r > 1 ? nil : t % n
end

t0 = Integer(ARGF.readline)
buses = ARGF.readline.split(?,).map.with_index { |busid, i|
  busid == ?x ? nil : [Integer(busid), i].freeze
}.compact.freeze

[
  [bench_candidates_1, ->f { send(f, t0, buses.map(&:first)) }],
  [bench_candidates_2, ->f { send(f, buses).last }],
].each { |bench_candidates, ff|
  results = {}

  Benchmark.bmbm { |bm|
    bench_candidates.each { |f|
      bm.report(f) { 10.times { results[f] = ff[f] }}
    }
  }

  # Obviously the benchmark would be useless if they got different answers.
  if results.values.uniq.size != 1
    results.each { |k, v| puts "#{k} #{v}" }
    raise 'differing answers'
  end
}
