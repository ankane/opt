require_relative "test_helper"

class OptTest < Minitest::Test
  def test_available_solvers
    assert_includes Opt.available_solvers, Opt.default_solvers[:lp]
  end

  def test_available_solvers_with_filtering
    assert_includes Opt.available_solvers { |_, solver| solver.supports_type?(:qp) }, :highs
  end
end
