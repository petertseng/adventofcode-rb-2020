def depart_matching_id(t0, buses)
  buses.map { |busid| [-t0 % busid, busid] }.min_by(&:first)
end

# https://brilliant.org/wiki/chinese-remainder-theorem/
# Slightly more useful than https://en.wikipedia.org/wiki/Modular_multiplicative_inverse#Applications
# Much more useful than https://en.wikipedia.org/wiki/Chinese_Remainder_Theorem
#
# This one is just acting on one bus at a time,
# which has the interesting ability of showing the constraint added by each bus.
#
# we start with step = 1, t0 = 0, and for each bus, are looking for t = (t0 + step * k) where
# t % busid[i] == (-bus_offset[i]) % busid[i]
# So solve for k first.
# (t0 + step * k) % busid[i] == (-bus_offset[i]) % busid[i]
# (step * k) % busid[i] == (-bus_offset[i] - t0) % busid[i]
# k % busid[i] == (-bus_offset[i] - t0) * invmod(step, busid[i]) % busid[i]
#
# Now substitute k back in, and we have our next t in terms of t0 and step.
# And next step is the lcm of step and bus's busid.
# t = t0 + step * ((-bus_offset[i] - t0) * invmod(step, busid[i]) % busid[i])
#
# What if not all busid are coprime? Then instead:
#
# we start with step = 1, t0 = 0, and for each bus, are looking for t = (t0 + step * k) where
# t % busid[i] == (-bus_offset[i]) % busid[i]
# or equivalently,
# t + busid[i] * j == -bus_offset[i]
# t0 + step * k + busid[i] * j == -bus_offset[i]
# step * k + busid[i] * j == -bus_offset[i] - t0
#
# Recall the extended Euclidean algorithm, which can find
# ax + by == gcd(a, b)
# Now we can use the extended Euclidean algorithm to find values for x, y and gcd(a, b),
# by giving it the inputs a = step and b = busid.
#
# If -bus_offset[i] - t0 is NOT a multiple of gcd(a, b), there is no solution.
# If it is, we can scale up x and y by (-bus_offset[i] - t0) / gcd(step, busid[i]) to get k and j.
# k = x * (-bus_offset[i] - t0) / gcd(step, busid[i]).
#
# (unsure about this step?)
# Recall that we still need:
# step * k + busid[i] * y == -bus_offset[i] - t0
# We can discard y (and j) by reintroducing modulus
# step * k % busid[i] == (-bus_offset[i] - t0) % busid[i]
# So k = (x * (-bus_offset[i] - t0) % busid[i]) / gcd(step, busid[i])
#
# t = t0 + step * ((x * (-bus_offset[i] - t0) % busid[i]) / gcd(step, busid[i]))
#
# So that's what the below does.
# To compare the difference between the two versions (must be coprime vs general),
# see benchmark directory.
def depart_matching_offset(buses)
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

# returns [gcd, x]
# a * x + n * y == gcd
# Doesn't return y, because I don't need it.
#
# the inverse of a modulo n would be:
# gcd > 1 ? nil : x % n
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

def buses(s)
  s.split(?,).filter_map.with_index { |busid, i|
    [Integer(busid), i].freeze if busid != ?x
  }.freeze
end

verbose = ARGV.delete('-v')
if ARGV[0]&.include?(?,)
  t0 = 0
  buses = buses(ARGV[0])
else
  t0 = Integer(ARGF.readline)
  buses = buses(ARGF.readline)
end

wait, busid = depart_matching_id(t0, buses.map(&:first))
puts "#{"#{wait} * (#{busid}) = " if verbose}#{wait * busid}"

ts = depart_matching_offset(buses)
puts "LCM #{buses.reduce(1) { |a, (busid, _)| a.lcm(busid) }}" if verbose
p verbose ? ts : ts.last
