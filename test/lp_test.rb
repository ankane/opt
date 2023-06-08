require_relative "test_helper"

class LpTest < Minitest::Test
  def setup
    skip unless supports_type?(:lp)
  end

  def test_minimize
    x1 = Opt::Variable.new(0.., "x1")
    x2 = Opt::Variable.new(0.., "x2")

    assert_nil x1.value
    assert_nil x2.value

    prob = Opt::Problem.new
    prob.add(2 * x1 + 2 * x2 >= 7)
    prob.add(3 * x1 + 4 * x2 >= 12)
    prob.add(2 * x1 + x2 >= 6)
    prob.minimize(8 * x1 + 10 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 31.2, res[:objective]
    assert_in_delta 2.4, x1.value
    assert_in_delta 1.2, x2.value
  end

  def test_minimize2
    x1 = Opt::Variable.new(0.., "x1")
    x2 = Opt::Variable.new(0.., "x2")

    prob = Opt::Problem.new
    prob.add(2 * x1 >= 7 - 2 * x2)
    prob.add(12 <= 3 * x1 + 4 * x2)
    prob.add(x2 - 6 + 2 * x1 >= 0)
    prob.minimize(7 * x1 + 10 * x2 + x1)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 31.2, res[:objective]
    assert_in_delta 2.4, x1.value
    assert_in_delta 1.2, x2.value
  end

  def test_maximize
    x1 = Opt::Variable.new(..1, "x1")
    x2 = Opt::Variable.new(0.., "x2")

    prob = Opt::Problem.new
    prob.add(1 * x1 + 1 * x2 <= 3)
    prob.maximize(10 * x1 + 1 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 12, res[:objective]
    assert_in_delta 1, x1.value
    assert_in_delta 2, x2.value
  end

  def test_equality
    x1 = Opt::Variable.new(0.., "x1")

    prob = Opt::Problem.new
    prob.add(x1 == 1)
    prob.maximize(x1)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 1, res[:objective]
    assert_in_delta 1, x1.value
  end

  def test_multiple_optimal
    x1 = Opt::Variable.new(0.., "x1")
    x2 = Opt::Variable.new(0.., "x2")

    prob = Opt::Problem.new
    prob.add(x1 + 2 * x2 <= 30)
    prob.maximize(x1 + 2 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 30, res[:objective]
    assert_in_delta 30, x1.value + 2 * x2.value
  end

  def test_infeasible
    x = Opt::Variable.new(0.., "x")

    prob = Opt::Problem.new
    prob.add(x + 1 == x)
    res = prob.solve
    assert_equal :infeasible, res[:status]
    assert_nil res[:objective]
    assert_nil x.value
  end

  def test_unbounded_minimize
    expected_status =
      case solver
      when :cbc
        # no Cbc_isInitialSolveProvenDualInfeasible function
        :unset
      when :glop
        # https://github.com/google/or-tools/issues/3319
        :infeasible
      else
        :unbounded
      end

    x = Opt::Variable.new(..0, "x")

    prob = Opt::Problem.new
    prob.minimize(x)
    res = prob.solve
    assert_equal expected_status, res[:status]
    assert_nil res[:objective]
    assert_nil x.value
  end

  def test_unbounded_maximize
    expected_status =
      case solver
      when :cbc
        # no Cbc_isInitialSolveProvenDualInfeasible function
        :unset
      when :glop
        # https://github.com/google/or-tools/issues/3319
        :infeasible
      else
        :unbounded
      end

    x = Opt::Variable.new(0.., "x")

    prob = Opt::Problem.new
    prob.maximize(x)
    res = prob.solve
    assert_equal expected_status, res[:status]
    assert_nil res[:objective]
    assert_nil x.value
  end

  def test_offset_minimize
    x = Opt::Variable.new(0.., "x")

    prob = Opt::Problem.new
    prob.minimize(x + 2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 2, res[:objective]
    assert_in_delta 0, x.value
  end

  def test_offset_maximize
    x = Opt::Variable.new(..0, "x")

    prob = Opt::Problem.new
    prob.maximize(x + 2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 2, res[:objective]
    assert_in_delta 0, x.value
  end

  def test_no_objective
    x1 = Opt::Variable.new(0.., "x1")
    x2 = Opt::Variable.new(0.., "x2")

    prob = Opt::Problem.new
    prob.add(2 * x1 + 2 * x2 >= 7)
    prob.add(3 * x1 + 4 * x2 >= 12)
    prob.add(2 * x1 + x2 >= 6)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 0, res[:objective]
    assert_operator x1.value, :>=, 0
    assert_operator x2.value, :>=, 0
  end

  def test_constant_objective
    x1 = Opt::Variable.new(0.., "x1")
    x2 = Opt::Variable.new(0.., "x2")

    prob = Opt::Problem.new
    prob.add(2 * x1 + 2 * x2 >= 7)
    prob.add(3 * x1 + 4 * x2 >= 12)
    prob.add(2 * x1 + x2 >= 6)
    prob.minimize(2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 2, res[:objective]
    assert_operator x1.value, :>=, 0
    assert_operator x2.value, :>=, 0
  end

  def test_negative_variable
    x = Opt::Variable.new(..0, "x")

    prob = Opt::Problem.new
    prob.add(x >= -2)
    prob.minimize(2 * x)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta (-4), res[:objective]
    assert_in_delta (-2), x.value
  end

  def test_no_variables
    prob = Opt::Problem.new
    error = assert_raises(Opt::Error) do
      prob.solve
    end
    assert_equal "No variables", error.message
  end

  def test_expression_value
    x1 = Opt::Variable.new(0.., "x1")
    x2 = Opt::Variable.new(0.., "x2")
    expr1 = 2 * x1 + 2 * x2
    expr2 = 3 * x1 + 4 * x2
    expr3 = 2 * x1 + x2
    obj = 8 * x1 + 10 * x2

    prob = Opt::Problem.new
    prob.add(expr1 >= 7)
    prob.add(expr2 >= 12)
    prob.add(expr3 >= 6)
    prob.minimize(obj)

    assert_nil x1.value
    assert_nil x2.value
    assert_nil expr1.value
    assert_nil expr2.value
    assert_nil expr3.value
    assert_nil obj.value

    res = prob.solve
    assert_equal :optimal, res[:status]

    assert_in_delta 2.4, x1.value
    assert_in_delta 1.2, x2.value
    assert_in_delta 7.2, expr1.value
    assert_in_delta 12, expr2.value
    assert_in_delta 6, expr3.value
    assert_in_delta 31.2, obj.value
  end

  def test_threads
    threads =
      2.times.map do
        Thread.new do
          x1 = Opt::Variable.new(0.., "x1")
          prob = Opt::Problem.new
          prob.add(x1 >= 2)
          prob.minimize(x1)
          prob.solve
        end
      end
    threads.map(&:join)
  end
end
