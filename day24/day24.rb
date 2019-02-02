# frozen_string_literal: true

require 'byebug'
require 'memory_profiler'

IMMUNE_SYSTEM = "Immune System"
INFECTION = "Infection"

Group = Struct.new(:army, :count, :units, :hit_points, :immunities, :weaknesses, :attack_damage, :attack_type, :initiative) do
  def effective_power
    units * attack_damage
  end

  def take_damage(damage)
     units_lost = [damage / hit_points, self.units].min
     self.units -= units_lost
     units_lost
  end

  def to_s
    "Group #{count} contains #{units} units"
  end
end

class Simulation
  def initialize(armies)
    @immune_system = armies[IMMUNE_SYSTEM].map(&:dup)
    @infection = armies[INFECTION].map(&:dup)
  end

  def run(boost)
    @immune_system.each { |group| group.attack_damage += boost }
    until @immune_system.empty? || @infection.empty?
      #print_armies
      fight
      @immune_system.select! { |group| group.units.positive? }
      @infection.select! { |group| group.units.positive? }
    end
    @immune_system.any? ? [IMMUNE_SYSTEM, @immune_system.sum(&:units)] : [INFECTION, @infection.sum(&:units)]
  end

  def print_armies
    puts
    puts "Immune system:"
    puts @immune_system
    puts "Infection:"
    puts @infection
    puts
  end

  def fight
    selected_targets = select_targets
    #puts
    attack(selected_targets)
  end

  def select_targets
    attackers = (@immune_system + @infection).sort_by { |g| [-g.effective_power, -g.initiative] }
    targets = attackers.clone
    attackers.map do |attacker|
      target, _ = targets.map do |target|
                           next if target.army == attacker.army
                           damage = damage(attacker, target)
                           #puts "#{attacker.army} group #{attacker.count} would deal defending group #{target.count} #{damage} damage"
                           next if damage == 0
                           [target, damage]
                         end
                         .tap     { |ary| ary.compact! }
                         .sort_by { |target, damage| [-damage, -target.effective_power, -target.initiative] }
                         .first
     next unless target

      targets.delete(target)
      [attacker, target]
    end.compact
  end

  def attack(selected_targets)
    selected_targets.sort_by { |attacker, _| -attacker.initiative }
                    .each do |attacker, target|
      next unless attacker.units.positive?

      units_lost = target.take_damage(damage(attacker, target))
      #puts "#{attacker.army} group #{attacker.count} attacks defending group #{target.count}, killing #{units_lost} units"
    end
  end

  def damage(attacker, target)
    if target.immunities.include?(attacker.attack_type)
      0
    elsif target.weaknesses.include?(attacker.attack_type)
      attacker.effective_power * 2
    else
      attacker.effective_power
    end
  end
end

def parse_armies
  armies = {
    IMMUNE_SYSTEM => [],
    INFECTION => [],
  }
  army = nil
  count = 0
  group_regex = /(\d+) units each with (\d+) hit points (?:\((.*)\) )?with an attack that does (\d+) (\S+) damage at initiative (\d+)/
  parenthesis_regex = //
  File.open('armies.txt').each do |line|
    next if line.chomp.empty?

    if line.start_with?("Immune System:")
      count = 0
      army = IMMUNE_SYSTEM
    elsif line.start_with?("Infection:")
      count = 0
      army = INFECTION
    else
      count += 1
      m = group_regex.match(line)
      byebug unless m
      units = Integer(m[1])
      hit_points = Integer(m[2])
      attack_damage = Integer(m[4])
      attack_type = m[5]
      initiative = Integer(m[6])
      immunities = []
      weaknesses = []
      if m[3]
        m[3].split('; ').each do |option| # 'weak to fire, ice'
          if option.start_with?('immune')
            immunities = option.sub('immune to ', '').split(', ')
          else
            weaknesses = option.sub('weak to ', '').split(', ')
          end
        end
      end
      armies[army] << Group.new(army, count, units, hit_points, immunities, weaknesses, attack_damage, attack_type, initiative)
    end
  end
  armies
end

def sim(armies, boost)
  Simulation.new(armies).run(boost)
end

winning_army = nil
armies = parse_armies
boost = 31 # at boost 30, there was a stand-off causing the simulation to run forever

until winning_army == IMMUNE_SYSTEM
  winning_army, units_remaining = *sim(armies, boost)
  puts "With boost #{boost}, the #{winning_army} has #{units_remaining} units remaining"
  boost += 1
end



