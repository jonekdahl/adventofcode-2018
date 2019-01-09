
Instruction = Struct.new(:opcode_nr, :a, :b, :c)

Opcode = Struct.new(:name, :func) do
  def exec(regs, a, b, c)
    func.call(regs, a, b, c)
  end
end

Sample = Struct.new(:before, :instruction, :after) do
  def behave_like?(opcode)
    regs = before.clone
    opcode.exec(regs, instruction.a, instruction.b, instruction.c)
    regs == after
  end
end

opcodes = [
  Opcode.new('addr', lambda { |regs, a, b, c| regs[c] = regs[a] + regs[b] }),
  Opcode.new('addi', lambda { |regs, a, b, c| regs[c] = regs[a] + b }),

  Opcode.new('mulr', lambda { |regs, a, b, c| regs[c] = regs[a] * regs[b] }),
  Opcode.new('muli', lambda { |regs, a, b, c| regs[c] = regs[a] * b }),

  Opcode.new('banr', lambda { |regs, a, b, c| regs[c] = regs[a] & regs[b] }),
  Opcode.new('bani', lambda { |regs, a, b, c| regs[c] = regs[a] & b }),

  Opcode.new('borr', lambda { |regs, a, b, c| regs[c] = regs[a] | regs[b] }),
  Opcode.new('bori', lambda { |regs, a, b, c| regs[c] = regs[a] | b }),

  Opcode.new('setr', lambda { |regs, a, _, c| regs[c] = regs[a] }),
  Opcode.new('seti', lambda { |regs, a, _, c| regs[c] = a }),

  Opcode.new('gtir', lambda { |regs, a, b, c| regs[c] = a > regs[b] ? 1 : 0 }),
  Opcode.new('gtri', lambda { |regs, a, b, c| regs[c] = regs[a] > b ? 1 : 0 }),
  Opcode.new('gtrr', lambda { |regs, a, b, c| regs[c] = regs[a] > regs[b] ? 1 : 0 }),

  Opcode.new('eqir', lambda { |regs, a, b, c| regs[c] = a == regs[b] ? 1 : 0 }),
  Opcode.new('eqri', lambda { |regs, a, b, c| regs[c] = regs[a] == b ? 1 : 0 }),
  Opcode.new('eqrr', lambda { |regs, a, b, c| regs[c] = regs[a] == regs[b] ? 1 : 0 }),
]

def parse_samples
  before = nil
  instruction = nil
  after = nil
  samples = []
  before_regex = /Before: \[(\d+), (\d+), (\d+), (\d+)\]/
  instruction_regex = /^(\d+) (\d+) (\d+) (\d+)/
  after_regex = /After:  \[(\d+), (\d+), (\d+), (\d+)\]/
  File.open('samples.txt').each_line do |line|
    if matcher = line.match(before_regex)
      before = matcher[1..-1].map { |s| Integer(s) }
    elsif matcher = line.match(instruction_regex)
      instruction = Instruction.new(*matcher[1..-1].map { |s| Integer(s) })
    elsif matcher = line.match(after_regex)
      after = matcher[1..-1].map { |s| Integer(s) }
      samples << Sample.new(before, instruction, after)
    end
  end
  samples
end

def parse_program
  instruction_regex = /^(\d+) (\d+) (\d+) (\d+)/
  File.open('test_program.txt').map do |line|
    matcher = line.match(instruction_regex)
    instruction = Instruction.new(*matcher[1..-1].map { |s| Integer(s) })
  end
end


samples = parse_samples
three_or_more = samples.count { |sample| opcodes.count { |opcode| sample.behave_like?(opcode) } >= 3 }
puts "#{three_or_more} samples behaves like three or more opcodes"

opcodes_by_nr = Array.new(opcodes.size)
until opcodes.empty? do
  mappings = samples.map { |sample| [sample, opcodes.select { |opcode| sample.behave_like?(opcode) }] }
  mappings.select { |_, matching_opcodes| matching_opcodes.size == 1 }
    .each do |sample, matching_opcodes|
      samples.delete(sample)
      opcode_nr = sample.instruction.opcode_nr
      next if opcodes_by_nr[opcode_nr]

      opcodes_by_nr[opcode_nr] = matching_opcodes.first
      opcodes.delete(matching_opcodes.first)
  end
end

program_instructions = parse_program

registers = [0, 0, 0, 0]
program_instructions.each do |instruction|
  opcode = opcodes_by_nr[instruction.opcode_nr]
  opcode.exec(registers, instruction.a, instruction.b, instruction.c)
end

puts "The value in register 0 after execution: #{registers[0]}"
