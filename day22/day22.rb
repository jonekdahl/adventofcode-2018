# frozen_string_literal: true

require 'byebug'

TYPES = {
  0 => ".",
  1 => "=",
  2 => "|",
}.freeze

class Region
  attr_reader :geologic_index, :type

  def initialize(geologic_index, depth)
    @geologic_index = geologic_index
    @depth = depth
  end

  def erosion_level
    @erosion_level ||= (@geologic_index + @depth) % 20_183
  end

  def type
    erosion_level % 3
  end

  def risk
    type
  end

  def to_s
    "#{TYPES[type]}"
  end
end

class Mouth < Region
  def to_s
    "M"
  end

  def risk
    0
  end
end

class Target < Region
  def to_s
    "T"
  end

  def risk
    0
  end
end

class Cave
  def initialize(depth, target_x, target_y)
    @depth = depth
    @target_x = target_x
    @target_y = target_y
    map_cave
  end

  def map_cave
    @cave = Array.new(@target_x + 1) { Array.new(@target_y + 1) }
    @cave[0][0] = Mouth.new(0, @depth)
    @cave[@target_x][@target_y] = Target.new(0, @depth)

    0.upto(@target_x) do |x|
      0.upto(@target_y) do |y|
        @cave[x][y] ||= Region.new(geologic_index(x, y), @depth)
      end
    end
  end

  def geologic_index(x, y)
    element = @cave[x][y]
    return element.geologic_index if element

    return x * 16_807 if y == 0
    return y * 48_271 if x == 0

    @cave[x - 1][y].erosion_level * @cave[x][y - 1].erosion_level
  end

  def total_risk
    risk = 0
    0.upto(@target_y) do |y|
      0.upto(@target_x) do |x|
        risk += @cave[x][y].risk
      end
    end
    risk
  end

  def print
    0.upto(@target_y) do |y|
      0.upto(@target_x) do |x|
        type = @cave[x][y].to_s
        printf "#{type}"
      end
      puts
    end
  end
end

# Example
#depth = 510
#target_x = 10
#target_y = 10

depth = 4080
target_x = 14
target_y = 785

cave = Cave.new(depth, target_x, target_y)
puts "The total risk of the cave is #{cave.total_risk}"

