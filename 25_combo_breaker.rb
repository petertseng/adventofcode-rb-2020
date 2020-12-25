MOD = 20201227

# https://en.wikipedia.org/wiki/Discrete_logarithm
# there are many algorithms; for now I picked a simple-to-understand one.
# https://en.wikipedia.org/wiki/Baby-step_giant-step

def discrete_log(g, h, mod)
  m = (mod ** 0.5).ceil

  j_of_aj = {1 => 0}
  current = 1
  (1...m).each { |j|
    j_of_aj[current = (current * g) % mod] = j
  }

  am = g.pow(mod - m - 1, mod)

  gamma = h
  m.times { |i|
    if (j = j_of_aj[gamma])
      return i * m + j
    end
    gamma = (gamma * am) % mod
  }
  raise 'not found'
end

verbose = ARGV.delete('-v')
pubkeys = ARGV.size >= 2 ? ARGV : ARGF.take(3)
raise "bad #{pubkeys}" if pubkeys.size != 2

pubkey1, pubkey2 = pubkeys.map(&method(:Integer))
privkey1 = discrete_log(7, pubkey1, MOD)
if verbose
  puts "card privkey #{privkey1}"
  puts "door privkey #{discrete_log(7, pubkey2, MOD)}"
end
puts pubkey2.pow(privkey1, MOD)
