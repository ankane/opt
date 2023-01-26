module Opt
  module Solvers
    class AbstractSolver
      def self.supports_type?(type)
        supported_types.include?(type)
      end
    end
  end
end
