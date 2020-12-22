require 'set'

DECK_DIVIDER = 0
NOT_KNOWN_TO_LOOP = Array.new(51, false)
[0, 1, 2, 3, 4, 6, 8, 12, 24, 32, 38, 40, 42, 44, 46, 48, 49, 50].each { |n|
  NOT_KNOWN_TO_LOOP[n] = true
}
NOT_KNOWN_TO_LOOP.freeze

# The game runs fast enough that no particular optimisation is needed.
def game(deck1, deck2)
  seen = Set.new
  while true
    # Wasn't asked of us in part 1, but I sometimes manually test inputs that cause it.
    return [:loop, []] unless seen.add?(compress_decks(deck1, deck2))

    card1 = deck1.shift
    card2 = deck2.shift
    if card1 > card2
      deck1 << card1
      deck1 << card2
      return [1, deck1] if deck2.empty?
    else
      deck2 << card2
      deck2 << card1
      return [2, deck2] if deck1.empty?
    end
  end
end

GLOBAL_CACHE = {}
STAT = Hash.new(0)
LOOPS = Array.new(51, 0)

def recgame(deck1, deck2, toplevel: false)
  max1 = deck1.max
  max2 = deck2.max
  max_card = max1 > max2 ? max1 : max2

  if !toplevel
    # https://www.reddit.com/r/adventofcode/comments/khzm6z/2020_day_22_part_2_properties_of_misinterpreted/ggo3hcg
    # Recursive games either end in a p1 victory due to loop,
    # or that the holder of the highest card wins.
    # If p1 holds the highest card, p1 wins in both cases, so is guaranteed.
    return -1 if max1 > max2

    # We don't seem to know anything else for sure.
    # We know that if the game doesn't loop then high card wins,
    # but we don't know how to tell in advance that the game won't loop.
    # All we know is that we have a list of lengths where we haven't seen a loop yet...
    return max2 <=> max1 if NOT_KNOWN_TO_LOOP[deck1.size + deck2.size]
  end

  if false
    global_key = compress_decks(deck1, deck2)
    if (cached = GLOBAL_CACHE[global_key])
      # This does happen, but it's 160 hits vs 2869 misses withvs 3061 misses without.
      # Checking for it actually takes more time than it saves.
      STAT[:hit] += 1
      return cached
    else
      STAT[:miss] += 1
    end
  end

  seen = Set.new
  while true
    # loop rule - check only when a certain card is to be drawn,
    # that being the high card.
    if (deck1[0] == max_card || deck2[0] == max_card) && !seen.add?(compress_decks(deck1, deck2))
      #LOOPS[deck1.size + deck2.size] += 1
      #GLOBAL_CACHE[global_key] = -1
      return toplevel ? [:loop, deck1] : -1
    end

    card1 = deck1.shift
    card2 = deck2.shift
    winner = if deck1.size >= card1 && deck2.size >= card2
      recgame(deck1.first(card1), deck2.first(card2))
    else
      card2 <=> card1
    end

    if winner < 0
      deck1.push(card1, card2)
      if deck2.empty?
        #GLOBAL_CACHE[global_key] = -1
        return toplevel ? [1, deck1] : -1
      end
    elsif winner > 0
      deck2.push(card2, card1)
      if deck1.empty?
        #GLOBAL_CACHE[global_key] = 1
        return toplevel ? [2, deck2] : 1
      end
    else
      raise 'no winner???'
    end
  end
end

def compress_decks(deck1, deck2)
  # If I wanted to express it as an integer,
  # I need something that can uniquely describe permutations of the integers 1-100...
  # All of the choices are pretty bad (see benchmark directory)
  # but the one chosen is least bad.
  (deck1 + [DECK_DIVIDER] + deck2).pack('c*')
end

def score(deck)
  deck.reverse_each.with_index(1).sum { |n, i| n * i }
end

verbose = ARGV.delete('-v')
decks = ARGF.each("\n\n", chomp: true).map.with_index { |section, i|
  player, *lines = section.lines
  raise "bad #{player} not player #{i + 1}" if player.chomp != "Player #{i + 1}:"
  cards = lines.map(&method(:Integer))
  raise "can't have card #{DECK_DIVIDER}" if cards.include?(DECK_DIVIDER)
  cards.freeze
}.freeze

winner1, deck1 = game(*decks.map(&:dup))
puts "player #{winner1} win" if verbose
puts score(deck1)

winner2, deck2 = recgame(*decks.map(&:dup), toplevel: true)
puts "player #{winner2} win" if verbose
puts score(deck2)

puts STAT unless STAT.empty?
puts "loops with #{LOOPS.each_with_index.filter_map { |v, i| i if v != 0 }}" unless LOOPS.all?(&:zero?)
