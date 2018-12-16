
class CircularList

  class Node

    attr_accessor :data, :prev, :next

    def initialize(data)
      @data = data
      @prev = nil
      @next = nil
    end

  end

  def initialize
    @current_node = nil
  end

  def position
    @current_node
  end

  # Inserts a new node after the current position
  def insert(data)
    node = Node.new(data)
    if @current_node.nil?
      node.prev = node
      node.next = node
      @current_node = node
    elsif @current_node == @current_node.next
      @current_node.next = node
      @current_node.prev = node
      node.next = @current_node
      node.prev = @current_node
    else
      node.prev = @current_node
      node.next = @current_node.next
      @current_node.next.prev = node
      @current_node.next = node
    end
  end

  def next!
    @current_node = @current_node&.next
  end

  def prev!
    @current_node = @current_node&.prev
  end

  # Remove the current node and return the data of it.
  def remove
    raise "Cannot remove from empty list" if @current_node.nil?

    to_remove = @current_node
    if @current_node == @current_node.next
      @current_node = nil
    else
      @current_node.prev.next = @current_node.next
      @current_node.next.prev = @current_node.prev
      @current_node = @current_node.next # move to next node after removal
    end
    to_remove.data
  end

  def each_element(&block)
    def elements_from(node, initial, &block)
      return if !initial && node == @current_node
      block.call(node.data)
      elements_from(node.next, false, &block)
    end

    elements_from(@current_node, true, &block) if @current_node
  end

end

class Game

  class Player
    def initialize
      @marbles = []
    end

    def add_marble(marble)
      @marbles << marble
    end

    def score
      @marbles.sum
    end
  end

  def initialize(player_count, last_marble)
    @players = (1..player_count).map { Player.new }
    @last_marble = last_marble
    @circle = CircularList.new
    @circle.insert(0)
  end

  def play
    (1..@last_marble).each do |marble|
      play_round(marble)
    end
    @players.map { |p| p.score }.max
  end

  private

  def play_round(marble)
    current_player = @players[(marble % @players.size) - 1]
    if marble % 23 == 0
      current_player.add_marble(marble)
      7.times { @circle.prev! }
      removed_marble = @circle.remove
      current_player.add_marble(removed_marble)
    else
      @circle.next!
      @circle.insert(marble)
      @circle.next!
    end
  end
end

player_count = 438
last_marble = 71_626

game = Game.new(player_count, last_marble)
puts "Winning score (part one): #{game.play}"

game = Game.new(player_count, last_marble * 100)
puts "Winning score (part two): #{game.play}"
