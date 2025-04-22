require_relative "test_helper"

class QpTest < Minitest::Test
  def setup
    skip unless supports_type?(:qp)
  end

  def test_quadratic
    x = Opt::Variable.new(2.., "x")

    prob = Opt::Problem.new
    prob.minimize(x * x)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 4, res[:objective]
    assert_in_delta 2, x.value
  end

  def test_maximize
    x = Opt::Variable.new(2.., "x")

    prob = Opt::Problem.new
    prob.maximize(-(x * x))
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta(-4, res[:objective])
    assert_in_delta 2, x.value
  end

  def test_quadratic2
    x1 = Opt::Variable.new(2.., "x1")
    x2 = Opt::Variable.new(3.., "x2")

    prob = Opt::Problem.new
    prob.minimize(x1 * x1 + 2 * x1 * x2 + x2 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 25, res[:objective]
    assert_in_delta 2, x1.value
    assert_in_delta 3, x2.value
  end

  def test_quadratic3
    x1 = Opt::Variable.new(2.., "x1")
    x2 = Opt::Variable.new(3.., "x2")

    prob = Opt::Problem.new
    prob.minimize(3 * x1 * x1 + 5 * x1 * x2 + 7 * x2 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 105, res[:objective]
    assert_in_delta 2, x1.value
    assert_in_delta 3, x2.value
  end

  def test_quadratic4
    x1 = Opt::Variable.new(2.., "x1")
    x2 = Opt::Variable.new(3.., "x2")

    prob = Opt::Problem.new
    prob.minimize(3 * x1 * x1 + 5 * x1 * x2 + 7 * x2 * x2 + 4 * x1 + 6 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 131, res[:objective]
    assert_in_delta 2, x1.value
    assert_in_delta 3, x2.value
  end

  def test_quadratic5
    x1 = Opt::Variable.new(2.., "x1")
    x2 = Opt::Variable.new(3.., "x2")

    prob = Opt::Problem.new
    prob.minimize((x1 + x2) * (x1 + x2))
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 25, res[:objective]
    assert_in_delta 2, x1.value
    assert_in_delta 3, x2.value
  end

  def test_quadratic6
    x1 = Opt::Variable.new(2.., "x1")
    x2 = Opt::Variable.new(3.., "x2")

    prob = Opt::Problem.new
    prob.minimize(2 * x1 * (x1 + x2) + 2 * x2 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 38, res[:objective]
    assert_in_delta 2, x1.value
    assert_in_delta 3, x2.value
  end

  def test_quadratic7
    x1 = Opt::Variable.new(2.., "x1")
    x2 = Opt::Variable.new(3.., "x2")

    prob = Opt::Problem.new
    prob.minimize(2 * x1 * (x1 + 3 * x2) + 10 * x2 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 134, res[:objective]
    assert_in_delta 2, x1.value
    assert_in_delta 3, x2.value
  end

  def test_non_quadratic
    x1 = Opt::Variable.new(2.., "x1")

    prob = Opt::Problem.new
    error = assert_raises(Opt::Error) do
      prob.minimize(x1 * x1 * x1)
    end
    assert_equal "Non-quadratic", error.message
  end

  def test_infeasible
    x = Opt::Variable.new(0.., "x")

    prob = Opt::Problem.new
    prob.add(x + 1 == x)
    prob.minimize(x * x)
    res = prob.solve
    assert_equal :infeasible, res[:status]
    assert_nil res[:objective]
    assert_nil x.value
  end

  def test_unbounded
    # incorrect error message
    skip if solver == :osqp && OSQP::VERSION == "0.4.0"

    expected_message =
      if solver == :highs
        "Bad status"
      else
        "Non-convex problem"
      end

    x = Opt::Variable.new(0.., "x")

    prob = Opt::Problem.new
    prob.maximize(x * x)

    error = assert_raises do
      prob.solve
    end
    assert_equal expected_message, error.message
  end
end
