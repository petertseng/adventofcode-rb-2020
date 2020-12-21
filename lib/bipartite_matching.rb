module BipartiteMatching
  module_function

  # Map with keys being left, values being the rights that could match it.
  def match(rights_for_left, verbose: false)
    rights_for_left = rights_for_left.transform_values(&:dup)

    confirmed_right_for_left = {}

    while confirmed_right_for_left.size < rights_for_left.size
      progress = false
      # We only need one or the other, but will keep both in case code is needed later.
      while (l, r = naked_single(rights_for_left))
        puts "naked single: #{l} must be #{r}" if verbose
        confirmed_right_for_left[l] = r
        rights_for_left.each_value { |rs| rs.delete(r) }
        progress = true
      end
      while (l, r = hidden_single(rights_for_left))
        puts "hidden single: #{l} must be #{r}" if verbose
        confirmed_right_for_left[l] = r
        rights_for_left.delete(l)
        progress = true
      end
      break unless progress
    end

    confirmed_right_for_left
  end

  def naked_single(rights_for_left)
    (l, rs = rights_for_left.find { |l, rs| rs.size == 1 }) && [l, rs.first]
  end

  def hidden_single(rights_for_left)
    # TODO: Having to regenerate lefts_for_right every single time is unnecessary.
    # But since hidden_single is never actually called, I don't actually care.
    # And I didn't want to have to update lefts_for_right in the solving loop.
    lefts_for_right = invert(rights_for_left)
    (r, ls = lefts_for_right.find { |r, ls| ls.size == 1 }) && [ls.first, r]
  end

  def invert(rights_for_left)
    rights_for_left.each_with_object(Hash.new { |h, k| h[k] = [] }) { |(l, rs), h|
      rs.each { |r| h[r] << l }
    }
  end
end
