
def power_level(x, y, serial_number)
  @grid ||= Array.new(301) { Array.new(301, nil) }
  cached_result = @grid[x][y]
  return cached_result if cached_result

  rack_id = x + 10
  level = rack_id * y
  level += serial_number
  level *= rack_id
  level = level < 100 ? 0 : (level / 100) % 10
  level = level - 5
  @grid[x][y] = level
  level
end

def power_level_total(x, y, serial_number, size)
  total_power = 0
  (x..(x + size - 1)).each do |x|
    (y..(y + size - 1)).each do |y|
      total_power += power_level(x, y, serial_number)
    end
  end
  total_power
end

def grid(serial_number)
  max_power = -1000
  max_x = 0
  max_y = 0
  max_size = 0
  (1..300).each do |size|
    last = 300 - size + 1
    (1..last).each do |x|
      (1..last).each do |y|
        power_level = power_level_total(x, y, serial_number, size)
        if power_level > max_power
          p max_power = power_level
          p max_x = x
          p max_y = y
          p max_size = size
          puts
        end
      end
    end
  end
  [max_x, max_y, size]
end

serial_number = 8979
puts grid(serial_number)
