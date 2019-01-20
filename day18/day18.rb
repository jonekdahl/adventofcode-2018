# frozen_string_literal: true

require 'memory_profiler'

class Forest
  def initialize(scan)
    @scan = scan
    @max_y = @scan.size - 1
    @max_x = @scan[0].size - 1
  end

  def tick
    @next_scan ||= Array.new(@max_y + 1) { Array.new(@max_x + 1) }
    0.upto(@max_y) do |y|
      0.upto(@max_x) do |x|
        @next_scan[y][x] = evolve(x, y)
      end
    end
    @scan, @next_scan = @next_scan, @scan
  end

  def resource_value
    count('#') * count('|')
  end

  def count(type)
    count = 0
    @scan.each { |line| line.each { |acre| count += 1 if acre == type } }
    count
  end

  def evolve(x, y)
    type = at(x, y)
    if type == '.' # open
      count_adjacent(x, y, '|') >= 3 ? '|' : '.'
    elsif type == '|' # trees
      count_adjacent(x, y, '#') >= 3 ? '#' : '|'
    elsif type == '#' # lumberyard
      (count_adjacent(x, y, '#') >= 1 && count_adjacent(x, y, '|') >= 1) ? '#' : '.'
    else
      raise "WAT"
    end
  end

  def count_adjacent(x, y, type)
    count = 0
    max(y - 1, 0).upto(min(y + 1, @max_y)) do |ay|
      max(x - 1, 0).upto(min(x + 1, @max_x)) do |ax|
        next if ax == x && ay == y

        count += 1 if at(ax, ay) == type
      end
    end
    #puts "Number of '#{type}' adjacent to [#{x}, #{y}]: #{count}"
    count
  end

  def min(a, b)
    a < b ? a : b
  end

  def max(a, b)
    a > b ? a : b
  end

  def at(x, y)
    @scan[y][x]
  end

  def to_s
    @scan.map do |line|
      line.join
    end.join("\n")
  end
end

def parse_forest
  scan = File.open('forest.txt').map do |line|
    line.chomp.chars
  end
  Forest.new(scan)
end

forest = parse_forest

#10.times { forest.tick }
#puts forest.to_s
#puts "Resource value: #{forest.resource_value}"

values = []
1_000.times do |i|
  forest.tick
  values << forest.resource_value
end

puts "Resource value after 10 minutes: #{values[9]}"

max_value = values[500..-1].max
max_indices = values.each.with_index.map { |a, i| a == max_value ? i : nil }.compact
cycle_size = max_indices[0..-2].zip(max_indices[1..-1]).map { |i1, i2| i2 - i1 }.uniq[0]
#puts "Max value #{max_value} is repeated at #{max_indices}, or every #{cycle_size} iteration"

cycles = ((1_000_000_000 - 1000) / cycle_size) + 1
iteration = 1_000_000_000 - cycle_size * cycles

puts "Resource value after 1_000_000_000 minutes: #{values[iteration - 1]}"
