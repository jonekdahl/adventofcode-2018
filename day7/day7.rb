
class Instructions

  def initialize
    @steps = Hash.new { |hash, step_name| hash[step_name] = Step.new(step_name) }
  end

  def add(before:, after:)
    step_before = @steps[before]
    step_after = @steps[after]
    step_after.add_prerequisite(step_before)
  end

  def next_step
    @steps.values.reject(&:done?).select(&:prerequisites_completed?).sort_by(&:name).first
  end

  def order_of_steps
    order = +""
    until @steps.values.all?(&:done?)
      next_step.tap do |step|
        step.done!
        order << step.name
      end
    end
    order
  end
end

class Step

  attr_reader :name, :prerequisites

  def initialize(name)
    @name = name
    @done = false
    @prerequisites = []
  end

  def done!
    @done = true
  end

  def done?
    @done
  end

  def add_prerequisite(step)
    @prerequisites << step
  end

  def prerequisites_completed?
    @prerequisites.all?(&:done?)
  end
end

def parse_instructions
  Instructions.new.tap do |instructions|
    regex = /Step ([A-Z]) must be finished before step ([A-Z]) can begin./
      File.open('instructions.txt').map do |line|
      m = line.match(regex)
      instructions.add(before: m[1], after: m[2])
    end
  end
end

instructions = parse_instructions
puts "Order of steps: #{instructions.order_of_steps}"
