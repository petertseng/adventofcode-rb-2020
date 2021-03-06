module Search
  module_function

  def path_of(prevs, n)
    path = [n]
    current = n
    while (current = prevs[current])
      path.unshift(current)
    end
    path
  end

  def bfs(start, neighbours:, goal:)
    current_gen = [start]
    prev = {start => nil}
    goals = {}
    gen = -1

    until current_gen.empty?
      gen += 1
      next_gen = []
      while (cand = current_gen.shift)
        goals[cand] = gen if goal[cand]

        neighbours[cand].each { |neigh|
          next if prev.has_key?(neigh)
          prev[neigh] = cand
          next_gen << neigh
        }
      end
      current_gen = next_gen
    end

    {
      found: !goals.empty?,
      gen: gen,
      goals: goals,
      #path: goals.min.then { |g| g && path_of(prev, goals.min) },
      prev: prev,
    }
  end
end
