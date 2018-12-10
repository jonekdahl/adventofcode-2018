require 'set'

def parse_changes
  File.open('frequency_changes.txt').map { |line| Integer(line.chomp!) }
end

def first_recurring(changes)
  freq = 0
  frequencies = Set.new

  changes.cycle do |change|
    frequencies << freq
    freq += change

    if frequencies.include? freq
      return freq
    end
  end
  return nil
end

changes = parse_changes
puts "Resulting frequency: #{changes.sum}"

puts puts "First recurring frequency: #{first_recurring(changes)}"

