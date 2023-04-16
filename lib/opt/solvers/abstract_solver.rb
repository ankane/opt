module Opt
  module Solvers
    class AbstractSolver
      def self.supports_type?(type)
        supported_types.include?(type)
      end

      def self.supports_semi_continuous_variables?
        false
      end

      def self.supports_semi_integer_variables?
        false
      end
    end
  end
end
