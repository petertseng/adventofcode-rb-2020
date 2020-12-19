require 'benchmark'

require_relative '../19_monster_messages'

VERBOSE = false

bench_candidates = %i(match0_recursive_regex)

def new_rules(raw_rules)
  raw_rules.merge(
    8 => [
      [42].freeze,
      [42, 8].freeze,
    ].freeze,
    11 => [
      [42, 31].freeze,
      [42, 11, 31].freeze,
    ].freeze,
  ).freeze
end


bench_candidates << def match0_descent_pos_index(messages, raw_rules)
  messages.count { |m| descent_suffixes_index(m, 0, new_rules(raw_rules), 0).include?(m.size) }
end

def descent_suffixes_index(m, pos, raw_rules, n)
  # This line not even necessary!
  # Guess the String case handles it just fine,
  # since nil != rule.
  #return [] if m.empty?

  case rule = raw_rules.fetch(n)
  when String
    m[pos] == rule ? [pos + 1] : []
  when Integer
    descent_suffixes_index(m, pos, raw_rules, rule)
  when Array
    rule.flat_map { |seq_rules|
      seq_rules.reduce([pos]) { |poses, seq_rule|
        poses.flat_map { |subpos|
          descent_suffixes_index(m, subpos, raw_rules, seq_rule)
        }
      }
    }
  else raise "bad rule #{n} #{rule}"
  end
end

bench_candidates << def match0_descent_substring(messages, raw_rules)
  messages.count { |m| descent_suffixes_substring(m, new_rules(raw_rules), 0).any?(&:empty?) }
end

def descent_suffixes_substring(m, raw_rules, n)
  # This line not even necessary!
  # Guess the String case handles it just fine,
  # since nil != rule.
  #return [] if m.empty?

  case rule = raw_rules.fetch(n)
  when String
    m[0] == rule ? [m[1..]] : []
  when Integer
    descent_suffixes_substring(m, raw_rules, rule)
  when Array
    rule.flat_map { |seq_rules|
      seq_rules.reduce([m]) { |ms, seq_rule|
        ms.flat_map { |subm|
          descent_suffixes_substring(subm, raw_rules, seq_rule)
        }
      }
    }
  else raise "bad rule #{n} #{rule}"
  end
end

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { results[f] = send(f, @messages, @raw_rules) }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
