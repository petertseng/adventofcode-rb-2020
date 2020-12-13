# https://www.reddit.com/r/adventofcode/comments/kc94h1/2020_day_13_part_2_generalization/
# https://www.reddit.com/r/adventofcode/comments/kccm2d/day_13_part_2_does_your_code_work_with_2x43/
# maybe https://gist.github.com/ephemient/d6b11a869593e22ea15a9199b2c794c3 helps understand

cases = {
  '14,x,x,x,335,x,x,x,39,x,x,x,x,x,x,x,x,187,19' => 124016326,
  '73,x,x,x,x,x,x,67,x,25,x,x,x,x,x,343,x,x,9' => 369373941,
  '77,97,x,x,x,x,x,x,57,x,x,x,x,x,62,x,x,x,x,78,x,x,x,65' => nil,
  '7,24,x,x,9,13,x,x,x,20,x,x,x,33' => 173831,
  '71,x,x,x,x,x,x,x,375,x,x,x,x,x,x,x,x,726,x,x,x,x,x,76,67,53,x,x,x,94' => 21428909746117,
  '59,x,x,x,117,x,x,x,x,x,x,x,x,x,x,x,189,x,61,x,x,137' => nil,
  '173,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,1287,x,x,2173,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,1275,x,x,x,x,x,x,x,x,x,x,x,671,x,x,x,x,x,x,2674' => 27208285429450535,
  '1997,x,x,x,x,x,x,1747,x,x,x,x,x,2003,x,x,x,x,x,x,1883,x,x,x,x,x,1667,x,x,x,x,x,x,x,1701' => 4756544012204563475,
  '2,x,4,3' => 6,
}

cases.each { |c, ans|
  lines = `echo "0\n#{c}" | ruby 13*.rb 2>/dev/null`.lines
  answer = if lines.size == 2
    Integer(lines[-1])
  else
    nil
  end
  if ans != answer
    puts "#{c} bad, should be #{ans} not #{answer}"
  end
}
puts "#{cases.size} cases"
