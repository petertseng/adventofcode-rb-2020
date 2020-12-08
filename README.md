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

* None yet

# Highlights

Favourite problems:

* None yet.

Interesting approaches:

* Day 08 (Handheld Halting): Construct set of instructions that halt, then look for an instruction that can flip such that you land in that set.

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

# Posting schedule and policy

Before I post my day N solution, the day N leaderboard **must** be full.
No exceptions.

Waiting any longer than that seems generally not useful since at that time discussion starts on [the subreddit](https://www.reddit.com/r/adventofcode) anyway.

Solutions posted will be **cleaned-up** versions of code I use to get leaderboard times (if I even succeed in getting them), rather than the exact code used.
This is because leaderboard-seeking code is written for programmer speed (whatever I can come up with in the heat of the moment).
This often produces code that does not meet any of the goals of this repository (seen in the introductory paragraph).

# Past solutions

The [index](https://github.com/petertseng/adventofcode-common/blob/master/index.md) lists all years/languages I've ever done (or will ever do).
