def game(cups, ncups:, after1:, rounds:)
  right = Array.new(ncups + 1) { |i| i + 1 }
  cups.each_cons(2) { |l, r| right[l] = r }
  if ncups > cups.size
    right[cups[-1]] = cups.size + 1
    right[ncups] = cups[0]
  else
    right[cups[-1]] = cups[0]
  end

  current = cups[0]

  t = 0
  while (t += 1) <= rounds
    pickup1 = right[current]
    pickup2 = right[pickup1]
    pickup3 = right[pickup2]
    after_pickup = right[pickup3]

    dest = current == 1 ? ncups : current - 1
    dest = dest == 1 ? ncups : dest - 1 while dest == pickup1 || dest == pickup2 || dest == pickup3

    right_of_dest = right[dest]

    right[current] = after_pickup
    right[dest] = pickup1
    right[pickup3] = right_of_dest

    current = after_pickup
  end

  current = 1
  after1.times.map { current = right[current] }
end

verbose = ARGV.delete('-v')
cups = Integer(!ARGV.empty? && ARGV[0].match?(/^\d+$/) ? ARGV[0] : ARGF.read).digits.reverse.freeze
rounds = if (arg = ARGV.find { |a| a.start_with?('-t') })
  ARGV.delete(arg)
  Integer(arg[2..])
else
  10_000_000
end
ncups = if (arg = ARGV.find { |a| a.start_with?('-c') })
  ARGV.delete(arg)
  Integer(arg[2..])
else
  1_000_000
end

puts game(cups, ncups: cups.size, after1: cups.size - 1, rounds: 100).join
after1 = game(cups, ncups: ncups, after1: 2, rounds: rounds)
puts "#{"#{after1.join(' * ')} = " if verbose}#{after1.reduce(:*)}"
