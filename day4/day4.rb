require 'time'

Event = Struct.new(:time, :what) do
end

Shift = Struct.new(:guard, :sleep_intervals) do

  def add_interval(s, e)
    self.sleep_intervals << [s, e]
  end

  def sleep_time
    sleep_intervals.map { |s, e| e - s }.sum
  end

  def sleep_minutes
    sleep_intervals.flat_map { |s, e| (s..e - 1).to_a }
  end
end

def parse_events
  regex = /\[(.*)\] (.*)/
  File.open('events.txt').map do |line|
    m = line.match(regex)
    params = m.to_a[1..-1]
    Event.new(*params)
  end
end

def parse_shifts(events)
  shifts = []
  guard_regex = /Guard #(\d*) begins shift/
  shift = nil
  asleep = nil
  awake = nil

  events.each do |event|
    t = Time.strptime(event.time, "%Y-%m-%d %H:%M")
    if event.what.start_with?("Guard")
      shifts << shift if shift
      shift = Shift.new
      shift.guard = event.what.match(guard_regex)[1]
      shift.sleep_intervals = []
    elsif event.what == "falls asleep"
      asleep = t.min
    elsif event.what == "wakes up"
      awake = t.min
      shift.sleep_intervals << [asleep, awake]
    else
      raise "Unexpected event: #{event}"
    end
  end
  shifts << shift if shift
end

def sleepiest_guard(shifts)
  sleep_times = shifts.group_by(&:guard).map do |guard, shifts|
    total_sleep = shifts.sum(&:sleep_time)
    [guard, shifts, total_sleep]
  end
  sleep_times.sort_by { |guard, shifts, total_sleep| total_sleep }.last
end

def optimal_minute(shifts)
  minutes = Array.new(60) { 0 }
  shifts.each do |shift|
    shift.sleep_minutes.each { |min| minutes[min] += 1 }
  end
  minutes.index(minutes.max)
end

def most_sleepy_minute(shifts)
  sleep_times = shifts.group_by(&:guard).map do |guard, shifts|
    minutes = Array.new(60) { 0 }
    shifts.each do |shift|
      shift.sleep_minutes.each { |min| minutes[min] += 1 }
    end
    {guard: guard, minutes: minutes}
  end
  max_guard = sleep_times.max { |h1, h2| h1[:minutes].max <=> h2[:minutes].max }
  {
    guard: max_guard[:guard],
    minute: max_guard[:minutes].index(max_guard[:minutes].max)
  }
end

events = parse_events.sort_by(&:time)
shifts = parse_shifts(events)

sleepiest_guard_shifts = sleepiest_guard(shifts)
puts "Sleepiest guard: #{sleepiest_guard_shifts[0]} (#{sleepiest_guard_shifts[2]} minutes in total)"
optimal_minute = optimal_minute(sleepiest_guard_shifts[1])
puts "Optimal minute: #{optimal_minute}"

sleepiest_minute = most_sleepy_minute(shifts)
puts "Guard #{sleepiest_minute[:guard]} was most frequently asleep on minute #{sleepiest_minute}"
