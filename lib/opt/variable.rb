module Opt
  class Variable < Expression
    attr_reader :bounds, :name
    attr_accessor :value

    def initialize(bounds, name = nil)
      @bounds = bounds
      @name = name || "x#{object_id}"
    end

    def inspect
      @name
    end

    def vars
      @vars ||= [self]
    end
  end
end
