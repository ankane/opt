require_relative "test_helper"

class ExpressionTest < Minitest::Test
  def setup
    @x1 = Opt::Variable.new(0.., "x1")
    @x2 = Opt::Variable.new(0.., "x2")
  end

  def test_add
    assert_equal "x1 + x2", (@x1 + @x2).inspect
    assert_equal "x1 + 1", (@x1 + 1).inspect
    assert_equal "x1 - 1", (@x1 - 1).inspect
    assert_equal "x1 + x1", (@x1 + @x1).inspect
    assert_equal "x1 + 1 + x2 + 2", (@x1 + 1 + @x2 + 2).inspect
    assert_equal "-1 * x1", (-@x1).inspect
  end

  def test_sum
    assert_equal "x1 + x2", [@x1, @x2].sum.inspect
    assert_equal "x1 + x2 + 3", [@x1, @x2, 3].sum.inspect
    assert_equal "x1 + 1 + x2 + 2", [@x1, 1, @x2, 2].sum.inspect
    assert_equal "2 * x1 + 2 * x2", [@x1, @x2].sum { |v| 2 * v }.inspect
  end

  def test_multiply
    assert_equal "3 * x1", (3 * @x1).inspect
    assert_equal "x1 * 3", (@x1 * 3).inspect
    assert_equal "3 * (x1 + 1)", (3 * (@x1 + 1)).inspect
    assert_equal "(x1 + 1) * 3", ((@x1 + 1) * 3).inspect
    assert_equal "((x1 + 1) * 3) * 4", (((@x1 + 1) * 3) * 4).inspect
    assert_equal "4 * ((x1 + 1) * 3)", (4 * ((@x1 + 1) * 3)).inspect
  end

  # does not raise error until added to problem
  # to allow for quadratic objective
  def test_nonlinear_expression
    assert_equal "x1 * x1", (@x1 * @x1).inspect
  end

  def test_nonlinear_constraint
    prob = Opt::Problem.new
    assert_nonlinear { prob.add(@x1 * @x1 >= 0) }
    assert_nonlinear { prob.add(@x1 * (@x1 + 1) >= 0) }
    assert_nonlinear { prob.add((@x1 + 1) * @x1 >= 0) }
    assert_nonlinear { prob.add((@x1 + 1) * (@x1 + 1) >= 0) }
  end

  def assert_nonlinear
    error = assert_raises(ArgumentError) do
      yield
    end
    assert_equal "Nonlinear", error.message
  end

  def test_value
    expression = 2 * @x1 + 3 * @x2 * @x2
    @x1.value = 1
    @x2.value = 2
    assert_equal 14, expression.value
  end

  def test_nil_value
    expression = 2 * @x1 + 3 * @x2 * @x2
    assert_nil expression.value

    @x1.value = 1
    assert_nil expression.value

    @x2.value = 1
    assert_equal 5, expression.value
  end
end
