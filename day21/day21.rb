# frozen_string_literal: true

require 'set'

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

  def pc=(value)
    @regs[@pc] = value
  end

  def to_s
    "PC=#{pc.to_s.rjust(2, "0")}, regs=[#{@regs.map.with_index { |val, idx| idx == @pc ? '_' : val}.join(', ')}]"
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

def print_program(instructions, profile, pc_reg, registers)
  instructions.each.with_index do |i, line_nr|
    cur = registers.pc == line_nr
    s = +""
    s << (cur ? "PC " : "   ")
    if i.opcode_name == 'seti' || i.opcode_name == 'setr'
      s << "#{line_nr.to_s.rjust(2, "0")} #{profile[line_nr].to_s.rjust(8, "0")} #{i.opcode_name} #{i.a} _ #{i.c}"
    else
      s << "#{line_nr.to_s.rjust(2, "0")} #{profile[line_nr].to_s.rjust(8, "0")} #{i.opcode_name} #{i.a} #{i.b} #{i.c}"
    end
    if i.c == pc_reg
      if i.opcode_name == 'addi' && (i.a == pc_reg || i.b == pc_reg)
        steps = i.a == pc_reg ? i.b : i.a
        s << " - relative jump, to instruction #{line_nr + steps + 1}"
      elsif i.opcode_name == 'addr'
        reg = i.a == pc_reg ? i.b : i.a
        s << " - relative jump, r[#{reg}]#{cur ? "=#{registers[reg]}" : ""} steps"
      elsif i.opcode_name == 'setr'
        if i.a == pc_reg
          s << " - absolute jump"
        else
          s << " - absolute jump, #{i.b} steps"
        end
      elsif i.opcode_name == 'seti'
        s << " - jump to instruction #{i.a + 1}"
      else
        s << " - modifies pc"
      end
    elsif i.opcode_name == 'seti'
      s << " - store #{i.a} in r[#{i.c}]"
    elsif i.opcode_name == 'mulr'
      s << " - multiply r[#{i.a}] with r[#{i.b}], store in r[#{i.c}]"
    elsif i.opcode_name == 'addr'
      s << " - add r[#{i.a}]#{cur ? "=" + registers[i.a].to_s : ""} with r[#{i.b}]#{cur ? "=" + registers[i.b].to_s : ""}, store in r[#{i.c}]"
    elsif i.opcode_name == 'eqrr'
      s << " - if r[#{i.a}] == r[#{i.b}], set r[#{i.c}] = 1"
    elsif i.opcode_name == 'bani'
      s << " - r[#{i.a}]#{cur ? "=" + registers[i.a].to_s(16) : ""} & #{i.b.to_s(16)} (bitwise AND)"
    elsif i.opcode_name == 'bori'
      s << " - r[#{i.a}]#{cur ? "=" + registers[i.a].to_s(16) : ""} | #{i.b.to_s(16)} (bitwise OR)"
    end
    puts s
  end
end

pc_reg, instructions = parse_program

def execute_instruction(opcodes, registers, instructions, profile)
  # Straight Ruby implementation of hot loop
  if registers.pc == 18
    r = registers
    loop do
      r[3] = r[4] + 1     # 18 addi 4 1 3
      r[3] = r[3] << 8    # 19 muli 3 256 3
      if r[3] > r[5]      # 20 gtrr 3 5 3, 21 addr 3 1 1, 22 addi 1 1 1
        break             # 23 seti 25 _ 1 - jump to instruction 26 (exit subroutine)
      else                # 22 addi 1 1 1 - relative jump, to instruction 24
        r[4] = r[4] + 1   # 24 addi 4 1 4
      end
    end                   # 25 seti 17 _ 1 - jump to instruction 18
    registers.pc = 26
  else
    profile[registers.pc] += 1
    instruction = instructions[registers.pc]
    opcode = opcodes[instruction.opcode_name]
    opcode.exec(registers, instruction.a, instruction.b, instruction.c)
    registers.increment_pc
  end
end

def run(r0, pc_reg, instructions, opcodes)
  profile = Array.new(instructions.size, 0)
  instruction_count = 0
  last_halting_number = nil
  seen = Set.new
  registers = Registers.new([r0, 0, 0, 0, 0, 0], pc_reg)
  until registers.pc > instructions.size - 1 # || registers.pc == 28
    #if instruction_count % 1_000 == 0
    #  puts "\nAfter execution of #{instruction_count} instructions: #{registers}"
    #  print_program(instructions, profile, pc_reg, registers)
    #end
    if registers.pc == 28
      halting_number = registers[2]
      break if seen.include?(halting_number) # have we seen this value before

      puts "halting numbers found: #{seen.size}" if seen.size % 1000 == 0
      last_halting_number = halting_number
      seen << halting_number
    end
    instruction_count += 1
    execute_instruction(opcodes, registers, instructions, profile)
  end
  #puts "\nAfter execution of #{instruction_count} instructions: #{registers}"
  #print_program(instructions, profile, pc_reg, registers)
  [instruction_count, last_halting_number]
end


r0 = 0 # 8797248 # found by halting the program at line 28
instruction_count, last_halting_number = run(r0, pc_reg, instructions, opcodes)
#puts "With r0=#{r0}, the program halts after #{instruction_count} instructions"
puts "The last halting number before repetition wae #{last_halting_number}"
