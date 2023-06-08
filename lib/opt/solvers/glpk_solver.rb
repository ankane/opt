module Opt
  module Solvers
    class GlpkSolver < AbstractSolver
      def solve(sense:, start:, index:, value:, col_lower:, col_upper:, obj:, row_lower:, row_upper:, offset:, verbose:, time_limit:, vars:, **)
        col_kind =
          vars.map do |v|
            case v
            when Binary
              :binary
            when Integer
              :integer
            else
              :continuous
            end
          end

        mat_ia = []
        mat_ja = []
        mat_ar = []
        start.each_with_index do |s, j|
          rng = s...start[j + 1]
          index[rng].zip(value[rng]) do |i, v|
            mat_ia << i + 1
            mat_ja << j + 1
            mat_ar << v
          end
        end

        model =
          Glpk.load_problem(
            obj_dir: sense,
            obj_coef: obj,
            mat_ia: mat_ia,
            mat_ja: mat_ja,
            mat_ar: mat_ar,
            col_kind: col_kind,
            col_lower: col_lower,
            col_upper: col_upper,
            row_lower: row_lower,
            row_upper: row_upper,
          )
        res = model.solve(message_level: verbose ? 3 : 0, time_limit: time_limit)
        model.free if model.respond_to?(:free)

        status =
          case res[:status]
          when :no_feasible, :no_primal_feasible
            :infeasible
          else
            res[:status]
          end

        if status == :optimal && !res[:obj_val].finite?
          status = :unbounded
        end

        {
          status: status,
          objective: res[:obj_val] + offset,
          x: res[:col_primal]
        }
      end

      def self.available?
        defined?(Glpk)
      end

      def self.supported_types
        [:lp, :mip]
      end
    end
  end
end
