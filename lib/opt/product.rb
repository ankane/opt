module Opt
  class Product < Expression
    attr_reader :left, :right

    def initialize(left, right)
      @left = left
      @right = right
    end

    def inspect
      "#{inspect_part(@left)} * #{inspect_part(@right)}"
    end

    def value
      return nil if left.value.nil? || right.value.nil?

      left.value * right.value
    end

    def vars
      @vars ||= (@left.vars + @right.vars).uniq
    end

    private

    def inspect_part(var)
      if var.instance_of?(Expression)
        "(#{var.inspect})"
      else
        var.inspect
      end
    end
  end
end
