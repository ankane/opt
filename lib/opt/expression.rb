module Opt
  class Expression
    attr_reader :parts

    def initialize(parts = [])
      @parts = parts
    end

    def +(other)
      Expression.new([self, self.class.to_expression(other)])
    end

    def -(other)
      Expression.new([self, -self.class.to_expression(other)])
    end

    def -@
      -1 * self
    end

    def *(other)
      Expression.new([Product.new(self, self.class.to_expression(other))])
    end

    # TODO allow for integer expressions
    def >(other)
      raise Error, "Strict inequality not allowed"
    end

    # TODO allow for integer expressions
    def <(other)
      raise Error, "Strict inequality not allowed"
    end

    def >=(other)
      Comparison.new(self, :>=, other)
    end

    def <=(other)
      Comparison.new(self, :<=, other)
    end

    def ==(other)
      Comparison.new(self, :==, other)
    end

    def inspect
      @parts.map(&:inspect).join(" + ").gsub(" + -", " - ")
    end

    # keep order
    def coerce(other)
      if other.is_a?(Numeric)
        [Constant.new(other), self]
      else
        raise TypeError, "#{self.class} can't be coerced into #{other.class}"
      end
    end

    def value
      values = parts.map(&:value)
      return nil if values.any?(&:nil?)

      values.sum
    end

    def vars
      @vars ||= @parts.flat_map(&:vars)
    end

    # private
    def self.to_expression(other)
      if other.is_a?(Numeric)
        Constant.new(other)
      elsif other.is_a?(Expression)
        other
      else
        raise TypeError, "can't cast #{other.class.name} to Expression"
      end
    end
  end
end
