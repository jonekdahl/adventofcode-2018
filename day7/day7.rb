
class Instructions

  def initialize
    @steps = Hash.new { |hash, step_name| hash[step_name] = Step.new(step_name) }
  end

  def add(before:, after:)
    step_before = @steps[before]
    step_after = @steps[after]
    step_after.add_prerequisite(step_before)
  end

  def next_steps
    @steps.values.reject(&:done?).select(&:prerequisites_completed?).sort_by(&:name)
  end

  def order_of_steps
    order = +""
    until all_steps_done?
      next_steps.first.tap do |step|
        step.done!
        order << step.name
      end
    end
    order
  end

  def all_steps_done?
    @steps.values.all?(&:done?)
  end
end

class Step

  attr_reader :name, :prerequisites

  def initialize(name)
    @name = name
    @done = false
    @prerequisites = []
    @remaining_work = duration
  end

  def done!
    @done = true
  end

  def done?
    @done
  end

  def started?
    @remaining_work < duration
  end

  def add_prerequisite(step)
    @prerequisites << step
  end

  def prerequisites_completed?
    @prerequisites.all?(&:done?)
  end

  def duration
    60 + (name.ord - 'A'.ord + 1)
  end

  def work
    raise "No work remaining" if done?

    @remaining_work -= 1
    done! if @remaining_work == 0
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

class WorkForce

  class Worker
    attr_accessor :step

    def initialize
      @step = nil
    end

    def idle?
      @step.nil?
    end

    def assign(step)
      @step = step
    end

    def work
      return unless step

      @step.work
      @step = nil if step.done?
    end
  end

  def initialize(num_workers:)
    @workers = (1..num_workers).map { Worker.new }
    @time = 0
  end

  def work
    idle_workers = @workers.select(&:idle?)
    next_steps = @instructions.next_steps.reject(&:started?)
    job_count = [idle_workers.size, next_steps.size].min
    idle_workers[0..job_count - 1].zip(next_steps[0..job_count - 1]).each do |worker, step|
      worker.assign(step)
    end
    @workers.each { |w| w.work }
    @time += 1
  end

  def execute(instructions)
    @instructions = instructions
    work until @instructions.all_steps_done?
    @time
  end
end

# Part one
instructions = parse_instructions
puts "Order of steps: #{instructions.order_of_steps}"

# Part two
instructions = parse_instructions
work_force = WorkForce.new(num_workers: 5)
puts "Time to execute instructions: #{work_force.execute(instructions)}"
