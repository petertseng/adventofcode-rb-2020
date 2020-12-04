def year_between(l, r)
  ->s { (l..r).cover?(Integer(s)) }
end

VALID_EYES = %w[amb blu brn gry grn hzl oth].map(&:freeze).freeze
VALID_PASSPORT = {
  byr: year_between(1920, 2002),
  iyr: year_between(2010, 2020),
  eyr: year_between(2020, 2030),
  hgt: ->hgt {
    if hgt.end_with?('cm')
      (150..193).cover?(Integer(hgt[0...-2]))
    elsif hgt.end_with?('in')
      (59..76).cover?(Integer(hgt[0...-2]))
    end
  },
  hcl: /^#[0-9a-f]{6}$/,
  ecl: ->s { VALID_EYES.include?(s) },
  pid: /^\d{9}$/,
}.freeze

verbose = if ARGV.delete('-vv')
  2
elsif ARGV.delete('-v')
  1
else
  0
end
show_accepted = ARGV.delete('-a')
show_denied = ARGV.delete('-d')
accepted = Hash.new { |h, k| h[k] = [] }
denied = Hash.new { |h, k| h[k] = [] }

passports = ARGF.each("\n\n").map { |passport_lines|
  fields = passport_lines.split.to_h { |kv|
    k, v = kv.split(?:)
    [k.to_sym, v.freeze]
  }.freeze

  # true: present and valid
  # false: present and invalid
  # nil: absent
  valids = VALID_PASSPORT.to_h { |k, f|
    v = begin
      (s = fields[k]) && !!(f === s)
    rescue
      # This never actually happens in the Advent of Code inputs
      # (would happen if there were a non-numeric value in a numeric field)
      # but we should probably say false for that field...
      # for now, I'll just reraise
      puts passport_lines
      raise
    end
    # Can't sort nil against anything else, so can't directly put it in denied.
    # If I wanted, I could put it in and adjust the sort appropriately,
    # but not motivated enough.
    (v ? accepted : denied)[k] << s unless v.nil?
    [k, v]
  }.freeze

  {
    fields: fields,
    optional_fields: (fields.keys - VALID_PASSPORT.keys).freeze,
    valids: valids,
    complete: valids.values.none?(nil),
    valid: valids.values.all?(true),
  }.freeze
}.freeze

[
  [show_accepted, accepted, :accepted],
  [show_denied, denied, :denied],
].each { |show, h, name|
  next unless show
  h.each { |k, vs|
    puts "#{name} #{k} #{vs.size}"
    vs.tally.sort.each { |v, count|
      puts "    #{name} #{k} #{v} x#{count}"
    }
  }
}

puts passports.count { |p| p[:complete] }
puts passports.count { |p| p[:valid] }
passports.each_with_index { |p, i|
  if verbose > 1
    puts "#{i} #{p[:fields]}"
    puts "#{i} #{p[:valids]}"
  end
  puts "#{i} #{p[:valid]}"
} if verbose > 0
