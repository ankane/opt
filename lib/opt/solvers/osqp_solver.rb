module Opt
  module Solvers
    class OsqpSolver < AbstractSolver
      def solve(sense:, col_lower:, col_upper:, obj:, row_lower:, row_upper:, constraints_by_var:, vars:, offset:, verbose:, time_limit:, type:, indexed_objective:, **)
        obj = obj.map { |v| -v } if sense == :maximize

        a =
          constraints_by_var.map(&:first).map do |ic|
            vars.map do |var|
              ic[var] || 0
            end
          end

        # add variable constraints
        vars.each_with_index do |v, i|
          row = [0] * vars.size
          row[i] = 1
          a << row
          row_lower << col_lower[i]
          row_upper << col_upper[i]
        end

        p = OSQP::Matrix.new(a.first.size, a.first.size)
        if type == :qp
          vars.map.with_index do |v1, i|
            vars.map.with_index do |v2, j|
              if i > j
                0
              else
                v = indexed_objective[[v1, v2]]
                v = (v1.equal?(v2) ? v * 2 : v)
                v *= -1 if sense == :maximize
                p[i, j] = v
              end
            end
          end
        end

        solver = OSQP::Solver.new
        solve_opts = {}
        solve_opts[:time_limit] = time_limit if time_limit
        solve_opts[OSQP::VERSION.to_f >= 0.4 ? :polishing : :polish] = true
        res = solver.solve(p, obj, a, row_lower, row_upper, verbose: verbose, **solve_opts)
        objective = res[:obj_val]
        objective *= -1 if sense == :maximize
        objective += offset

        status =
          case res[:status]
          when "solved"
            :optimal
          when "primal infeasible"
            :infeasible
          when "dual infeasible"
            :unbounded
          else
            res[:status]
          end

        {
          status: status,
          objective: objective,
          x: res[:x]
        }
      end

      def self.available?
        defined?(OSQP)
      end

      def self.supported_types
        [:lp, :qp]
      end
    end
  end
end
