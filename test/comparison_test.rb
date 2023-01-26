require_relative "test_helper"

class ComparisonTest < Minitest::Test
  def setup
    @x1 = Opt::Variable.new(0.., "x1")
    @x2 = Opt::Variable.new(0.., "x2")
  end

  def test_greater_than_or_equal_to
    assert_equal "x1 >= 1 + x2", (@x1 >= 1 + @x2).inspect
  end

  def test_less_than_or_equal_to
    assert_equal "x1 <= 1", (@x1 <= 1).inspect
  end

  def test_greater_than
    error = assert_raises(Opt::Error) do
      @x1 > 1
    end
    assert_equal "Strict inequality not allowed", error.message
  end

  def test_less_than
    error = assert_raises(Opt::Error) do
      @x1 < 1
    end
    assert_equal "Strict inequality not allowed", error.message
  end

  def test_equal_to
    assert_equal "x1 == 1", (@x1 == 1).inspect
  end

  def test_bad
    error = assert_raises(TypeError) do
      @x1 == Object.new
    end
    assert_equal "can't cast Object to Expression", error.message
  end

  def test_equal_to_solve
    prob = Opt::Problem.new
    prob.add(1 * @x1 + 0 * @x2 == 1)
    prob.add(1 * @x1 + 1 * @x2 == 3)
    prob.minimize(1 * @x1 + 1 * @x2)
    res = prob.solve
    assert_in_delta 3, res[:objective]
    assert_in_delta 1, @x1.value
    assert_in_delta 2, @x2.value
  end
end
