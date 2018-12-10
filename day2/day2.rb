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
#box_ids = %w(abcdef bababc abbcde abcccd aabcdd abcdee ababab)
checksum = checksum(box_ids)
puts "Checksum: #{checksum}"
