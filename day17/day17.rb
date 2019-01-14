# frozen_string_literal: true

require 'byebug'
require 'ruby-prof'
require 'stackprof'
require 'memory_profiler'
require 'set'

Position = Struct.new(:x, :y) do
  def down!
    self.y = self.y + 1
  end

  def left!
    self.x = self.x - 1
  end

  def right!
    self.x = self.x + 1
  end
end

Drop = Struct.new(:position, :direction, :settled, :seen_wall) do
  def down!
    position.down!
    self.direction = :down
  end

  def left!
    position.left!
    self.direction = :left
  end

  def right!
    position.right!
    self.direction = :right
  end
end

class Scan

  def initialize(ranges)
    @x_min = ranges.map { |x_range, _| x_range.first }.min - 1
    @x_max = ranges.map { |x_range, _| x_range.last }.max + 1
    @y_min = ranges.map { |_, y_range| y_range.first }.min
    @y_max = ranges.map { |_, y_range| y_range.last }.max

    puts "scanned area x: #{@x_min}..#{@x_max}, y: #{@y_min}..#{@y_max}"
    @scan = Array.new(@x_max + 1) { Array.new(@y_max + 1, '.') }
    @left_or_right = Array.new(@x_max + 1) { Array.new(@y_max + 1, :left) }
    @scan[500][0] = '+'

    ranges.each do |x_range, y_range|
      x_range.each do |x|
        y_range.each do |y|
          @scan[x][y] = '#'
        end
      end
    end
    @drops = []
  end

  def run
    drops = 0
    unsettled_count = 0
    until unsettled_count >= 10 do
      drops = drops + 1
      drop = Drop.new(Position.new(500, 1), :down, false, false)
      run_drop(drop)

      if drop.settled
        at!(drop.position.x, drop.position.y, '~')
        unsettled_count = 0
        #puts "Drop #{drops} settled at [#{drop.position.x}, #{drop.position.y}]"
      else
        puts "Drop #{drops} dropped below [#{drop.position.x}, #{drop.position.y}] and is lost"
        unsettled_count = unsettled_count + 1
      end
      #puts "#{self}"
    end
  end

  def run_drop(drop)
    until drop.settled || drop.position.y > @y_max do
      position = drop.position
      #puts "Position: #{position}"
      if can_flow_down?(position)
        at!(position.x, position.y, '|')
        drop.seen_wall = false
        drop.down!
      elsif drop.direction == :down
        if can_flow_left?(position) && can_flow_right?(position)
          at!(drop.position.x, drop.position.y, '|')
          left_or_right?(position) == :left ? drop.left! : drop.right!
        elsif can_flow_left?(position)
          at!(position.x, position.y, '|')
          drop.seen_wall = true
          drop.left!
        elsif can_flow_right?(position)
          at!(position.x, position.y, '|')
          drop.seen_wall = true
          drop.right!
        else
          drop.settled = true
        end
      elsif drop.direction == :left
        if can_flow_left?(position)
          at!(position.x, position.y, '|')
          drop.left!
        elsif drop.seen_wall
          drop.settled = true
        else
          at!(position.x, position.y, '|')
          drop.seen_wall = true
          drop.right!
        end
      elsif drop.direction == :right
        if can_flow_right?(position)
          at!(position.x, position.y, '|')
          drop.right!
        elsif drop.seen_wall
          drop.settled = true
        else
          at!(position.x, position.y, '|')
          drop.seen_wall = true
          drop.left!
        end
      end
    end
  end

  def left_or_right?(position)
    @left_or_right[position.x][position.y] = @left_or_right[position.x][position.y] == :left ? :right : :left
  end

  def can_flow_down?(position)
    open?(position.x, position.y + 1)
  end

  def can_flow_left?(position)
    open?(position.x - 1, position.y)
  end

  def can_flow_right?(position)
    open?(position.x + 1, position.y)
  end

  def open?(x, y)
    return true if y > @y_max
    @free ||= ['.', '|'].to_set.freeze
    @free.include?(at(x, y))
  end

  def at(x, y)
    @scan[x][y]
  end

  def at!(x, y, val)
    @scan[x][y] = val
  end

  def to_s
    (0..(@y_max + 1)).each do |y|
      (@x_min..@x_max).each do |x|
        print @scan[x][y]
      end
      puts
    end
  end

  def count_water
    count = 0
    water = ['~', '|']
    (@y_min..@y_max).each do |y|
      (@x_min..@x_max).each do |x|
        count = count + 1 if water.include?(at(x, y))
      end
    end
    count
  end

  def count_water_at_rest
    count = 0
    water = '~'.freeze
    (@y_min..@y_max).each do |y|
      (@x_min..@x_max).each do |x|
        count = count + 1 if at(x, y) == water
      end
    end
    count
  end
end


def parse_scan
  ranges = File.open('scan.txt').map do |line|
    matcher = /([xy])=(\d+)/.match(line)
    from = to = Integer(matcher[2])
    if matcher[1] == 'x'
      x_range = from..to
    else
      y_range = from..to
    end
    matcher = /([xy])=(\d+)\.\.(\d+)/.match(line)
    from = Integer(matcher[2])
    to = Integer(matcher[3])
    if matcher[1] == 'x'
      x_range = from..to
    else
      y_range = from..to
    end
    [x_range, y_range]
  end
  Scan.new(ranges)
end


scan = parse_scan
#result = RubyProf.profile(measure_mode: RubyProf::WALL_TIME) do
#profile = StackProf.run(mode: :cpu, out: '/tmp/stackprof-cpu-day17.dump') do
#report = MemoryProfiler.report do
  scan.run
#end

#RubyProf::FlatPrinter.new(result).print(STDOUT, :min_percent => 2) # ruby-prof
#report.pretty_print # memory profiler


#puts "#{scan}"
puts "#{scan.count_water} water squares in total"
puts "#{scan.count_water_at_rest} water squares at rest"
