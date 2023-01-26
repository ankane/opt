module Opt
  module Solvers
    class CbcSolver < AbstractSolver
      def solve(sense:, start:, index:, value:, col_lower:, col_upper:, obj:, row_lower:, row_upper:, offset:, verbose:, time_limit:, vars:, **)
        model =
          Cbc.load_problem(
            sense: sense,
            start: start,
            index: index,
            value: value,
            col_lower: col_lower,
            col_upper: col_upper,
            obj: obj,
            row_lower: row_lower,
            row_upper: row_upper,
            col_type: vars.map { |v| v.is_a?(Integer) ? :integer : :continuous }
          )

        # only pass options if set to support Cbc < 2.10.0
        options = {}
        options[:log_level] = 1 if verbose
        options[:time_limit] = time_limit if time_limit
        res = model.solve(**options)

        status =
          case res[:status]
          when :primal_infeasible
            :infeasible
          else
            res[:status]
          end

        {
          status: status,
          objective: res[:objective] + offset,
          x: res[:primal_col]
        }
      end

      def self.available?
        defined?(Cbc)
      end

      def self.supported_types
        [:lp, :mip]
      end
    end
  end
end
