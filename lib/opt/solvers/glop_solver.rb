module Opt
  module Solvers
    class GlopSolver < AbstractSolver
      def solve(sense:, col_lower:, col_upper:, obj:, offset:, verbose:, time_limit:, constraints_by_var:, vars:, **)
        solver = ORTools::Solver.new("GLOP")

        # create vars
        vars2 =
          vars.map.with_index do |v, i|
            solver.num_var(col_lower[i], col_upper[i], v.name)
          end

        var_index = vars.map.with_index.to_h

        # add constraints
        constraints_by_var.each do |left, op, right|
          expr = left.sum { |k, v| vars2[var_index[k]] * v }
          case op
          when :<=
            solver.add(expr <= right)
          when :>=
            solver.add(expr >= right)
          else
            solver.add(expr == right)
          end
        end

        # add objective
        objective = vars2.zip(obj).sum { |v, o| v * o }

        if sense == :maximize
          solver.maximize(objective)
        else
          solver.minimize(objective)
        end

        solver.time_limit = time_limit if time_limit
        status = solver.solve

        {
          status: status,
          objective: solver.objective.value + offset,
          x: vars2.map(&:solution_value)
        }
      end

      def self.available?
        defined?(ORTools)
      end

      def self.supported_types
        [:lp]
      end
    end
  end
end
