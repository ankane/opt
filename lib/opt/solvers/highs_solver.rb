module Opt
  module Solvers
    class HighsSolver < AbstractSolver
      def solve(sense:, start:, index:, value:, col_lower:, col_upper:, obj:, row_lower:, row_upper:, vars:, offset:, verbose:, type:, time_limit:, indexed_objective:, **)
        start.pop

        model =
          case type
          when :mip
            Highs.mip(
              sense: sense,
              col_cost: obj,
              col_lower: col_lower,
              col_upper: col_upper,
              row_lower: row_lower,
              row_upper: row_upper,
              a_format: :colwise,
              a_start: start,
              a_index: index,
              a_value: value,
              offset: offset,
              integrality: vars.map { |v| v.is_a?(Integer) ? 1 : 0 }
            )
          when :qp
            q_start = []
            q_index = []
            q_value = []

            vars.each_with_index do |v2, j|
              q_start << q_index.size
              vars.each_with_index do |v1, i|
                v = indexed_objective[[v1, v2]]
                if v != 0
                  q_index << i
                  # multiply values by 2 since minimizes 1/2
                  q_value << (v1.equal?(v2) ? v * 2 : v)
                end
              end
            end

            Highs.qp(
              sense: sense,
              col_cost: obj,
              col_lower: col_lower,
              col_upper: col_upper,
              row_lower: row_lower,
              row_upper: row_upper,
              a_format: :colwise,
              a_start: start,
              a_index: index,
              a_value: value,
              offset: offset,
              q_format: :colwise,
              q_start: q_start,
              q_index: q_index,
              q_value: q_value
            )
          else
            Highs.lp(
              sense: sense,
              col_cost: obj,
              col_lower: col_lower,
              col_upper: col_upper,
              row_lower: row_lower,
              row_upper: row_upper,
              a_format: :colwise,
              a_start: start,
              a_index: index,
              a_value: value,
              offset: offset
            )
          end

        res = model.solve(verbose: verbose, time_limit: time_limit)

        {
          status: res[:status],
          objective: res[:obj_value],
          x: res[:col_value]
        }
      end

      def self.available?
        defined?(Highs)
      end

      def self.supported_types
        [:lp, :qp, :mip]
      end
    end
  end
end
