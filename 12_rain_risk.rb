Coord = Struct.new(:y, :x) {
  def left
    self.class.new(-x, y)
  end

  def right
    self.class.new(x, -y)
  end

  def l1
    x.abs + y.abs
  end

  def +(coord)
    self.class.new(y + coord.y, x + coord.x)
  end

  def *(scalar)
    self.class.new(y * scalar, x * scalar)
  end
}

def move(dirs, ship_init, movable, turnable)
  dirs.each_with_object(ship_init) { |(letter, magnitude), ship|
    case letter
    when :N; ship[movable].y -= magnitude
    when :S; ship[movable].y += magnitude
    when :E; ship[movable].x += magnitude
    when :W; ship[movable].x -= magnitude
    when :L, :R
      raise "bad turn #{magnitude}" if magnitude % 90 != 0
      magnitude /= 90
      if letter == :R
        magnitude.times { ship[turnable] = ship[turnable].right }
      else
        magnitude.times { ship[turnable] = ship[turnable].left }
      end
    when :F
      ship[:ship_pos] += ship[turnable] * magnitude
    else raise "bad #{letter} #{magnitude}"
    end
  }
end

dirs = ARGF.map { |l| [l[0].to_sym, Integer(l[1..])].freeze }.freeze

ship1 = move(dirs, {ship_pos: Coord.new(0, 0), facing: Coord.new(0, 1)}, :ship_pos, :facing)
puts ship1[:ship_pos].l1

ship2 = move(dirs, {waypoint_pos: Coord.new(-1, 10), ship_pos: Coord.new(0, 0)}, :waypoint_pos, :waypoint_pos)
puts ship2[:ship_pos].l1
