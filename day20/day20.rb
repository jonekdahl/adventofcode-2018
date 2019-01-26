# frozen_string_literal: true

# NOTE: This version cannot handle intersecting paths, but it works on the given inputs.

require 'set'

class Room
  attr_accessor :distance
  attr_reader :exits

  def initialize
    @exits = {}
  end

  def add_exit(direction, room)
    @exits[direction] = room
  end
end

class Mapper

  NORTH = :north
  SOUTH = :south
  EAST = :east
  WEST = :west

  DIRECTIONS = [NORTH, SOUTH, EAST, WEST].to_set

  OPPOSITE_DIRECTION = {
    NORTH => SOUTH,
    SOUTH => NORTH,
    EAST => WEST,
    WEST => EAST,
  }.freeze

  def parse(directions)
    directions = directions.gsub(/\^/, '[')
                           .gsub(/\$/, ']')
                           .gsub(/N/, 'NORTH, ')
                           .gsub(/S/, 'SOUTH, ')
                           .gsub(/E/, 'EAST, ')
                           .gsub(/W/, 'WEST, ')
                           .gsub(/\(/, '[[')
                           .gsub(/\)/, ']], ')
                           .gsub(/\|/, '], [')
    @directions = instance_eval directions
  end

  def follow_directions
    def _follow(room, directions, position)
      #puts "explore: #{position}"
      return room if position == directions.size

      direction = directions[position]
      if direction.is_a?(Array) # branch
        options = direction
        end_rooms = options.map { |option| _follow(room, option, 0) }
        end_rooms.uniq! # This was a crucial optimization, to avoid traversing the rest of the directions from the same room multiple times
        end_rooms.each { |last_room_of_option| _follow(last_room_of_option, directions, position + 1) }
      else # DIRECTIONS.include?(direction)
        next_room = room.exits[direction]
        unless next_room
          next_room = Room.new
          room.add_exit(direction, next_room)
          next_room.add_exit(OPPOSITE_DIRECTION[direction], room)
        end
        _follow(next_room, directions, position + 1)
      end
    end

    @start_room = Room.new
    _follow(@start_room, @directions, 0)
  end


  def explore
    def _explore(rooms_to_explore, seen, position)
      until position == rooms_to_explore.size
        room = rooms_to_explore[position]
        room.exits.each do |direction, new_room|
          next if seen.include?(new_room)

          new_room.distance = room.distance + 1
          rooms_to_explore << new_room
          seen << new_room
        end
        position += 1
      end
      furthest_room = rooms_to_explore[-1]
      distance_at_least_thousand = seen.count { |room| room.distance >= 1000 }
      [furthest_room, distance_at_least_thousand]
    end

    @start_room.distance = 0
    _explore([@start_room], [@start_room].to_set, 0)
  end
end

example1 = '^WNE$'
example2 = '^ENWWW(NEEE|SSE(EE|N))$'
example3 = '^ENNWSWW(NEWS|)SSSEEN(WNSE|)EE(SWEN|)NNN$'
example4 = '^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$'
example5 = '^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$'

directions = File.open('directions.txt').each_line.first.chomp

mapper = Mapper.new
mapper.parse(directions)
mapper.follow_directions
furthest_room, distance_at_least_thousand = mapper.explore

puts "Distance to furthest room: #{furthest_room.distance}"
puts "Room with distance at least 1000: #{distance_at_least_thousand}"
