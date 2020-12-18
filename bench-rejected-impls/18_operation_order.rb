require 'benchmark'

require_relative '../18_operation_order'

bench_candidates_1 = %i(rec_desc_ltr_using_rtl)
bench_candidates_2 = %i(rec_desc_add_before_mul_using_rtl)

# For amusement and reminiscence,
# I preserve the hand-crafted solutions that I wrote initially.

# Since there's no precedence, can immediately apply all ops as they come in.
bench_candidates_1 << def ltr_immediately_apply(expr, verbose: false)
  expr = expr.delete(' ')

  stack = [{val: nil, op: nil}]

  apply = ->v {
    last = stack[-1]
    if last[:val] && last[:op]
      puts "#{stack[-1][:val]} #{stack[-1][:op]} #{v}" if verbose
      last[:val] = last[:val].send(last[:op], v)
      last[:op] = nil
    else
      raise "improperly replaced #{last} #{expr}" if last[:val] || last[:op]
      last[:val] = v
    end
  }

  expr.each_char { |c|
    case c
    when ?(
      stack << {val: nil, op: nil}
    when ?)
      last = stack.pop
      raise "bad paren #{last} #{expr}" if !last[:val] || last[:op]
      apply[last[:val]]
    when /\d/
      apply[Integer(c)]
    when ?+, ?*
      last = stack[-1]
      raise "bad op #{c} #{last} #{expr}" if !last[:val] || last[:op]
      last[:op] = c
    else raise "bad #{c} in #{expr}"
    end
  }

  raise "unclosed paren #{stack} in #{expr}" if stack.size > 1
  raise "leftover op #{stack[-1]} in #{expr}" if stack[-1][:op]

  stack[-1][:val]
end

