
require 'byebug'

Point = Struct.new(:coords) do
  def distance(other)
    (self.coords[0] - other.coords[0]).abs +
      (self.coords[1] - other.coords[1]).abs +
      (self.coords[2] - other.coords[2]).abs +
      (self.coords[3] - other.coords[3]).abs
  end
end

class Constellation
  attr_reader :points

  def initialize(points = [])
    @points = points
  end

  def join(other)
    @points += other.points
    self
  end

  def distance(point)
    @points.min_by { |p| p.distance(point) }.distance(point)
  end
end

def parse(file)
  File.open(file).map do |line|
    Point.new(line.chomp.split(',').map { |s| Integer(s) })
  end
end

def create_constellations(points)
  constellations = []
  points.each do |point|
    close_to = constellations.select { |constellation| constellation.distance(point) <= 3 }
    if close_to.size == 0
      constellations << Constellation.new([point])
    elsif close_to.size == 1
      close_to.first.points << point
    else
      target_constellation = close_to.first
      other_constellations = close_to[1..-1]
      other_constellations.each do |c|
        constellations.delete(c)
        target_constellation.join(c)
      end
      target_constellation.points << point
    end
  end
  constellations
end

points = parse('points.txt')
constellations = create_constellations(points)
puts "Number of constellations: #{constellations.size}"
