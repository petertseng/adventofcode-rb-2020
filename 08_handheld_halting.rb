require_relative 'lib/search'
require 'set'

def run(insts, terminating_pcs: nil, verbose_exec: false, verbose_swap: false)
  seen = Set.new
  acc = 0
  pc = -1
  can_mutate = !!terminating_pcs

  while pc >= -1 && (inst = insts[pc += 1])
    puts "#{inst} @ #{pc}" if verbose_exec
    return [:loop, acc] unless seen.add?(pc)
    op, arg = inst

    case op
    when :acc
      acc += arg
    when :jmp
      if can_mutate && terminating_pcs[pc + 1]
        # Mutating this to not be a jump would end us in the terminating set.
        # Let the initial program be P and the program after mutation be P'.
        # Let this instruction be i and the instruction reached after i be j.
        #
        # If we reached here and have not mutated yet,
        # i was part of the initial loop in P.
        # If j leads to i in P, j would not be in the terminating set.
        # So j's path to termination is unaffected by mutating i.
        #
        # So we mutate i and are assured that we will terminate.
        puts "#{pc} #{inst} / #{insts.size} -> #{swap(inst)}" if verbose_swap
        can_mutate = false
      else
        pc += arg - 1
      end
    when :nop
      if can_mutate && terminating_pcs[pc + arg]
        # Mutating this to be a jump would end us in the terminating set.
        puts "#{pc} #{inst} / #{insts.size} -> #{swap(inst)}" if verbose_swap
        can_mutate = false
        pc += arg - 1
      end
    else raise "bad #{inst} @ #{pc}"
    end
  end

  [pc == insts.size ? :exit : :badpc, acc]
end

def swap(inst)
  new_op = case inst[0]
  when :acc; return nil
  when :nop; :jmp
  when :jmp; :nop
  else raise "bad #{inst}"
  end
  swapped = inst.dup
  swapped[0] = new_op
  swapped.freeze
end

def terminating_pcs(insts)
  come_from = Hash.new { |h, k| h[k] = [] }
  insts.each_with_index { |(op, arg), pc|
    npc = pc + (op == :jmp ? arg : 1)
    come_from[npc] << pc
  }

  come_from.default_proc = nil
  come_from.default = [].freeze
  come_from.each_value(&:freeze)
  come_from.freeze

  Search.bfs(insts.size, neighbours: come_from, goal: ->_ { true })[:goals]
end

verbose = ARGV.delete('-v')
brute = ARGV.delete('-b')
insts = ARGF.map { |line|
  words = line.split
  [words[0].to_sym, Integer(words[1])].freeze
}.freeze

stat, acc = run(insts, verbose_exec: verbose)
raise "bad #{stat}" if stat != :loop
puts acc

if brute
  insts.each_with_index { |inst, i|
    next unless (swap_inst = swap(inst))
    swapped = insts.dup
    swapped[i] = swap_inst
    swapped.freeze

    stat, acc = run(swapped)
    puts "#{i} #{stat} #{acc}" if verbose

    puts acc if stat == :exit
  }
else
  terminating_pcs = terminating_pcs(insts)
  p terminating_pcs if verbose

  stat, acc = run(insts, terminating_pcs: terminating_pcs, verbose_swap: verbose)
  raise "bad #{stat}" if stat != :exit
  puts acc
end