# Couldn't use the stack-based solution for part 2,
# so used string replacement one instead.
# And then I went back and made one for part 1 too.
bench_candidates_1 << def string_replacement_ltr(expr, depth = 0, verbose: false)
  expr = expr.delete(' ') if depth == 0
  lpad = '    ' * depth

  while (rparen = expr.index(?)))
    # Looking forward from the first left parenthesis is prone to nesting problems like ((1 + 2) + 3)
    # Looking backward from the first right parenthesis, though, is totally fine.
    lparen = expr.rindex(?(, rparen)
    replace = expr[(lparen + 1)...rparen]
    replacement = string_replacement_ltr(replace, depth + 1, verbose: verbose)
    expr[lparen..rparen] = replacement.to_s
    puts "#{lpad}#{replace} = #{replacement}, now #{expr}" if verbose
  end

  while (add_or_mul = expr[/(\d+)(\+|\*)(\d+)/])
    expr[add_or_mul] = v = Integer($1).send($2, Integer($3)).to_s
    puts "#{lpad}#$1 #$2 #$3 = #{v}; now #{expr}" if verbose
  end

  Integer(expr)
end

bench_candidates_2 << def string_replacement_add_before_mul(expr, verbose: false)
  expr = expr.dup

  while expr.include?(' ')
    # We can always do addition.
    if (add = expr[/(\d+) \+ (\d+)/])
      expr[add] = v = (Integer($1) + Integer($2)).to_s
      puts "#$1 + #$2 = #{v}; now #{expr}" if verbose
      next
    end

    if expr.include?(?()
      # We can remove parentheses around a single number.
      if (paren = expr[/\((\d+)\)/])
        expr[paren] = $1
        puts "remove paren around #$1, now #{expr}" if verbose
        next
      end

      # There still are parentheses, but we can't take any of the above actions.
      # We have to do a multiplication inside a pair of parentheses.
      # We must choose one where multiplication is the only operation.
      if (mult = expr[/\((\d+) \* (\d+)((?: \* \d+)*)\)/])
        v = Integer($1) * Integer($2)
        expr[$&] = "(#{v}#$3)"
        puts "#$& -> (#{v}#$3); now #{expr}" if verbose
        next
      end
    else
      # There are no parentheses, so it's safe to do any multiplication.
      if (mult = expr[/(\d+) \* (\d+)/])
        expr[mult] = v = (Integer($1) * Integer($2)).to_s
        puts "#$1 * #$2 -> #{v}; now #{expr}" if verbose
        next
      end
    end
  end

  Integer(expr)
end

# Guess I didn't think of doing it this way at the time (do the parentheses first...)
bench_candidates_2 << def string_replacement_add_before_mul2(expr, depth = 0, verbose: false)
  expr = expr.delete(' ') if depth == 0
  lpad = '    ' * depth

  while (rparen = expr.index(?)))
    # Looking forward from the first left parenthesis is prone to nesting problems like ((1 + 2) + 3)
    # Looking backward from the first right parenthesis, though, is totally fine.
    lparen = expr.rindex(?(, rparen)
    replace = expr[(lparen + 1)...rparen]
    replacement = string_replacement_add_before_mul2(replace, depth + 1, verbose: verbose)
    expr[lparen..rparen] = replacement.to_s
    puts "#{lpad}#{replace} = #{replacement}, now #{expr}" if verbose
  end

  while (add = expr[/(\d+)\+(\d+)/])
    expr[add] = v = (Integer($1) + Integer($2)).to_s
    puts "#{lpad}#$1 + #$2 = #{v}; now #{expr}" if verbose
  end

  while (mul = expr[/(\d+)\*(\d+)/])
    expr[mul] = v = (Integer($1) * Integer($2)).to_s
    puts "#{lpad}#$1 * #$2 = #{v}; now #{expr}" if verbose
  end

  Integer(expr)
end

# https://en.wikipedia.org/wiki/Shunting-yard_algorithm
# This one is standard literature, but a little slower.

bench_candidates_1 << def shunting_yard_ltr(expr, verbose: false)
  shunting_yard(expr, Hash.new(0).freeze)
end

bench_candidates_2 << def shunting_yard_add_before_mul(expr, verbose: false)
  shunting_yard(expr, {?+ => 1, ?* => 0}.freeze)
end

def shunting_yard(expr, prec, left = Hash.new(true).freeze)
  expr = expr.delete(' ')

  nums = []
  ops = []

  popop = -> {
    num1, num2 = nums.pop(2)
    nums << num1.send(ops.pop, num2)
  }

  expr.each_char { |c|
    case c
    when /\d/
      # Note that there are never any two-digit numbers!
      nums << Integer(c)
    when ?+, ?*
      popop[] while (op = ops[-1]) && op != ?( && (prec[op] > prec[c] || prec[op] == prec[c] && left[c])
      ops << c.freeze
    when ?(
      ops << c.freeze
    when ?)
      while ops[-1] != ?(
        raise "bad parens #{expr}" if ops.empty?
        popop[]
      end
      raise "bad parens #{expr}" if ops.pop != ?(
    else "bad #{c} in #{expr}"
    end
  }

  popop[] until ops.empty?
  raise "not enough ops #{expr}" if nums.size > 1
  raise "not enough nums #{expr}" if nums.empty?

  nums[0]
end

# As mentioned, to achieve left-to-right parsing with recursive descent,
# need to pass some blocks around.

bench_candidates_1 << def rec_desc_ltr(expr, verbose: false)
  ops = [%w(+ *).map(&:freeze).freeze].freeze
  rec_desc_ltr_strip(expr, ops, verbose: verbose)
end

bench_candidates_2 << def rec_desc_add_before_mul(expr, verbose: false)
  ops = [
    # parse lowest precedence first
    [?*.freeze].freeze,
    [?+.freeze].freeze,
  ].freeze
  rec_desc_ltr_strip(expr, ops, verbose: verbose)
end

def rec_desc_ltr_strip(expr, ops, verbose: false)
  no_spaces = expr.delete(' ')
  val, pos = op_expr_ltr(no_spaces, 0, ops, ops, verbose: verbose, &:itself)
  raise "unparsed #{pos}" if pos != no_spaces.size
  val
end

def op_expr_ltr(expr, pos, op_groups, current_op_groups, verbose: false)
  v1, pos = if current_op_groups[1]
    op_expr_ltr(expr, pos, op_groups, current_op_groups[1..], verbose: verbose, &:itself)
  else
    term_ltr(expr, pos, op_groups, verbose: verbose)
  end
  v2 = yield v1

  c = expr[pos]
  if current_op_groups[0].include?(c)
    op_expr_ltr(expr, pos + 1, op_groups, current_op_groups, verbose: verbose) { |v3|
      puts "#{v2} #{c} #{v3}" if verbose
      v2.send(c, v3)
    }
  elsif c.nil? || ')+*'.include?(c)
    [v2, pos]
  else
    raise "bad char #{c} at #{pos} in #{expr}"
  end
end

# term_ltr and term_rtl are exactly alike,
# other than which of op_expr_ltr and op_expr_rtl they call
# (and that term_ltr also needs to pass a block)
# Could have pass it in as a symbol and using send but it caused unnecssary slowdown,
# which made benchmark unfair.
def term_ltr(expr, pos, op_groups, verbose: false)
  case c = expr[pos]
  when ?(
    v, close_paren = op_expr_ltr(expr, pos + 1, op_groups, op_groups, verbose: verbose, &:itself)
    raise "#{close_paren} was #{expr[close_paren]} not close paren" if expr[close_paren] != ?)
    [v, close_paren + 1]
  when /\d/
    [Integer(c), pos + 1]
  end
end

expressions = @expressions
[
  bench_candidates_1,
  bench_candidates_2,
].each { |bench_candidates|
  results = {}

  Benchmark.bmbm { |bm|
    bench_candidates.each { |f|
      bm.report(f) { results[f] = expressions.sum(&method(f)) }
    }
  }

  # Obviously the benchmark would be useless if they got different answers.
  if results.values.uniq.size != 1
    results.each { |k, v| puts "#{k} #{v}" }
    expressions.each { |expr|
      # Find an expr where they differ.
      expr_results = bench_candidates.to_h { |f| [f, send(f, expr)] }
      if expr_results.values.uniq.size != 1
        puts "#{expr}:"
        expr_results.each { |k, v|
          puts "#{k} #{v}"
          send(k, expr, verbose: true)
        }
      end
    }
    raise 'differing answers'
  end
}
