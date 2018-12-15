
Coord = Struct.new(:x, :y) do
  def distance(x, y)
    (self.x - x).abs + (self.y - y).abs
  end

  def inspect
    to_s
  end

  def to_s
    "[#{x}, #{y}]"
  end
end

def parse_coords
  File.open('coordinates.txt').map do |line|
    params = line.split(', ').map(&:chomp).map { |str| Integer(str) }
    Coord.new(*params)
  end
end

class Board
  def initialize(coords)
    @coords = coords
    init_board
  end

  def init_board
    @width = @coords.map(&:x).max + 1
    @height = @coords.map(&:y).max + 1
    @board = Array.new(@width) { Array.new(@height) }
  end

  def closest_coord(x, y)
    distances = @coords.map { |coord| [coord, coord.distance(x, y)] }.to_h
    min_distance = distances.values.min
    min_coords = distances.select { |_, distance| distance == min_distance }
    min_coords.size == 1 ? min_coords.keys.first : nil
  end

  def fill_closest_coord!
    (0..@width - 1).each do |x|
      (0..@height - 1).each do |y|
        @board[x][y] = closest_coord(x, y)
        #puts "[#{x}, #{y}]: closest coord is #{@board[x][y] || 'nil'}"
      end
    end
  end

  def edge?(x, y)
    x == 0 || y == 0 || x == @width - 1 || y == @height - 1
  end

  def area(coord)
    area = 0
    (0..@width - 1).each do |x|
      (0..@height - 1).each do |y|
        if @board[x][y] == coord
          area += 1
          return nil if edge?(x, y)
        end
      end
    end
    area
  end

  def largest_area
    self.fill_closest_coord!
    @coords.map { |c| area(c) }.compact.max
  end

  def total_distance(x, y)
    @coords.sum { |c| c.distance(x, y) }
  end

  def largest_region(max_total_distance)
    area = 0
    (0..@width - 1).each do |x|
      (0..@height - 1).each do |y|
        area += 1 if total_distance(x, y) <= max_total_distance
      end
    end
    area
  end
end

coords = parse_coords
board = Board.new(coords)
puts "Largest area: #{board.largest_area}"
puts "Largest region: #{board.largest_region(9999)}"
