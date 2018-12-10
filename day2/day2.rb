require 'set'

def parse_box_ids
  File.open('box_ids.txt').map { |line| line.chomp! }
end

def letter_freq(id)
  letters = Hash.new { |hash, key| hash[key] = 0 }
  id.each_char { |letter| letters[letter] += 1 }
  letters
end

def freq?(letters, freq)
  letters.values.any? { |f| f == freq }
end

def checksum(box_ids)
  twice_count = 0
  thrice_count = 0

  box_ids.each do |id|
    letters = letter_freq(id)
    twice_count += 1 if freq?(letters, 2)
    thrice_count += 1 if freq?(letters, 3)
  end

  twice_count * thrice_count
end

box_ids = parse_box_ids
checksum = checksum(box_ids)
puts "Checksum: #{checksum}"


def differing_letters(b1, b2)
  b1.each_char.zip(b2.each_char).reduce(0) { |acc, pair| acc += (pair[0] == pair[1] ? 0 : 1) }
end

def similar_box_ids(box_ids)
  box_ids.each do |b1|
    box_ids.each do |b2|
      return [b1, b2] if differing_letters(b1, b2) == 1
    end
  end
end

puts "Similar ids: #{similar_box_ids(box_ids)}"
