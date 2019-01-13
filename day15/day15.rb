# frozen_string_literal: true

#require 'byebug'
#require 'memory_profiler'
#require 'stackprof'
require 'set'

Position = Struct.new(:x, :y) do
  def to_s
    @string_representation ||= "[#{x}, #{y}]"
  end

  def adjacent
    @adjacent ||= [Position.create(x, y - 1), Position.create(x - 1, y), Position.create(x + 1, y), Position.create(x, y + 1)].freeze
  end

  def self.create(x, y)
    @positions ||= Hash.new do |hx, x|
      hx[x] = Hash.new do |hy, y|
        hy[y] = Position.new(x, y)
      end
    end
    @positions[x][y]
  end
end

class Combat

  attr_reader :rounds

  Unit = Struct.new(:position, :type, :attack_power, :hit_points, :dead, :combat) do
    def x
      position.x
    end

    def y
      position.y
    end

    def enemies
      combat.enemies_of(self)
    end

    def attack_positions(targets = enemies)
      targets.flat_map { |target| combat.adjacent_to(target.position) }.uniq
    end

    def tick
      return if dead

      targets = enemies
      if targets.empty?
        return :done
      end

      adjacent_targets = adjacent_targets(targets)
      if adjacent_targets.any?
        attack(targets)
      else
        attack_positions = attack_positions(targets)
        return if move(attack_positions) == :unreachable

        attack(targets)
      end
    end

    def move(attack_positions)
      nearest_reachable_positions = nearest_reachable_positions(attack_positions)
      #puts "Reachable: #{nearest_reachable_positions}"
      if nearest_reachable_positions.empty?
        return :unreachable
      end

      chosen_position = first_position(nearest_reachable_positions)
      next_position = next_position(chosen_position)
      combat.move_unit(self, next_position)
    end

    def next_position(target_position)
      adjacent = combat.adjacent_to(position)
      paths = combat.discover(target_position, adjacent)
      paths = paths.select { |pos, _| adjacent.any? { |apos| pos == apos } }
      next_positions = paths.group_by { |_, depth| depth }.sort.first[1]
      first_position(next_positions)
    end

    def nearest_reachable_positions(attack_positions)
      all_positions = combat.discover(position, attack_positions)
      matching_positions = all_positions.select { |pos, _| attack_positions.any? { |apos|pos == apos } }
      if matching_positions.any?
        matching_positions.group_by { |_, depth| depth }.sort.first[1]
      else
        []
      end
    end

    def first_position(positions)
      positions.sort { |(p1, _), (p2, _)| p1.y != p2.y ? p1.y <=> p2.y : p1.x <=> p2.x }.first[0]
    end

    def attack(targets)
      adjacent_targets = adjacent_targets(targets)
      return :not_in_range unless adjacent_targets.any?

      targets = adjacent_targets.group_by { |target| target.hit_points }.sort.first[1]
      target = combat.sort_by_reading_order(targets).first
      combat.attack(self, target)
    end

    def adjacent_targets(targets)
      targets.select { |target| in_range?(target) }
    end

    def in_range?(target)
      position.adjacent.include?(target.position)
    end
  end

  def initialize(map, elf_attack_power)
    @map = map
    @units = []
    map.each.with_index do |row, y|
      row.each.with_index do |ch, x|
        if ch == 'E' || ch == 'G'
          attack_power = ch == 'E' ? elf_attack_power : 3
          @units << Unit.new(Position.create(x, y), ch, attack_power, 200, false, self)
        end
      end
    end
  end

  def run
    @rounds = 0
    loop do
      #puts "After #{@rounds}"
      #display_map
      units = sort_by_reading_order(living_units)
      units.each do |unit|
        return if unit.tick == :done
      end
      @rounds += 1
    end
  end

  def summarize
    puts "Rounds completed: #{@rounds}"
    hps = living_units.map(&:hit_points)
    puts "Hit points remaining: #{hps}, sum: #{hps.sum}"
    puts "Battle outcome: #{@rounds * hps.sum}"
  end

  def display_map
    @map.each do |row|
      puts "#{row.join}\n"
    end
  end

  def move_unit(unit, new_position)
    @map[unit.y][unit.x] = '.'
    @map[new_position.y][new_position.x] = unit.type
    unit.position = new_position
  end

  def attack(attacker, target)
    target.hit_points -= attacker.attack_power
    if target.hit_points <= 0
      target.dead = true
      @map[target.y][target.x] = '.'
    end
  end

  def discover(starting_position, search_for)
    _discover = ->(discovered_positions, discovered_set, search_for, array_position) do
      position, depth = discovered_positions[array_position]
      new_positions = adjacent_to(position).reject { |pos, _| discovered_set.include?(pos) }
      new_positions.each do |npos|
        discovered_positions << [npos, depth + 1]
        discovered_set << npos
      end

      # are we at the last discoverable position?
      return discovered_positions if array_position + 1 == discovered_positions.size

      # is the next position further away from the origin than the current one?
      if discovered_positions[array_position + 1][1] > discovered_positions[array_position][1]
        # have we found any of the positions we are searching for?
        if discovered_set.intersect?(search_for)
          #puts "Found some of the targets at depth #{depth}, bailing out"
          return discovered_positions
        end
        #puts "Not yet found any targets, moving to level #{depth + 1}"
      end

      _discover.call(discovered_positions, discovered_set, search_for, array_position + 1)
    end

    _discover.call([[starting_position, 0]], [starting_position].to_set, search_for.to_set.freeze, 0)
  end

  def living_units
    @units.reject(&:dead)
  end

  def all_elves_alive?
    @units.select { |unit| unit.type == 'E' }.none?(&:dead)
  end

  def enemies_of(unit)
    living_units.reject { |u| u.type == unit.type }
  end

  def on_map?(x, y)
    x.between?(0, @map.first.size - 1) && y.between?(0, @map.size - 1)
  end

  def open?(x, y)
    @map[y][x] == '.'
  end

  def adjacent_to(p)
    # used to .select { |p| on_map?(p.x, p.y) } #
    p.adjacent.select { |p| open?(p.x, p.y) }
  end

  def sort_by_reading_order(positions)
    positions.sort { |p1, p2| p1.y != p2.y ? p1.y <=> p2.y : p1.x <=> p2.x }
  end
end

def parse_combat(elf_attack_power)
  map = File.open('combat.txt').map(&:chomp).map(&:chars)
  Combat.new(map, elf_attack_power)
end

combat = parse_combat(3)
#report = MemoryProfiler.report do
#profile = StackProf.run(mode: :cpu, out: '/tmp/stackprof-cpu-day15.dump') do
  combat.run
#end
#end

combat.summarize

(4..30).each do |elf_attack_power|
  puts "Trying elf power: #{elf_attack_power}"
  combat = parse_combat(elf_attack_power)
  combat.run
  if combat.all_elves_alive?
    puts "Elf power #{elf_attack_power} is the lowest elf power required"
    combat.summarize
    break
  else
    puts "Need more elf power"
 end
end
