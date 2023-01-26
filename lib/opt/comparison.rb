module Opt
  class Comparison
    attr_reader :left, :op, :right

    def initialize(left, op, right)
      @left = Expression.to_expression(left)
      @op = op
      @right = Expression.to_expression(right)
    end

    def inspect
      "#{@left.inspect} #{@op} #{@right.inspect}"
    end
  end
end
