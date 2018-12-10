
Claim = Struct.new(:index, :left, :top, :width, :height) do
  def occupies?(x, y)
    x.between?(left, right) && y.between?(top, bottom)
  end

  def right
    left + width - 1
  end

  def bottom
    top + height - 1
  end
end


# Example claim: '#1 @ 432,394: 29x14'
def parse_claims
  regex = /#(\d+) @ (\d+),(\d+): (\d+)x(\d+)/
  File.open('claims.txt').map do |line|
    m = line.match(regex)
    params = m.to_a[1..-1].map { |str| Integer(str) }
    Claim.new(*params)
  end
end

def record_claims!(claims, fabric)
  claims.each do |claim|
    (claim.top..claim.bottom).flat_map do |y|
      (claim.left..claim.right).map do |x|
        fabric[x][y] += 1
      end
    end
  end
end

def count_multi_claim(fabric)
  count = 0
  (0..999).flat_map do |y|
    (0..999).map do |x|
      count += 1 if fabric[x][y] >= 2
    end
  end
  count
end


fabric = Array.new(1000) { Array.new(1000, 0) }

claims = parse_claims
record_claims!(claims, fabric)
puts count_multi_claim(fabric)

def non_overlapping_claim?(claim, fabric)
  (claim.top..claim.bottom).each do |y|
    (claim.left..claim.right).each do |x|
      return false unless fabric[x][y] == 1
    end
  end
  true
end

def find_claim(claims, fabric)
  claims.detect { |claim| non_overlapping_claim?(claim, fabric) }
end

puts find_claim(claims, fabric)
