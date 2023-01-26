require_relative "test_helper"

class OptTest < Minitest::Test
  def test_available_solvers
    assert_includes Opt.available_solvers, Opt.default_solvers[:lp]
  end
end
