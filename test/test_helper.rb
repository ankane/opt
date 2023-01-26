require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"

class Minitest::Test
  def supports_type?(type)
    Opt.solvers[Opt.default_solvers[type]].supports_type?(type)
  end

  def solver
    Opt.default_solvers[:lp]
  end
end

solver = (ENV["SOLVER"] || "clp").to_sym
puts "Using #{solver}"

Opt.default_solvers = {lp: solver, qp: solver, mip: solver}
