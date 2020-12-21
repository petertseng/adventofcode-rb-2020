require_relative 'lib/bipartite_matching'
require 'set'

verbose = ARGV.delete('-v')
foods = ARGF.map { |line|
  ingredients, allergens = line.delete_suffix(")\n").split(' (contains ')
  [
    Set.new(ingredients.split.map(&:freeze)).freeze,
    allergens.split(', ').map(&:freeze).freeze,
  ].freeze
}.freeze

allergen_could_be = {}

foods.each { |ingredients, allergens|
  allergens.each { |allergen|
    allergen_could_be[allergen] ||= ingredients.dup
    allergen_could_be[allergen] &= ingredients
  }
}

allergen_could_be.each_value(&:freeze)
allergen_could_be.freeze

all_ingredients = foods.sum(Set.new, &:first).freeze
not_allergens = (all_ingredients - allergen_could_be.sum(Set.new, &:last)).freeze

if verbose
  allergen_could_be.each { |allergen, ingredients|
    puts "#{allergen} could be #{ingredients.size}: #{ingredients.to_a.join(', ')}"
  }
  puts "#{not_allergens.size}/#{all_ingredients.size} ingredients can't be allergens: #{not_allergens.size <= 10 ? not_allergens : '(too many to show all)'}"
end

puts foods.sum { |ingredients, _|
  ingredients.count { |i| not_allergens.include?(i) }
}

match = BipartiteMatching.match(allergen_could_be, verbose: verbose)
raise "couldn't deduce: #{allergen_could_be.keys - match.keys}" if match.size != allergen_could_be.size

match.sort_by(&:first).each { |allergen, ingredient|
  puts "#{allergen} = #{ingredient}"
} if verbose

puts match.sort_by(&:first).map(&:last).join(?,)
