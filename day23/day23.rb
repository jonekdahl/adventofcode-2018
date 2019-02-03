# frozen_string_literal: true

Position = Struct.new(:x, :y, :z) do
  def distance(pos)
    (x - pos.x).abs + (y - pos.y).abs + (z - pos.z).abs
  end
end

BoundingBox = Struct.new(:min, :max) do
  def volume
    (max.x - min.x).abs * (max.y - min.y).abs * (max.z - min.z).abs
  end
end

Bot = Struct.new(:position, :signal_radius) do
  def in_range_of?(pos)
    position.distance(pos) <= signal_radius
  end

  def bounding_box
    @bounding_box ||= BoundingBox.new(
      Position.new(position.x - signal_radius, position.y - signal_radius, position.z - signal_radius),
      Position.new(position.x + signal_radius, position.y + signal_radius, position.z + signal_radius)
    )
  end

  def each_position_in_range
    bb = bounding_box

    bb.min.x.upto(bb.max.x) do |x|
      bb.min.y.upto(bb.max.y) do |y|
        bb.min.z.upto(bb.max.z) do |z|
          yield(x, y, z)
        end
      end
    end
  end
end

def parse(file)
  regex = /pos=\<(-?\d+),(-?\d+),(-?\d+)\>, r=(\d+)/ # pos=<0,0,0>, r=4
  File.open(file).map do |line|
    m = regex.match(line)
    ints = m[1..-1].map { |s| Integer(s) }
    Bot.new(Position.new(*ints[0..2]), ints[3])
  end
end

def min(a, b)
  a < b ? a : b
end

def max(a, b)
  a > b ? a : b
end

def bounding_box(bots)
  min = Position.new(nil, nil, nil)
  max = Position.new(nil, nil, nil)

  bots.each do |bot|
    bmin = bot.bounding_box.min
    bmax = bot.bounding_box.max
    min.x = min.x ? min(min.x, bmin.x) : bmin.x
    min.y = min.y ? min(min.y, bmin.y) : bmin.y
    min.z = min.z ? min(min.z, bmin.z) : bmin.z
    max.x = max.x ? max(max.x, bmax.x) : bmax.x
    max.y = max.y ? max(max.y, bmax.y) : bmax.y
    max.z = max.z ? max(max.z, bmax.z) : bmax.z
  end

  BoundingBox.new(min, max)
end

def find_optimal_positions(bots, bounding_box)
  max_bots_in_range = 1
  max_bots_positions = []
  min, max = *bounding_box
  min.x.upto(max.x) do |x|
    puts "x = #{x}"
    min.y.upto(max.y) do |y|
      min.z.upto(max.z) do |z|
        position = Position.new(x, y, z)
        bots_in_range = bots.count { |bot| bot.in_range_of?(position) }
        puts "#{bots_in_range} bots in range of #{position}" if bots_in_range >= 2
        if bots_in_range > max_bots_in_range
          max_bots_in_range = bots_in_range
          max_bots_positions = [position]
        elsif bots_in_range == max_bots_in_range
          max_bots_positions << position
        end
      end
    end
  end
  [max_bots_positions, max_bots_in_range]
end

bots = parse('nanobots.txt')
strongest_bot = bots.sort_by { |bot| bot.signal_radius }.last
bots_in_range = bots.count { |bot| strongest_bot.in_range_of?(bot.position) }
puts "#{bots_in_range} bots are in range of #{strongest_bot}"
bounding_box = bounding_box(bots)
puts "Bounding box: #{bounding_box}"
puts "%10d - volume of bounding_box" % bounding_box.volume
bot_volumes = bots.map { |bot| bot.bounding_box.volume }.sum
puts "%10d - sum of bot bounding box volumes" % bot_volumes

optimal_positions, bots_in_range = find_optimal_positions(bots, bounding_box)
puts "Positions where the most number of bots are in range (#{bots_in_range}):"
pp optimal_positions
