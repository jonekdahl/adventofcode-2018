
# Ruby version of https://github.com/msullivan/advent-of-code/blob/master/2018/23b.py

require 'z3'
require 'byebug'

Position = Struct.new(:x, :y, :z) do
  def distance(pos)
    (x - pos.x).abs + (y - pos.y).abs + (z - pos.z).abs
  end
end

Bot = Struct.new(:position, :signal_radius)

def parse(file)
  regex = /pos=\<(-?\d+),(-?\d+),(-?\d+)\>, r=(\d+)/ # pos=<0,0,0>, r=4
  File.open(file).map do |line|
    m = regex.match(line)
    ints = m[1..-1].map { |s| Integer(s) }
    Bot.new(Position.new(*ints[0..2]), ints[3])
  end
end

def z3_abs(a)
  Z3::IfThenElse(a >= 0, a, -a)
end

def z3_dist(p1, p2)
  z3_abs(p1.x - p2.x) + z3_abs(p1.y - p2.y) + z3_abs(p1.z - p2.z)
end

class Solver
  def initialize(bots)
    @bots = bots
  end

  def run
    x = Z3::Int('x')
    y = Z3::Int('y')
    z = Z3::Int('z')
    orig = Position.new(x, y, z)
    cost = Z3::Int('cost')
    cost_expr = x * 0
    @bots.each do |bot|
      cost_expr += Z3::IfThenElse(z3_dist(orig, bot.position) <= bot.signal_radius, 1, 0)
    end
    opt = Z3::Optimize.new
    puts "let's go"
    opt.assert(cost == cost_expr)
    opt.maximize(cost)
    opt.minimize(z3_dist(Position.new(0, 0, 0), Position.new(x, y, z)))
    opt.check
    model = opt.model
    pp model
    pos = Position.new(model[x].to_i, model[y].to_i, model[z].to_i)
    puts "position: #{pos}"
    puts "num in range: #{model[cost].to_i}"
    puts "distance: #{Position.new(0, 0, 0).distance(pos)}"
  end
end

bots = parse('nanobots.txt')

Solver.new(bots).run
