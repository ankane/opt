require_relative "test_helper"

class MipTest < Minitest::Test
  def setup
    skip unless supports_type?(:mip)
  end

  def test_mip
    x1 = Opt::Integer.new(0.., "x1")
    x2 = Opt::Variable.new(0.., "x2")

    prob = Opt::Problem.new
    prob.add(2 * x1 + 2 * x2 >= 7)
    prob.add(3 * x1 + 4 * x2 >= 12)
    prob.add(2 * x1 + x2 >= 6)
    prob.minimize(8 * x1 + 10 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 31.5, res[:objective]
    assert_equal 3, x1.value
    assert_kind_of Integer, x1.value
    assert_in_delta 0.75, x2.value
    assert_kind_of Float, x2.value
  end

  def test_ip
    x1 = Opt::Integer.new(0.., "x1")
    x2 = Opt::Integer.new(0.., "x2")

    prob = Opt::Problem.new
    prob.add(2 * x1 + 2 * x2 >= 7)
    prob.add(3 * x1 + 4 * x2 >= 12)
    prob.add(2 * x1 + x2 >= 6)
    prob.minimize(8 * x1 + 10 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 32, res[:objective]
    assert_equal 4, x1.value
    assert_equal 0, x2.value
  end

  def test_binary
    x1 = Opt::Binary.new("x1")
    x2 = Opt::Binary.new("x2")

    prob = Opt::Problem.new
    prob.add(x1 - 2 * x2 >= 0)
    prob.maximize(2 * x1 + 3 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 2, res[:objective]
    assert_equal true, x1.value
    assert_equal false, x2.value
  end

  def test_infeasible
    x = Opt::Integer.new(0.., "x")

    prob = Opt::Problem.new
    prob.add(x + 1 == x)
    res = prob.solve
    assert_equal :infeasible, res[:status]
    assert_nil res[:objective]
    assert_nil x.value
  end

  def test_unbounded_minimize
    expected_status =
      if solver == :highs
        :unbounded_or_infeasible
      else
        :unbounded
      end

    x = Opt::Integer.new(..0, "x")

    prob = Opt::Problem.new
    prob.minimize(x)
    res = prob.solve
    assert_equal expected_status, res[:status]
    assert_nil res[:objective]
    assert_nil x.value
  end

  def test_unbounded_maximize
    expected_status =
      if solver == :highs
        :unbounded_or_infeasible
      else
        :unbounded
      end

    x = Opt::Integer.new(0.., "x")

    prob = Opt::Problem.new
    prob.maximize(x)
    res = prob.solve
    assert_equal expected_status, res[:status]
    assert_nil res[:objective]
    assert_nil x.value
  end

  def test_negative_variable
    x = Opt::Integer.new(..0, "x")

    prob = Opt::Problem.new
    prob.add(x >= -2)
    prob.minimize(2 * x)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_equal (-4), res[:objective]
    assert_equal (-2), x.value
  end

  def test_semi_contious_mip
    skip unless Opt.solvers[Opt.default_solvers[:mip]].supports_semi_continuous_variables?

    x1 = Opt::SemiContinuous.new(1.., "x1")
    x2 = Opt::SemiContinuous.new(2.., "x2")

    prob = Opt::Problem.new
    prob.add(3 * x1 + 2 * x2 >= 60)
    prob.minimize(8 * x1 + 6 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 160, res[:objective]
    assert_equal 20, x1.value
    assert_kind_of Float, x1.value
    assert_in_delta 0, x2.value
    assert_kind_of Float, x2.value
  end

  def test_semi_integer_mip
    skip unless Opt.solvers[Opt.default_solvers[:mip]].supports_semi_continuous_variables?

    x1 = Opt::SemiInteger.new(1.., "x1")
    x2 = Opt::SemiInteger.new(2.., "x2")

    prob = Opt::Problem.new
    prob.add(3 * x1 + 2 * x2 >= 75)
    prob.minimize(8 * x1 + 6 * x2)
    res = prob.solve
    assert_equal :optimal, res[:status]
    assert_in_delta 200, res[:objective]
    assert_equal 25, x1.value
    assert_kind_of Integer, x1.value
    assert_in_delta 0, x2.value
    assert_kind_of Integer, x2.value
  end

  def test_quadratic
    x1 = Opt::Integer.new(0.., "x1")

    prob = Opt::Problem.new
    prob.minimize(x1 * x1)
    error = assert_raises(Opt::Error) do
      prob.solve
    end
    assert_equal "Not supported", error.message
  end

  def test_sudoku
    grid = [
      [5, 3, 0, 0, 7, 0, 0, 0, 0],
      [6, 0, 0, 1, 9, 5, 0, 0, 0],
      [0, 9, 8, 0, 0, 0, 0, 6, 0],
      [8, 0, 0, 0, 6, 0, 0, 0, 3],
      [4, 0, 0, 8, 0, 3, 0, 0, 1],
      [7, 0, 0, 0, 2, 0, 0, 0, 6],
      [0, 6, 0, 0, 0, 0, 2, 8, 0],
      [0, 0, 0, 4, 1, 9, 0, 0, 5],
      [0, 0, 0, 0, 8, 0, 0, 7, 9]
    ]

    vars =
      9.times.map do |i|
        9.times.map do |j|
          9.times.map do |k|
            Opt::Binary.new("x[#{i},#{j},#{k}]")
          end
        end
      end

    prob = Opt::Problem.new

    # cells
    9.times do |i|
      9.times do |j|
        prob.add(vars[i][j].sum == 1)
      end
    end

    # puzzle values
    9.times do |i|
      9.times do |j|
        k = grid[i][j]
        prob.add(vars[i][j][k - 1] == 1) if k != 0
      end
    end

    # columns
    9.times do |i|
      add_different(prob, vars.map { |v| v[i] })
    end

    # rows
    9.times do |i|
      add_different(prob, vars[i])
    end

    # subgrids
    3.times do |i|
      3.times do |j|
        add_different(prob, 3.times.flat_map { |k| 3.times.map { |l| vars[3 * i + k][3 * j + l] }})
      end
    end

    prob.solve

    expected = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9]
    ]
    result = vars.map { |v| v.map { |v2| v2.index(&:value) + 1 } }
    assert_equal expected, result
  end

  private

  def add_different(prob, vars)
    9.times do |i|
      prob.add(vars.sum { |v| v[i] } == 1)
    end
  end
end
