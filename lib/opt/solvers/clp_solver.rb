module Opt
  module Solvers
    class ClpSolver < AbstractSolver
      def solve(sense:, start:, index:, value:, col_lower:, col_upper:, obj:, row_lower:, row_upper:, offset:, verbose:, time_limit:, **)
        model =
          Clp.load_problem(
            sense: sense,
            start: start,
            index: index,
            value: value,
            col_lower: col_lower,
            col_upper: col_upper,
            obj: obj,
            row_lower: row_lower,
            row_upper: row_upper,
            offset: -offset
          )
        res = model.solve(log_level: verbose ? 4 : nil, time_limit: time_limit)

        status =
          case res[:status]
          when :primal_infeasible
            :infeasible
          when :dual_infeasible
            :unbounded
          else
            res[:status]
          end

        {
          status: status,
          objective: res[:objective],
          x: res[:primal_col]
        }
      end

      def self.available?
        defined?(Clp)
      end

      def self.supported_types
        [:lp]
      end
    end
  end
end
