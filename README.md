# adventofcode-rb-2020

[![Build Status](https://travis-ci.org/petertseng/adventofcode-rb-2020.svg?branch=master)](https://travis-ci.org/petertseng/adventofcode-rb-2020)

For the sixth year in a row, it's the time of the year to do [Advent of Code](http://adventofcode.com) again.

Huh, how long can Eric keep this up...?

The solutions are written with the following goals, with the most important goal first:

1. **Speed**.
   Where possible, use efficient algorithms for the problem.
   Solutions that take more than a second to run are treated with high suspicion.
   This need not be overdone; micro-optimisation is not necessary.
2. **Readability**.
3. **Less is More**.
   Whenever possible, write less code.
   Especially prefer not to duplicate code.
   This helps keeps solutions readable too.

All solutions are written in Ruby.
Features from 2.7.x will be used, with no regard for compatibility with past versions.
`Enumerable#to_h` with block is anticipated to be the most likely reason for incompatibility.

# Input

In general, all solutions can be invoked in both of the following ways:

* Without command-line arguments, takes input on standard input.
* With command-line arguments, reads input from the named files (- indicates standard input).

Some may additionally support other ways:

* Day 13 (Shuttle Search): If providing a comma-separated list on ARGV, will compute only part 2 on that list, skipping part 1.
* Day 15 (Rambunctious Recitation): Can also pass comma-separated or space-separated list of numbers on ARGV.
* Day 23 (Crab Cups): Can also pass the cups on ARGV.
* Day 25 (Combo Breaker): Can also pass the public keys on ARGV.

# Highlights

Favourite problems:

* Day 12 (Rain Risk): Fun way to reduce code duplication between the two parts (the two parts each have a movable object and a turnable object).
* Day 18 (Operation Order): Not because I did well on it but because of its educational value in parsing.

Interesting approaches:

* Day 08 (Handheld Halting): Construct set of instructions that halt, then look for an instruction that can flip such that you land in that set.
* Day 11 (Seating System): Use reasoning about seats that must permanently remain empty or occupied.
* Day 12 (Rain Risk): Fun way to reduce code duplication between the two parts (the two parts each have a movable object and a turnable object).
* Day 13 (Shuttle Search): Supports bus intervals that are not pairwise coprime.
* Day 17 (Conway Cubes): Exploit symmetries to unlock reasonable runtimes on higher dimensions.

# Takeaways

* Day 01 (Report Repair): Oops, make sure you know what each potential parsing line of your template does.
  Used the "array of ints for each line" parser instead of the "one int for each line" parser, leading to no sums being found.
  (Also an outage prevented submitting on time)
* Day 03 (Toboggan Trajectory): Read the bolded portion carefully and assume nothing!
  Even though the problem statement says "Determine the number of trees... for each of the following slopes" and you'd think that would be a summation, the problem statement clearly requested a product in bolded text.
* Day 04 (Passport Processing): Don't become so used to parsing the input one line at a time that you miss an obvious approach.
  Reading the entire input and splitting by `"\n\n"` was a far simpler approach than the one taken on release, which was:
  Going line by line, accumulating the lines, adding them when you find an empty line, and then having to remember to add the very last accumulated group after iteration is over.
* Day 05 (Binary Boarding): Don't forget to check the answer is reasonable for the problem.
  Reading "the seats with IDs +1 and -1 from yours will be in your list" meant this code was written:

  ```ruby
  (seats.min..seats.max).find { |x| seats.include?(x - 1) && seats.include?(x + 1) }
  ```

  This is wildly incorrect since it simply selects `seats.min + 1`. Need to check `!seats.include?(x)` as well.
* Day 06 (Custom Customs): No real takeaway here except maybe to be careful about typing the answer correctly.
  I attempted to submit the answer via `curl`, but it hung (others were experiencing unpredictable issues that day as well).
  I tried to submit via the website but transposed two digits, and the one minute penalty cost almost exactly 50 points.
  Simply retrying the `curl` may have succeeded.
* Day 08 (Handheld Halting): Skimming the problem statement caused implementing extra unnecessary logic.
  The problem statement has clearly stated that since there's no control flow, any attempt to execute an instruction twice constitutes a loop.
  Missing this and instead writing code to only run for N instructions wasted time.
* Day 09 (Encoding Error): Even if doing a brute-force approach just for the leaderboard, make sure it's bounded.
  Code was of the general form:

  ```ruby
    nums.each_index { |i|
      2.step { |winsize|
        if nums[i, winsize].sum == target
          ...
        end
      }
    }
  ```

  This is incorrect because winsize increases without bound, summing the same elements over and over uselessly.
  It needs to be bounded above by the size of the array, such as `(2..nums.size).each { |winsize| ... }`.
  Perhaps printing out the sums would have been helpful.
* Day 10 (Adapter Array): Read problem statement carefully and don't assume the problem is harder than it is.
  Problem statement says the adapter can only accept **lower** joltages, not higher.
  Therefore, to use all the adapters must require taking them in ascending order.
  Instead, wasted time with BFS (no good, BFS finds a shortest path but we need a longest) or Hamiltonian (maybe workable if the neighbour function was understood correctly, but still time-wasting).
* Day 11 (Seating System): Don't prematurely optimise.
  If caching, don't let cached values collide.
  Tried to cache `seat_in_direction`, but forgot to include `dy` and `dx` in the cache key and instead only used `y` and `x`, which is patently wrong.
  Caching wasn't even necessary - the code would have run fast enough to get on the leaderboard (a few seconds) without it.
* Day 13 (Shuttle Search): When in doubt, trying on the example would be helpful.
  Looking at `[1068781 % 7, 1068781 % 13, 1068781 % 59, 1068781 % 31, 1068781 % 19]` would have revealed crucial information (the remainders being sought are not `[0, 1, 4, 6, 7]`, but instead the negatives of those).
* Day 15 (Rambunctious Recitation): When there is a high chance of an off-by-one error, it's worth checking on the example input.
  Not making an off-by-one error on part one still wouldn't have gotten points for part one but would be about 30 more points for part two.
* Day 16 (Ticket Translation): Despite my very best efforts to avoid mutation bugs, it still happened.
  Buggy code was of the general form:

  ```ruby
  fields[0], i = fields_for_index.each_with_index.find { |fs, _| fs.size == 1 }
  confirmed_fields[i] = fields[0]
  fields_for_index.each { |fs| fs.delete(fields[0]) }
  ```

  Partway through the iteration, `fields[0]` will become `nil` as it's deleted from itself.
  Needed to set `field = fields[0]`.
* Day 17 (Conway Cubes): Do **not** write `dx * dy * dz == 0` as a "shortcut" for `dx == 0 && dy == 0 && dz == 0`; it's wrong (it does `||` instead).
  Use `[-1, 0, 1].repeated_permutation(3) - [Array.new(3, 0)]` instead of nesting loops to loop over neighbours.
* Day 18 (Operation Order): While it's unfortunate that my first attempt to recursively parse turned out to be right-associative, if I had been in a get-it-done mindset, I would have realised that reversing the string would allow it to work. Passing blocks around can achieve left-associativity, but not easy to think of in the moment.
  There are solutions that redefined operators and used eval, and while they would have been good for points, they would not really have been of educational value.
* Day 19 (Monster Messages): In the get-it-done spirit, to get the leaderboard points, I simply wrote `42 31 | 42 42 31 31 | 42 42 42 31 31 31 | ...` a sufficient number of times to match all messages in the input.
  However, later on, I learned about recursive capture groups.
* Day 20 (Jurassic Jigsaw): Reading comprehension! Removing each tile's border is not the same as removing the entirety of all the border tiles of the image! That would have made the example make no sense.
* Day 23 (Crab Cups): Better estimation of whether a problem is still solvable using the right data structure. Was aware that using a linked list would be possible, but incorrectly guessed that 10 million iterations is so many that this was a pattern-finding and cleverness check intead of a datastructure check.
* Day 24 (Lobby Layout): I think I should consider using less error-prone parsing methods. I was parsing it character-by-character at first and accidentally appended an 'e' whenever a 'w' was encountered, whereas `scan(/[ns]?[ew]/)` would have been able to extract every single direction with no problems.
* Day 25 (Combo Breaker): Learned about discrete logarithms!

# Posting schedule and policy

Before I post my day N solution, the day N leaderboard **must** be full.
No exceptions.

Waiting any longer than that seems generally not useful since at that time discussion starts on [the subreddit](https://www.reddit.com/r/adventofcode) anyway.

Solutions posted will be **cleaned-up** versions of code I use to get leaderboard times (if I even succeed in getting them), rather than the exact code used.
This is because leaderboard-seeking code is written for programmer speed (whatever I can come up with in the heat of the moment).
This often produces code that does not meet any of the goals of this repository (seen in the introductory paragraph).

# Past solutions

The [index](https://github.com/petertseng/adventofcode-common/blob/master/index.md) lists all years/languages I've ever done (or will ever do).
