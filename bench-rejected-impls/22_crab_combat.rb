require 'benchmark'
require 'set'

# This might have been reasonable if the slow part was array shifting, but it's not.
# Ruby arrays work just fine as queues.
# So this doesn't help at all.
class Deck
  include Enumerable

  def initialize(cards, capacity)
    @read = 0
    @write = cards.size
    @cards = cards
    @capacity = capacity
    @cards.fill(nil, cards.size...capacity)
  end

  def empty?
    @read == @write
  end

  def size
    @write - @read
  end

  def shift
    @read += 1
    @cards[(@read - 1) % @capacity]
  end

  def <<(e)
    @cards[@write % @capacity] = e
    @write += 1
  end

  def first(n)
    Array.new(n) { |i| @cards[(@read + i) % @capacity] }
  end

  def to_a
    first(size)
  end

  def join(sep)
    to_a.join(sep)
  end

  def to_s
    to_a.to_s
  end

  def each(&block)
    r = @read
    until r == @write
      block[@cards[r % @capacity]]
      r += 1
    end
  end
end

#capacity = decks.sum(&:size)
#winner1, deck1 = game(*decks.map { |d| Deck.new(d.dup, capacity) })
#winner2, deck2 = recgame(*decks.map { |d| Deck.new(d.dup, capacity) }, toplevel: true)

def rand_decks
  nums = (1..50).to_a.shuffle
  [nums.slice!(0, rand(1..49)), nums]
end

Benchmark.bmbm { |bm|
  decks = Array.new(10000) { rand_decks }

  bm.report(:noop) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << 0
    }
  }

  bm.report(:noop_iter_cards) {
    s = Set.new
    decks.each { |deck1, deck2|
      deck1.each { }
      deck2.each { }
      s << 0
    }
  }

  bm.report(:loc_always_50) {
    s = Set.new
    decks.each { |deck1, deck2|
      loc = Array.new(50, 0)
      deck1.each_with_index { |x, i| loc[x] = i }
      deck2.each_with_index { |x, i| loc[x] = i + 50 }
      s << loc.pack('c*')
    }
  }

  bm.report(:loc_sparse) {
    s = Set.new
    decks.each { |deck1, deck2|
      loc = []
      deck1.each_with_index { |x, i| loc << x * 100 + i }
      deck2.each_with_index { |x, i| loc << x * 100 + i + 50 }
      s << loc.sort.pack('c*')
    }
  }

  bm.report(:join) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << deck1.join(?,) + ?| + deck2.join(?,)
    }
  }

  bm.report(:concat_with_sep) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << deck1 + [0] + deck2
    }
  }

  bm.report(:concat_with_map) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << deck1 + deck2.map { |x| x + 50 }
    }
  }

  bm.report(:to_s) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << deck1.to_s + deck2.to_s
    }
  }

  bm.report(:pack_then_concat) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << deck1.pack('c*') + "\0" + deck2.pack('c*')
    }
  }

  bm.report(:concat_then_packc) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << (deck1 + [0] + deck2).pack('c*')
    }
  }

  bm.report(:concat_then_packw) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << (deck1 + [0] + deck2).pack('w*')
    }
  }

  bm.report(:pack_unpackL) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << (deck1 + [0] + deck2).pack('c*').unpack('L*')
    }
  }

  bm.report(:pack_unpackQ) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << (deck1 + [0] + deck2).pack('c*').unpack('Q*')
    }
  }

  bm.report(:slice_shift) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << (deck1 + [0] + deck2).each_slice(10).map { |slc| slc.reduce(0) { |a, x| a << 6 + x } }
    }
  }

  bm.report(:just_shift) {
    s = Set.new
    decks.each { |deck1, deck2|
      s << (deck1 + [0] + deck2).reduce(0) { |a, x| a << 6 + x }
    }
  }
}
