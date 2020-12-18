# The most obvious way to apply operators in recursive-descent approaches results in right-to-left application.
# To deal with this, reverse the string and reverse all parentheses.
# (Note that if the string had multi-digit numbers, their value of course needs to be preserved)
#
# To achieve left-to-right parsing,
# can pass a block telling expressions to your right what to do with values they parse.
# This approach is in the benchmark directory, along with others.

def rec_desc_ltr_using_rtl(expr, verbose: false)
  ops = [%w(+ *).map(&:freeze).freeze].freeze
  rec_desc_rtl_rev_strip(expr, ops, verbose: verbose)
end

def rec_desc_add_before_mul_using_rtl(expr, verbose: false)
  ops = [
    # parse lowest precedence first
    [?*.freeze].freeze,
    [?+.freeze].freeze,
  ].freeze
  rec_desc_rtl_rev_strip(expr, ops, verbose: verbose)
end

def rec_desc_rtl_rev_strip(expr, ops, verbose: false)
  no_spaces = expr.delete(' ').reverse.tr('()', ')(')
  val, pos = op_expr_rtl(no_spaces, 0, ops, ops, verbose: verbose)
  raise "unparsed #{pos}" if pos != no_spaces.size
  val
end

def op_expr_rtl(expr, pos, op_groups, current_op_groups, verbose: false)
  v1, pos = if current_op_groups[1]
    op_expr_rtl(expr, pos, op_groups, current_op_groups[1..], verbose: verbose)
  else
    term_rtl(expr, pos, op_groups, verbose: verbose)
  end

  c = expr[pos]
  if current_op_groups[0].include?(c)
    v2, pos = op_expr_rtl(expr, pos + 1, op_groups, current_op_groups, verbose: verbose)
    puts "#{v1} #{c} #{v2}" if verbose
    [v1.send(c, v2), pos]
  elsif c.nil? || ')+*'.include?(c)
    [v1, pos]
  else
    raise "bad char #{c} at #{pos} in #{expr}"
  end
end

def term_rtl(expr, pos, op_groups, verbose: false)
  case c = expr[pos]
  when ?(
    v, close_paren = op_expr_rtl(expr, pos + 1, op_groups, op_groups, verbose: verbose)
    raise "#{close_paren} was #{expr[close_paren]} not close paren" if expr[close_paren] != ?)
    [v, close_paren + 1]
  when /\d/
    [Integer(c), pos + 1]
  end
end

expressions = ARGF.map(&:chomp).map(&:freeze).freeze

puts expressions.sum { |expr| rec_desc_ltr_using_rtl(expr) }
puts expressions.sum { |expr| rec_desc_add_before_mul_using_rtl(expr) }

# Export for benchmark
@expressions = expressions
