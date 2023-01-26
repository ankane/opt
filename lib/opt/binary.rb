module Opt
  class Binary < Integer
    def initialize(name = nil)
      super(0..1, name)
    end
  end
end
