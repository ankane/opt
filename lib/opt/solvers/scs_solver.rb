module Opt
  module Solvers
    class ScsSolver < AbstractSolver
      def solve(sense:, col_lower:, col_upper:, obj:, row_lower:, row_upper:, constraints_by_var:, vars:, offset:, verbose:, time_limit:, type:, indexed_objective:, **)
        obj = obj.map { |v| -v } if sense == :maximize

        a = []
        b = []

        # add variables to constraints
        vars.each_with_index do |var, i|
          if col_lower[i] != -Float::INFINITY
            constraints_by_var << [{var => 1}, :>=, col_lower[i]]
          end
          if col_upper[i] != Float::INFINITY
            constraints_by_var << [{var => 1}, :<=, col_upper[i]]
          end
        end

        c1, c2 = constraints_by_var.partition { |_, op, _| op == :== }
        z = c1.size
        l = c2.size

        c1.each do |left, _, right|
          a << vars.map { |v| left[v] || 0 }
          b << right
        end

        c2.each do |left, op, right|
          ai = vars.map { |v| left[v] || 0 }
          bi = right

          if op == :>=
            ai.map! { |v| v * -1 }
            bi *= -1
          end

          a << ai
          b << bi
        end

        data = {a: a, b: b, c: obj}
        cone = {z: z, l: l}

        if type == :qp
          p = SCS::Matrix.new(a.first.size, a.first.size)
          vars.map.with_index do |v1, i|
            vars.map.with_index do |v2, j|
              if i > j
                0
              else
                v = indexed_objective[[v1, v2]]
                v = (v1.equal?(v2) ? v * 2 : v)
                v *= -1 if sense == :maximize
                # p must be positive semidefinite
                raise Error, "Non-convex problem" if v < 0
                p[i, j] = v
              end
            end
          end
          data[:p] = p
        end

        solver = SCS::Solver.new
        res = solver.solve(data, cone, verbose: verbose, time_limit_secs: time_limit)
        objective = res[:pobj]
        objective *= -1 if sense == :maximize
        objective += offset

        status =
          case res[:status]
          when "solved"
            :optimal
          when "infeasible", "unbounded"
            res[:status].to_sym
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
        defined?(SCS)
      end

      def self.supported_types
        [:lp, :qp]
      end
    end
  end
end
