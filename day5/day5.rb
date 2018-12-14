require 'set'

class List

  class Node

    attr_accessor :data, :prev, :next

    def initialize(data)
      @data = data
      @prev = nil
      @next = nil
    end

  end

  attr_reader :head, :tail

  def initialize
    @head = nil
    @tail = nil
  end

  def append(data)
    node = Node.new(data)
    if @tail
      node.prev = @tail
      @tail.next = node
      @tail = node
    else
      @head = node
      @tail = node
    end
  end

  def remove(node)
    raise "Cannot remove from empty list" if @head.nil?

    if @head == node && @tail == node
      @head = nil
      @tail = nil
    else
      if node == @head
        @head = node.next
        @head.prev = nil
      elsif node == @tail
        @tail = node.prev
        @tail.next = nil
      else
        node.prev.next = node.next
        node.next.prev = node.prev
      end
    end
  end

  def each_element(&block)
    def elements_from(node, &block)
      return unless node
      block.call(node.data)
      elements_from(node.next, &block)
    end

    elements_from(@head, &block)
  end

end

def reacts?(c1, c2)
  @reacting_elements ||= ('a'..'z').zip("A".."Z").flat_map { |c1, c2| [c1 + c2, c2 + c1] }.to_set
  @reacting_elements.include?(c1 + c2)
end

def trigger_reaction(polymer)
  list = List.new
  polymer.each_char { |c| list.append(c) }
  position = list.head
  while !position.nil? && position != list.tail
    c1 = position.data
    c2 = position.next.data
    if reacts?(c1, c2)
      next_position = position == list.head ? position.next.next : position.prev
      list.remove(position)
      list.remove(position.next)
      position = next_position
    else
      position = position.next
    end
  end

  +"".tap { |reacted| list.each_element { |e| reacted << e } }
end

polymers = [
  ['aA', ''],
  ['abBA', ''],
  ['abAB', 'abAB'],
  ['aabAAB', 'aabAAB'],
  ['dabAcCaCBAcCcaDA', 'dabCBAcaDA']
]

polymers.each do |polymer, expected|
  reacted = trigger_reaction(polymer)
  puts "Reacting #{polymer}... #{reacted == expected ? 'CORRECT' : 'WRONG'}"
end

polymer = File.open('polymer.txt').each_line.first.chomp
reacted = trigger_reaction(polymer)
puts "Units remaining after reaction: #{reacted.size}"

def reduce_polymer(polymer, *units)
  +"".tap { |reduced| polymer.each_char { |c| reduced << c unless units.include?(c) } }
end

def optimal_polymer(polymer)
  reacted_polymers = ('a'..'z').zip("A".."Z").map do |units|
    reduced_polymer = reduce_polymer(polymer, *units)
    trigger_reaction(reduced_polymer)
  end
  reacted_polymers.min { |a, b| a.size <=> b.size }
end

puts "The shortest possible polymer has #{optimal_polymer(polymer).size} units"
