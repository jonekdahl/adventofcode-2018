
class Node

  attr_accessor :child_nodes, :metadata_entries

  def metadata_entry_sum
    metadata_entries.sum + child_nodes.map { |child| child.metadata_entry_sum }.sum
  end

  def value
    if child_nodes.empty?
      metadata_entry_sum
    else
      metadata_entries.map { |index| child_value(index) }.sum
    end
  end

  private

  def child_value(index)
    index <= child_nodes.size ? child_nodes[index - 1].value : 0
  end
end

def parse_license
  def build_node(ints)
    child_node_count = ints.next
    metadata_entry_count = ints.next
    Node.new.tap do |node|
      node.child_nodes = (1..child_node_count).map { |c| build_node(ints) }
      node.metadata_entries = (1..metadata_entry_count).map { ints.next }
    end
  end

  ints = File.open('license.txt').each_line.first.chomp.split.map { |str| Integer(str) }.to_enum
  build_node(ints)
end


license = parse_license
puts "Metadata entry sum: #{license.metadata_entry_sum}"
puts "License value: #{license.value}"
