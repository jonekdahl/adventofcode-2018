# frozen_string_literal: true

#require 'memory_profiler'

Instruction = Struct.new(:opcode_name, :a, :b, :c)

class Registers
  def initialize(regs, pc_reg)
    @pc = pc_reg
    @regs = regs
  end

  def [](reg)
    @regs[reg]
  end

  def []=(reg, value)
    @regs[reg] = value
  end

  def increment_pc
    @regs[@pc] += 1
  end

  def pc
    @regs[@pc]
  end
end

Opcode = Struct.new(:name, :func) do
  def exec(regs, a, b, c)
    func.call(regs, a, b, c)
  end
end

opcodes = {
  'addr' => Opcode.new('addr', lambda { |regs, a, b, c| regs[c] = regs[a] + regs[b] }),
  'addi' => Opcode.new('addi', lambda { |regs, a, b, c| regs[c] = regs[a] + b }),

  'mulr' => Opcode.new('mulr', lambda { |regs, a, b, c| regs[c] = regs[a] * regs[b] }),
  'muli' => Opcode.new('muli', lambda { |regs, a, b, c| regs[c] = regs[a] * b }),

  'banr' => Opcode.new('banr', lambda { |regs, a, b, c| regs[c] = regs[a] & regs[b] }),
  'bani' => Opcode.new('bani', lambda { |regs, a, b, c| regs[c] = regs[a] & b }),

  'borr' => Opcode.new('borr', lambda { |regs, a, b, c| regs[c] = regs[a] | regs[b] }),
  'bori' => Opcode.new('bori', lambda { |regs, a, b, c| regs[c] = regs[a] | b }),

  'setr' => Opcode.new('setr', lambda { |regs, a, _, c| regs[c] = regs[a] }),
  'seti' => Opcode.new('seti', lambda { |regs, a, _, c| regs[c] = a }),

  'gtir' => Opcode.new('gtir', lambda { |regs, a, b, c| regs[c] = a > regs[b] ? 1 : 0 }),
  'gtri' => Opcode.new('gtri', lambda { |regs, a, b, c| regs[c] = regs[a] > b ? 1 : 0 }),
  'gtrr' => Opcode.new('gtrr', lambda { |regs, a, b, c| regs[c] = regs[a] > regs[b] ? 1 : 0 }),

  'eqir' => Opcode.new('eqir', lambda { |regs, a, b, c| regs[c] = a == regs[b] ? 1 : 0 }),
  'eqri' => Opcode.new('eqri', lambda { |regs, a, b, c| regs[c] = regs[a] == b ? 1 : 0 }),
  'eqrr' => Opcode.new('eqrr', lambda { |regs, a, b, c| regs[c] = regs[a] == regs[b] ? 1 : 0 }),
}

def parse_program
  lines = File.open('program.txt').map(&:chomp)
  pc_reg = Integer(lines[0][4..-1])
  instruction_regex = /^([a-z]+) (\d+) (\d+) (\d+)/
  instructions = lines[1..-1].map do |line|
    matcher = line.match(instruction_regex)
    instruction = Instruction.new(matcher[1], *matcher[2..-1].map { |s| Integer(s) })
  end
  [pc_reg, instructions]
end

pc_reg, instructions = parse_program

def execute_instruction(opcodes, registers, instructions)
  instruction = instructions[registers.pc]
  opcode = opcodes[instruction.opcode_name]
  opcode.exec(registers, instruction.a, instruction.b, instruction.c)
  registers.increment_pc
end

#MemoryProfiler.report do
registers = Registers.new([0, 0, 0, 0, 0, 0], pc_reg)
until registers.pc > instructions.size - 1
  execute_instruction(opcodes, registers, instructions)
end
puts "The value in register 0 is #{registers[0]}"
#end.pretty_print

registers = Registers.new([1, 0, 0, 0, 0, 0], pc_reg)
until registers.pc > instructions.size - 1
  execute_instruction(opcodes, registers, instructions)
end

puts "The value in register 0 is #{registers[0]}"
