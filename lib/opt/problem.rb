module Opt
  class Problem
    attr_reader :sense, :objective, :constraints

    def initialize
      @constraints = []
      @indexed_constraints = []
    end

    def add(constraint)
      raise ArgumentError, "Expected Comparison" unless constraint.is_a?(Comparison)

      @constraints << constraint
      @indexed_constraints << index_constraint(constraint)
    end

    def minimize(objective)
      set_objective(:minimize, objective)
    end

    def maximize(objective)
      set_objective(:maximize, objective)
    end

    def solve(solver: nil, verbose: false, time_limit: nil)
      @indexed_objective ||= {}

      vars = self.vars
      raise Error, "No variables" if vars.empty?
      has_semi_continuous_var = vars.any? { |v| v.is_a?(SemiContinuous) }
      has_semi_integer_var = vars.any? { |v| v.is_a?(SemiInteger) }
      has_integer_var = vars.any? { |v| v.is_a?(Integer) }
      type = has_semi_continuous_var || has_semi_integer_var || has_integer_var ? :mip : :lp
      quadratic = @indexed_objective.any? { |k, _| k.is_a?(Array) }

      if quadratic
        raise Error, "Not supported" if type == :mip
        type = :qp
      end

      raise Error, "No solvers found" if Opt.available_solvers.empty?

      solver ||= (Opt.default_solvers[type] || Opt.available_solvers { |_, s| s.supports_type?(type) }.first)
      raise Error, "No solvers found for #{type}" unless solver

      # TODO better error message
      solver_cls = Opt.solvers.fetch(solver)
      raise Error, "Solver does not support #{type}" unless solver_cls.supports_type?(type)

      raise Error, "Solver does not support semi-continuous variables" if has_semi_continuous_var && !solver_cls.supports_semi_continuous_variables?
      raise Error, "Solver does not support semi-integer variables" if has_semi_integer_var && !solver_cls.supports_semi_integer_variables?

      col_lower = []
      col_upper = []
      obj = []

      @sense ||= :minimize

      vars.each do |var|
        col_lower << (var.bounds.begin || -Float::INFINITY)
        upper = var.bounds.end
        if upper && var.bounds.exclude_end?
          case var
          when Integer, SemiInteger
            upper -= 1
          else
            upper -= Float::EPSILON
          end
        end
        col_upper << (upper || Float::INFINITY)
        obj << (@indexed_objective[var] || 0)
      end

      row_lower = []
      row_upper = []
      constraints_by_var = @indexed_constraints
      constraints_by_var.each do |left, op, right|
        case op
        when :>=
          row_lower << right
          row_upper << Float::INFINITY
        when :<=
          row_lower << -Float::INFINITY
          row_upper << right
        else # :==
          row_lower << right
          row_upper << right
        end
      end

      start = []
      index = []
      value = []

      vars.each do |var|
        start << index.size
        constraints_by_var.map(&:first).each_with_index do |ic, i|
          if ic[var]
            index << i
            value << ic[var]
          end
        end
      end
      start << index.size

      if type == :qp
        @indexed_objective.select { |k, _| k.is_a?(Array) }.each do |k, v|
          @indexed_objective[k.reverse] = v
        end
      end

      res = solver_cls.new.solve(
        sense: @sense, start: start, index: index, value: value,
        col_lower: col_lower, col_upper: col_upper, obj: obj,
        row_lower: row_lower, row_upper: row_upper,
        constraints_by_var: constraints_by_var, vars: vars,
        offset: @indexed_objective[nil] || 0, verbose: verbose,
        type: type, time_limit: time_limit, indexed_objective: @indexed_objective
      )

      if res[:status] == :optimal
        vars.zip(res.delete(:x)) do |a, b|
          a.value =
            case a
            when Binary
              b.round != 0
            when Integer, SemiInteger
              b.round
            else
              b
            end
        end
      else
        res.delete(:objective)
        res.delete(:x)
      end
      res
    end

    def inspect
      str = String.new("")
      str << "#{@sense}\n  #{@objective.inspect}\n"
      str << "subject to\n"
      @constraints.each do |constraint|
        str << "  #{constraint.inspect}\n"
      end
      str << "vars\n"
      vars.each do |var|
        bounds = var.bounds
        end_op = bounds.exclude_end? ? "<" : "<="
        var_str =
          if bounds.begin && bounds.end
            "#{bounds.begin} <= #{var.name} #{end_op} #{bounds.end}"
          elsif var.bounds.begin
            "#{var.name} >= #{bounds.begin}"
          else
            "#{var.name} #{end_op} #{bounds.end}"
          end
        if var.is_a?(SemiContinuous) || var.is_a?(SemiInteger)
          var_str = "#{var_str} or #{var.name} = 0"
        end
        str << "  #{var_str}\n"
      end
      str
    end

    private

    def vars
      vars = []
      vars.concat(@objective.vars) if @objective
      @constraints.each do |constraint|
        vars.concat(constraint.left.vars)
        vars.concat(constraint.right.vars)
      end
      vars.uniq
    end

    def set_objective(sense, objective)
      raise Error, "Objective already set" if @sense

      @sense = sense
      @objective = Expression.to_expression(objective)
      @indexed_objective = index_expression(@objective)
    end

    def index_constraint(constraint)
      left = index_expression(constraint.left, check_linear: true)
      right = index_expression(constraint.right, check_linear: true)

      const = right.delete(nil).to_f - left.delete(nil).to_f
      right.each do |k, v|
        left[k] -= v
      end

      [left, constraint.op, const]
    end

    def index_expression(expression, check_linear: false)
      vars = Hash.new(0)
      case expression
      when Numeric
        vars[nil] += expression
      when Constant
        vars[nil] += expression.value
      when Variable
        vars[expression] += 1
      when Product
        if check_linear && expression.left.vars.any? && expression.right.vars.any?
          raise ArgumentError, "Nonlinear"
        end
        vars = index_product(expression.left, expression.right)
      else # Expression
        expression.parts.each do |part|
          index_expression(part, check_linear: check_linear).each do |k, v|
            vars[k] += v
          end
        end
      end
      vars
    end

    def index_product(left, right)
      # normalize
      types = [Constant, Variable, Product, Expression]
      if types.index { |t| left.is_a?(t) } > types.index { |t| right.is_a?(t) }
        left, right = right, left
      end

      vars = Hash.new(0)
      case left
      when Constant
        vars = index_expression(right)
        vars.transform_values! { |v| v * left.value }
      when Variable
        case right
        when Variable
          vars[quad_key(left, right)] = 1
        when Product
          index_expression(right).each do |k, v|
            case k
            when Array
              raise Error, "Non-quadratic"
            when Variable
              vars[quad_key(left, k)] = v
            else # nil
              raise "Bug?"
            end
          end
        else
          right.parts.each do |part|
            index_product(left, part).each do |k, v|
              vars[k] += v
            end
          end
        end
      when Product
        index_expression(left).each do |lk, lv|
          index_expression(right).each do |rk, rv|
            if lk.is_a?(Variable) && rk.is_a?(Variable)
              vars[quad_key(lk, rk)] = lv * rv
            else
              raise "todo"
            end
          end
        end
      else # Expression
        left.parts.each do |lp|
          right.parts.each do |rp|
            index_product(lp, rp).each do |k, v|
              vars[k] += v
            end
          end
        end
      end
      vars
    end

    def quad_key(left, right)
      if left.object_id <= right.object_id
        [left, right]
      else
        [right, left]
      end
    end
  end
end
