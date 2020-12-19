def rule_regex(n, raw_rules, cache = {})
  cache[n] ||= begin
    rhs = raw_rules.fetch(n)
    if rhs.is_a?(String)
      rhs.freeze
    else
      alts = rhs.map { |rs| rs.map { |r| rule_regex(r, raw_rules, cache) }.join }
      "(?:#{alts.join(?|)})".freeze
    end
  end
end

def list_strings_matching(ns, raw_rules)
  cache = {}
  ns.map { |n|
    matches = strings_matching(n, raw_rules, cache)
    puts "#{n} matches #{matches.size}:"
    matches.each { |m|
      puts "    #{m}"
    }
    puts
    matches
  }
end

def strings_matching(n, raw_rules, cache = {})
  cache[n] ||= begin
    rhs = raw_rules.fetch(n)
    if rhs.is_a?(String)
      [rhs.freeze].freeze
    else
      rhs.flat_map { |rs|
        rs = rs.map { |r| strings_matching(r, raw_rules, cache) }
        rs[0].product(*rs[1..]).map(&:join)
      }.freeze
    end
  end
end

verbose = if ARGV.delete('-v2')
  2
elsif ARGV.delete('-v1')
  1
elsif ARGV.delete('-v')
  0
else
  nil
end

raw_rules = ARGF.take_while { |l| !l.chomp.empty? }.to_h { |line|
  num, rule = line.chomp.split(': ')
  num = Integer(num)
  if rule.start_with?(?")
    [num, rule.split(?")[1].freeze]
  else
    alts = rule.split(' | ')
    [num, alts.map { |alt| alt.split.map(&method(:Integer)).freeze }.freeze]
  end
}.freeze

messages = ARGF.map { |l| l.chomp!; raise "#{l} should only be a and b" unless l.match?(/\A[ab]+\z/); l.freeze }.freeze

list_strings_matching([0], raw_rules) if verbose && raw_rules[0] != [[8, 11]]
r = Regexp.new(?^ + rule_regex(0, raw_rules) + ?$)
messages.each { |m| puts "#{m} #{r.match?(m)}" } if verbose == 1
puts messages.count { |m| r.match?(m) }

def match0_recursive_regex(messages, raw_rules, verbose: nil)
  begin
    cache = {}
    rule42 = rule_regex(42, raw_rules, cache)
    rule31 = rule_regex(31, raw_rules, cache)
  rescue
    return nil
  end

  matches = list_strings_matching([42, 31], raw_rules) if verbose

  cache = {
    8 => "(?:#{rule42})+".freeze,
    # https://stackoverflow.com/questions/19486686/recursive-nested-matching-pairs-of-curly-braces-in-ruby-regex
    11 => "(#{rule42}(?:\\g<1>)*#{rule31})".freeze
  }

  r = Regexp.new(?^ + rule_regex(0, raw_rules, cache) + ?$)
  if verbose == 2
    m42, m31 = matches
    sizes = (m42 + m31).map(&:size)
    slice = sizes.uniq.size == 1 ? sizes[0] : nil
    messages.each { |m|
      puts "#{m} #{r.match?(m)}"
      if slice
        puts m.chars.each_slice(slice).map { |slc|
          slc = slc.join
          matching_rules = [[42, m42], [31, m31]].filter_map { |n, ms| n if ms.include?(slc) }
          disp = case matching_rules.size
          when 2; :both
          when 1; matching_rules[0]
          when 0; :none
          end
          "%-#{slice}s" % [disp]
        }.join
      end
    }
  end
  messages.count { |m| m.match?(r) }
end

puts match0_recursive_regex(messages, raw_rules, verbose: verbose) || 'no part 2'

# export for benchmark
@raw_rules = raw_rules
@messages = messages
