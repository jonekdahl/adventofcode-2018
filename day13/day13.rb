# frozen_string_literal: true

class Track
  attr_accessor :first_crash, :last_remaining

  def initialize(map, carts)
    @map = map
    @carts = carts
    @done = false
  end

  def tick!
    cart_order = @carts.sort { |c1, c2| c1.y != c2.y ? c1.y <=> c2.y : c1.x <=> c2.x  }
    cart_order.each do |cart|
      next if cart.crashed?

      cart.tick!
      cart.turn_at_intersection if intersection_at?(cart.x, cart.y)
      cart.turn_at_curve(part_at(cart.x, cart.y)) if curve_at?(cart.x, cart.y)
      colliding_carts = carts_at(cart.x, cart.y)
      if colliding_carts.size > 1
        colliding_carts.each(&:crashed!)
        @first_crash ||= [cart.x, cart.y]
      end
    end

    if active_carts.size == 1
      @last_remaining = [active_carts.first.x, active_carts.first.y]
      return :done
    end
  end

  def part_at(x, y)
    @map[y][x]
  end

  def active_carts
    @carts.reject(&:crashed?)
  end

  def carts_at(x, y)
    carts = active_carts.select { |cart| cart.at?(x, y) }
  end

  def curve_at?(x, y)
    ['\\', '/'].include?(part_at(x, y))
  end

  def intersection_at?(x, y)
    part_at(x, y) == '+'
  end

  def run
    until tick! == :done
    end
  end

  def print
    @map.each.with_index do |row, y|
      row.each.with_index do |part, x|
        cart = @carts.detect { |cart| cart.at?(x, y) }
        printf "#{cart ? cart.direction : part}"
      end
      puts
    end
  end
end

class Cart
  attr_reader :x, :y, :direction

  def initialize(x, y, direction)
    @x = x
    @y = y
    @direction = direction
    @intersections = 0
    @crashed = false
  end

  def at?(x, y)
    self.x == x && self.y == y
  end

  def crashed!
    @crashed = true
  end

  def crashed?
    @crashed
  end

  def tick!
    if @direction == '<'
      @x -= 1
    elsif @direction == '>'
      @x += 1
    elsif @direction == '^'
      @y -= 1
    elsif @direction == 'v'
      @y += 1
    end
  end

  def turn_at_intersection
    @intersections += 1
    if @intersections % 3 == 1
      turn_left
    elsif @intersections % 3 == 0
      turn_right
    end
  end

  def turn_at_curve(curve)
    if @direction == '<'
      if curve == '/'
        @direction = 'v'
      elsif curve == '\\'
        @direction = '^'
      end
    elsif @direction == 'v'
      if curve == '/'
        @direction = '<'
      elsif curve == '\\'
        @direction = '>'
      end
    elsif @direction == '>'
      if curve == '/'
        @direction = '^'
      elsif curve == '\\'
        @direction = 'v'
      end
    elsif @direction == '^'
      if curve == '/'
        @direction = '>'
      elsif curve == '\\'
        @direction = '<'
      end
    end
  end

  def turn_left
    if @direction == '<'
      @direction = 'v'
    elsif @direction == 'v'
      @direction = '>'
    elsif @direction == '>'
      @direction = '^'
    elsif @direction == '^'
      @direction = '<'
    end
  end

  def turn_right
    if @direction == '<'
      @direction = '^'
    elsif @direction == '^'
      @direction = '>'
    elsif @direction == '>'
      @direction = 'v'
    elsif @direction == 'v'
      @direction = '<'
    end
  end
end

def parse_track
  map = {
    '<' => '-',
    '>' => '-',
    '^' => '|',
    'v' => '|',
  }
  carts = []
  map = File.open('track.txt').map.with_index do |line, y|
    line.chomp.chars.map.with_index do |ch, x|
      carts << Cart.new(x, y, ch) if map.keys.include?(ch)
      map.fetch(ch, ch)
    end
  end
  track = Track.new(map, carts)
end

track = parse_track
#track.print
track.run
puts "First crash occurs at #{track.first_crash}"
puts "When all other carts have crashed, the remaining cart is at #{track.last_remaining} "
