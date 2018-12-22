
Position = Struct.new(:x, :y)

Velocity = Struct.new(:x, :y)

Light = Struct.new(:position, :velocity) do
  def move!
    position.x += velocity.x
    position.y += velocity.y
  end

  def move_back!
    position.x -= velocity.x
    position.y -= velocity.y
  end
end

def parse_initial_positions
  regex = /<(.+),(.+)>.*<(.+),(.+)>/
  File.open('positions.txt').map do |line|
    matcher = line.match(regex)
    ints = matcher[1..-1].map { |s| Integer(s) }
    Light.new(Position.new(ints[0], ints[1]), Velocity.new(ints[2], ints[3]))
  end
end

class Sky

  attr_reader :lights
  attr_reader :moves

  def initialize(lights)
    @lights = lights
    @moves = 0
  end

  def move!
    @lights.each { |light| light.move! }
    @moves += 1
  end

  def move_back!
    @lights.each { |light| light.move_back! }
    @moves -= 1
  end

  def area
    bounding_box.area
  end

  def display
    box = bounding_box
    (box.top..box.bottom).each do |y|
      (box.left..box.right).each do |x|
        print light_at_position?(Position.new(x, y)) ? '#' : '.'
      end
      puts
    end
  end

  private

  BoundingBox = Struct.new(:top, :bottom, :left, :right) do
    def height
      bottom - top
    end

    def width
      right - left
    end

    def area
      height * width
    end
  end

  def bounding_box
    min_x = max_x = @lights.first.position.x
    min_y = max_y = @lights.first.position.y
    @lights.each do |light|
      pos = light.position
      min_x = pos.x < min_x ? pos.x : min_x
      min_y = pos.y < min_y ? pos.y : min_y
      max_x = pos.x > max_x ? pos.x : max_x
      max_y = pos.y > max_y ? pos.y : max_y
    end
    BoundingBox.new.tap do |box|
      box.left = min_x
      box.right = max_x
      box.top = min_y
      box.bottom = max_y
    end
  end

  def light_at_position?(position)
    @lights.any? { |light| light.position == position }
  end
end

lights = parse_initial_positions
sky = Sky.new(lights)

previous_area = sky.area
loop do
  sky.move!
  current_area = sky.area
  if current_area > previous_area
    sky.move_back!
    break
  end
  previous_area = current_area
end

sky.display
puts "The message will appear after #{sky.moves} seconds"
