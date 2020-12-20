class Tile
  attr_reader :id, :img, :borders, :uniq, :neigh

  def initialize(str)
    id_line, img = str.split("\n", 2)
    @id = Integer(id_line.split[1].delete_suffix(?:))
    @img = img.lines(chomp: true).map(&:freeze).freeze
    @borders = mkborders(@img).freeze
    @uniq = []
    @neigh = {}
  end

  def is_uniq!(border)
    @uniq << border
  end

  def make_top_left!
    changed = false
    new_neigh = @neigh.dup
    if @uniq.include?(:right)
      changed = true
      new_neigh[:right] = new_neigh.delete(:left)
      @img = fliph(@img)
    end

    if @uniq.include?(:bottom)
      changed = true
      new_neigh[:bottom] = new_neigh.delete(:top)
      @img = @img.reverse
    end

    if changed
      @img.each(&:freeze)
      @img.freeze
      @uniq = %i(top left).freeze
      @neigh = new_neigh.freeze
      @borders = mkborders(@img).freeze
    end
  end

  # Could just try all eight, but let's be a bit more nuanced.
  def make_match_border!(my_border, target)
    already_matching = @borders.select { |_, v|
      v == target || v.reverse == target
    }
    raise "making #@id #@borders match #{target} has candidates #{already_matching}" unless already_matching.size == 1
    current = already_matching.keys[0]

    new_img = @img
    # Check if we need to rotate 90/270 degrees
    if current != my_border && current != OPPOSITE[my_border]
      new_img = transpose_str(new_img)
      current = TRANSPOSE[current]
    end
    # Now we're either on the same border or opposite
    if current != my_border
      new_img = current == :top || current == :bottom ? new_img.reverse : fliph(new_img)
      current = OPPOSITE[current]
    end
    # Now we're on the same border but might be reversed.
    if border(new_img, my_border) != target
      new_img = current == :top || current == :bottom ? fliph(new_img) : new_img.reverse
    end

    if (new_border = border(new_img, my_border)) != target
      raise "making #@id #@borders match #{target} resulted in #{new_border} - originally #{already_matching}, now #{current}"
    end

    if @img != new_img
      @borders = mkborders(new_img).freeze
      @img = new_img.map(&:freeze).freeze
    end
  end
end

OPPOSITE = {
  top: :bottom,
  bottom: :top,
  left: :right,
  right: :left,
}.freeze

TRANSPOSE = {
  top: :left,
  bottom: :right,
  left: :top,
  right: :bottom,
}.freeze

def border(lines, border)
  case border
  when :top; lines[0].freeze
  when :bottom; lines[-1].freeze
  when :left; lines.map { |l| l[0] }.join.freeze
  when :right; lines.map { |l| l[-1] }.join.freeze
  else raise "bad border #{border}"
  end
end

def mkborders(lines)
  %i(top bottom left right).to_h { |i| [i, border(lines, i)] }
end

def transformations(s)
  [
    s,
    s.reverse,
    fliph(s),
    fliph(s.reverse),
    transpose_str(s),
    transpose_str(s.reverse),
    transpose_str(fliph(s)),
    transpose_str(fliph(s.reverse)),
  ]
end

def fliph(s)
  s.map(&:reverse)
end

def transpose_str(s)
  s.map(&:chars).transpose.map(&:join)
end

