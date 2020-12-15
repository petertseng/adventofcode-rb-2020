# modified Van Eck sequence

ROUNDS = 30_000_000

def run(t, spoken_now, last_spoken_at, limit)
  while (t += 1) < limit
    tprev = last_spoken_at[spoken_now]
    last_spoken_at[spoken_now] = t
    spoken_now = tprev ? t - tprev : 0
  end
  spoken_now
end

initial = (ARGV.none? { |a| /^[0-9]+(,[0-9]+)*$/.match?(a) } ? ARGF.read : ARGV.join(?,)).split(?,).map { Integer(_1, 10) }.freeze

last_spoken_at = Array.new(ROUNDS)
initial.each_with_index { |i, t|
  last_spoken_at[i] = t + 1
}
spoken_now = (i = initial[0..-2].rindex(initial[-1])) ? initial.size - 1 - i : 0

puts spoken_now = run(initial.size, spoken_now, last_spoken_at, 2020)
puts run(2019, spoken_now, last_spoken_at, ROUNDS)
