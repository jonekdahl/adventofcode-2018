
scores = [3, 7]
current_recipies = [0, 1]

def cook_and_move(scores, current_recipies)
  total_score = current_recipies.map { |cur| scores[cur] }.sum
  scores.concat(total_score.digits.reverse)
  current_recipies.each.with_index do |cur, elf|
    steps = 1 + scores[cur]
    current_recipies[elf] = (cur + steps) % scores.size
  end
end

def find(pattern, scores)
  def pattern_occurs_at(pattern, scores, start_idx)
    pattern.each.with_index do |score, idx|
      return false unless scores[start_idx + idx] == score
    end
    true
  end

  start_idx = scores.size - pattern.size - 1
  end_idx = scores.size - pattern.size
  return unless start_idx >= 0 && end_idx >= 0

  (start_idx..end_idx).each do |idx|
    return idx if pattern_occurs_at(pattern, scores, idx)
  end
  return nil
end

input = 293801.digits.reverse # 293801

until (needle = find(input, scores)) do
  cook_and_move(scores, current_recipies)
end

#puts "After #{input} iterations, the following 10 scores are #{scores[input..(input + 9)].join}"
puts "There are #{needle} recepies before the pattern #{input} occurs the first time"