VALID_CHAR = {?# => 1, ?. => 0}.freeze
def bits(s)
  s.each_char.with_index.sum { |c, i| VALID_CHAR.fetch(c) << i }
end

# nil: no tiles with that border... yet
# [Tile, border]: one tile with that border
# :occupied: two tiles with that border
border_match = {}

verbose = ARGV.delete('-v')
tiles = ARGF.each("\n\n", chomp: true).to_h { |tile|
  t = Tile.new(tile)
  t.borders.each { |border, str|
    min = [bits(str), bits(str.reverse)].min

    case border_match[min]
    when nil
      border_match[min] = [t, border]
    when Array
      # let the two tiles know of each other
      other_t, other_border = t.neigh[border] = border_match[min]
      other_t.neigh[other_border] = [t, border]
      border_match[min] = :occupied
    when :occupied
      raise "too many tiles have #{min}"
    else
      raise "bad #{min} #{border_match[min]}"
    end
  }
  [t.id, t]
}.freeze

border_match.each_value { |t, border| t.is_uniq!(border) if border }
tiles.each_value { |t|
  t.uniq.freeze
  t.neigh.freeze
}

corners = tiles.each_value.select { |t| t.uniq.size == 2 }
raise "#{corners.size} corners" if corners.size != 4
puts corners.map(&:id).reduce(:*)

# Selects tiles of the entire grid and orients them correctly.
# Starts from top left, builds top row, builds left column,
# builds out each subsequent row using the left column.
# Fun fact: Can handle any rectangular input, not just squares.
def build_grid(top_left, tiles)
  top_left.make_top_left!

  top_row = build_line(top_left, :right, :row) { |t| t.uniq.size == 2 }
  width = top_row.size
  left_column = build_line(top_left, :bottom, :column) { |t| t.uniq.size == 2 }
  # height = left_column.size

  # left_column also includes the top-left corner, but we don't need to rebuild the top row.
  left_column[1..].map { |left|
    lefts_left_border = if left.uniq.size > 1
      # We're at the bottom-left corner, need to pick which one is the left border.
      # The bottom border has a neighbour above (the second-to-last in left column),
      # so not that one.
      candidates = left.uniq.select { |u|
        t, _ = left.neigh[OPPOSITE[u]]
        t != left_column[-2]
      }
      raise "bottom-left corner has #{candidates} for right border" if candidates.size != 1
      candidates[0]
    else
      # otherwise, a left edge has only one unique border.
      left.uniq[0]
    end
    build_line(left, OPPOSITE[lefts_left_border], :row, size: width)
  }.unshift(top_row)
end

# Selects tiles of a line (row or column) and orients.
# Pass in size to limit the size, or a block to say when to stop.
def build_line(first, prev_border, line, size: nil)
  raise "Don't know when to stop" if !size && !block_given?

  case line
  when :row
    match_border_current = :left
    match_border_prev = :right
  when :column
    match_border_current = :top
    match_border_prev = :bottom
  else
    raise "bad line #{line}"
  end

  line = [first]
  prev = first

  until line.size == size
    current, current_border = prev.neigh[prev_border]
    current.make_match_border!(match_border_current, prev.borders[match_border_prev])
    prev_border = OPPOSITE[current_border]
    line << current
    break if block_given? && yield(current)
    prev = current
  end

  line
end

def rm_borders(reassembled)
  reassembled.map { |row|
    tile_lines = row.map { |tile|
      tile.img[1...-1].map { |l| l[1...-1] }
    }
    tile_lines.transpose.map(&:join).join("\n")
  }.join("\n")
end

MONSTER_OFFSET = 19

def compress(y, x, width, offset)
  # Increase width by 19 so that looking for a monster off the edge won't loop around to another row.
  (y + offset) * (width + MONSTER_OFFSET) + x + offset
end

def decompress(pos, width, offset)
  y, x = pos.divmod(width + MONSTER_OFFSET)
  [y - offset, x - offset]
end

MONSTER = [
  [-1, 18],
  [0, 0],
  [0, 5],
  [0, 6],
  [0, 11],
  [0, 12],
  [0, 17],
  [0, 18],
  [0, 19],
  [1, 1],
  [1, 4],
  [1, 7],
  [1, 10],
  [1, 13],
  [1, 16],
].map(&:freeze).freeze

def count_monsters(img, verbose: false)
  lines = img.lines(chomp: true).map(&:freeze).freeze
  width = lines.map(&:size).max

  # y => x => number of monsters containing that tile (hopefully only 0 or 1, but you never know)
  monster_tiles_in_row = Hash.new { |h, k| h[k] = Hash.new(0) }
  monster_tiles = 0

  transformed_monsters = [
    [-1, -1, false],
    [-1, -1, true],
    [-1, 1, false],
    [-1, 1, true],
    [1, -1, false],
    [1, -1, true],
    [1, 1, false],
    [1, 1, true],
  ].map { |dy, dx, mirror|
    MONSTER.map { |y, x|
      mirror ? compress(x * dx, y * dy, width, 0) : compress(y * dy, x * dx, width, 0)
    }.freeze
  }.freeze

  pounds = {}
  lines.each_with_index { |row, y|
    row.each_char.with_index { |c, x|
      pounds[compress(y, x, width, MONSTER_OFFSET)] = true if c == ?#
    }
  }

  monsters = 0
  pounds.each_key { |pound|
    transformed_monsters.each { |monster|
      next unless monster.all? { |m| pounds[pound + m] }
      if verbose
        puts "Sea monster #{monsters += 1}: #{decompress(pound, width, MONSTER_OFFSET)}"
        monster.each { |m|
          y, x = decompress(pound + m, width, MONSTER_OFFSET)
          monster_tiles_in_row[y][x] += 1
        }
      end
      # won't count overlaps
      monster_tiles += MONSTER.size
    }
  }

  [monster_tiles, monster_tiles_in_row]
end

def print_monsters(img, monster_tiles_in_row)
  img.lines.each_with_index { |row, y|
    unless (xs = monster_tiles_in_row[y])
      puts row
      next
    end
    puts row.chars.each_with_index.map { |c, x|
      case xs[x]
      when 0
        c
      when 1
        # Part of one monster: green
        "\e[1;32m#{c}\e[0m"
      else
        # Part of > 1 monster: red
        "\e[1;31m#{c}\e[0m"
      end
    }.join
  }
end

reassembled = build_grid(corners[0], tiles)
reassembled.each { |row| p row.map(&:id) } if verbose

img = rm_borders(reassembled)
monster_tiles, monsters_tiles_in_row = count_monsters(img, verbose: verbose)

if verbose
  print_monsters(img, monsters_tiles_in_row)
  puts "#{img.count(?#)} - #{monster_tiles}"
end

puts img.count(?#) - monster_tiles

# export for benchmark
@img = img
