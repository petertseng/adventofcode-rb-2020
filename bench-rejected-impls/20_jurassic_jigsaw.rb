require 'benchmark'

require_relative '../20_jurassic_jigsaw'

bench_candidates = []

bench_candidates << def count_monsters_transform_monster(img)
  monster_tiles, _ = count_monsters(img)
  raise "bad #{monster_tiles}" if monster_tiles % MONSTER.size != 0
  monster_tiles / MONSTER.size
end

bench_candidates << def count_monsters_transform_img(img, verbose: false)
  # string to print => row index => column indices containing sea monsters
  monster_locs = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }

  monsters = 0
  transformations(img.lines(chomp: true)).each_with_index { |tr, i|
    tr.each_cons(3).with_index { |(a, b, c), y|
      # positive lookahead to allow for overlaps
      b.scan(/(?=#....##....##....###)/) { |m|
        x = Regexp.last_match.offset(0).first
        next if a[x + 18] != ?#
        # doesn't seem to make a difference which of these I use
        #next unless c[x + 1, 16].match?(/#..#..#..#..#..#/)
        next unless 6.times.all? { |n| c[x + 1 + 3 * n] == ?# }
        if verbose
          puts "Sea monster #{monsters + 1}: #{y + 1} #{x}"
          joined = tr.join("\n")
          monster_locs[joined][y] << x + 18
          [0, 5, 6, 11, 12, 17, 18, 19].each { |dx| monster_locs[joined][y + 1] << x + dx }
          6.times { |n| monster_locs[joined][y + 2] << x + 1 + 3 * n }
        end
        monsters += 1
      }
    }
  }

  print_monsters_transform_img(monster_locs) if verbose

  monsters
end

def print_monsters_transform_img(monster_locs)
  monster_locs.each { |print, xs_of_y|
    print.lines.each_with_index { |row, y|
      unless (xs = xs_of_y[y])
        puts row
        next
      end
      puts row.chars.each_with_index.map { |c, x|
        xs.include?(x) ? "\e[1;32m#{c}\e[0m" : c
      }.join
    }
  }
end

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 10.times { results[f] = send(f, @img) }}
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
