# frozen_string_literal: true

require 'byebug'

ROCKY = 0
WET = 1
NARROW = 2

TYPES = {
  ROCKY => ".",
  WET => "=",
  NARROW => "|",
}.freeze


class Region
  attr_reader :x, :y, :geologic_index, :type

  def initialize(x, y, geologic_index, depth)
    @x, @y = x, y
    @geologic_index = geologic_index
    @depth = depth
    @fastest_times = {}
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

  def fastest_time?(time, tool)
    @fastest_times.key?(tool) ? time < @fastest_times[tool] : true
  end

  def fastest_time!(time, tool)
    @fastest_times[tool] = time
  end

  def to_s
    "#{TYPES[type]}"
  end

  def target?
    false
  end

  def can_use?(tool)
    case type
    when ROCKY
      tool != :neither
    when WET
      tool != :torch
    when NARROW
      tool != :climbing_gear
    end
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

  def target?
    true
  end
end

State = Struct.new(:region, :time, :tool)

TORCH = :torch
CLIMBING_GEAR = :climbing_gear
NEITHER = :neither
TOOLS = [TORCH, CLIMBING_GEAR, NEITHER]

class Cave
  def initialize(depth, target_x, target_y)
    @depth = depth
    @target_x = target_x
    @target_y = target_y
    @max_x = @target_x + 100
    @max_y = @target_y + 100
    map_cave
  end

  def map_cave
    @cave = Array.new(@max_x + 1) { Array.new(@max_y + 1) }
    @cave[0][0] = Mouth.new(0, 0, 0, @depth)
    @cave[@target_x][@target_y] = Target.new(@target_x, @target_y, 0, @depth)

    0.upto(@max_x) do |x|
      0.upto(@max_y) do |y|
        @cave[x][y] ||= Region.new(x, y, geologic_index(x, y), @depth)
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
    0.upto(@max_y) do |y|
      0.upto(@max_x) do |x|
        type = @cave[x][y].to_s
        printf "#{type}"
      end
      puts
    end
  end

  def search
    @state_queue = PriorityQueue.new
    add_to_queue(@cave[0][0], 0, TORCH) # start at mouth with the torch equipped
    state = nil
    loop do
      state = @state_queue.dequeue
      break if state.region.target? && state.tool == :torch

      add_movements(state)
      add_tool_switches(state)
    end
    state
  end

  def add_to_queue(region, time, tool)
    if region && region.can_use?(tool) && region.fastest_time?(time, tool)
      region.fastest_time!(time, tool)
      @state_queue.enqueue(State.new(region, time, tool), time)
    end
  end

  def add_movements(state)
    region = state.region
    add_to_queue(region_at(region.x, region.y + 1), state.time + 1, state.tool)
    add_to_queue(region_at(region.x + 1, region.y), state.time + 1, state.tool)
    add_to_queue(region_at(region.x, region.y - 1), state.time + 1, state.tool)
    add_to_queue(region_at(region.x - 1, region.y), state.time + 1, state.tool)
  end

  def add_tool_switches(state)
    TOOLS.each do |new_tool|
      next if new_tool == state.tool

      add_to_queue(state.region, state.time + 7, new_tool)
    end
  end

  def region_at(x, y)
    x.between?(0, @max_x) && y.between?(0, @max_y) ? @cave[x][y] : nil
  end
end

# A priority queue that keeps one queue per priority internally.
# Dequeues from the queue with the lowest value, so time (in minutes) will work as priority,
# given that we want to find the fastest way to the target.
#
class PriorityQueue
  def initialize
    @queues = {}
  end

  def enqueue(element, priority)
    queue = @queues[priority] || Queue.new
    queue << element
    @queues[priority] = queue
  end

  def dequeue
    highest_priority = @queues.keys.min
    queue = @queues[highest_priority]
    element = queue.pop
    @queues.delete(highest_priority) if queue.empty?
    element
  end
end

# Example
#depth = 510
#target_x = 10
#arget_y = 10

depth = 4080
target_x = 14
target_y = 785

cave = Cave.new(depth, target_x, target_y)
puts "The total risk of the cave is #{cave.total_risk}"
end_state = cave.search
puts "The optimal way to the target takes #{end_state.time} minutes"
