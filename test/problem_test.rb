require_relative "test_helper"

class ProblemTest < Minitest::Test
  def test_bad_objective
    prob = Opt::Problem.new
    error = assert_raises(TypeError) do
      prob.minimize(Object.new)
    end
    assert_equal "can't cast Object to Expression", error.message
  end

  def test_objective_set
    x1 = Opt::Variable.new(0.., "x1")

    prob = Opt::Problem.new
    prob.minimize(x1)
    error = assert_raises(Opt::Error) do
      prob.minimize(x1)
    end
    assert_equal "Objective already set", error.message
  end

  def test_unsupported_semi_continuous_variable
    x1 = Opt::SemiContinuous.new(1.., "x1")
    prob = Opt::Problem.new
    prob.minimize(x1)

    error = assert_raises(Opt::Error) do
      prob.solve(solver: :cbc)
    end
    assert_equal "Solver does not support semi-continuous variables", error.message
  end

  def test_unsupported_semi_integer_variable
    x1 = Opt::SemiInteger.new(1.., "x1")
    prob = Opt::Problem.new
    prob.minimize(x1)

    error = assert_raises(Opt::Error) do
      prob.solve(solver: :cbc)
    end
    assert_equal "Solver does not support semi-integer variables", error.message
  end
end
