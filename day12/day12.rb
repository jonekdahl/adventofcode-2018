

class Plants

  def initialize
    # plant 0 is at position 10 000 in the plant array
    @offset = 10_000
    @pots = Array.new(30_000, '.')
  end

  def [](pot)
    @pots[pot + @offset]
  end

  def []=(pot, value)
    @pots[pot + @offset] = value
  end

  def first_plant
    @pots.index('#') - @offset
  end

  def last_plant
    @pots.rindex('#') - @offset
  end

  def pattern_at(pot)
    position = pot + @offset
    @pots[(position - 2)..(position + 2)].join
  end

  def pots_sum
    @pots.map.with_index { |ch, idx| ch == '#' ? idx - @offset : 0 }.sum
  end
end

def parse_initial_state
  initial = '#.##.###.#.##...##..#..##....#.#.#.#.##....##..#..####..###.####.##.#..#...#..######.#.....#..##...#'
  Plants.new.tap do |plants|
    initial.each_char.with_index { |ch, pot| plants[pot] = ch }
  end
end

def parse_spreads
  File.open('spread.txt').map do |line|
    [line[0..4], line[9]]
  end.to_h.freeze
end

def next_generation(plants, spreads)
  start_pot = plants.first_plant - 2
  end_pot = plants.last_plant + 2
  Plants.new.tap do |new_plants|
    (start_pot..end_pot).each do |pot|
      pattern = plants.pattern_at(pot)
      new_plants[pot] = spreads.fetch(pattern)
    end
  end
end

plants = parse_initial_state
spreads = parse_spreads

p plants.first_plant
p plants.last_plant
p plants.pattern_at(0)
#p spreads


(1..5000).each do |generation|
  plants = next_generation(plants, spreads)
  puts "#{generation},#{plants.pots_sum}" if generation % 1000 == 0
  #puts "#{generation},#{plants.pots_sum}"
end

puts "The sum of the last generation is #{plants.pots_sum}"
