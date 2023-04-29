# modules
require_relative "opt/expression"
require_relative "opt/comparison"
require_relative "opt/constant"
require_relative "opt/variable"
require_relative "opt/integer"
require_relative "opt/binary"
require_relative "opt/semi_continuous"
require_relative "opt/semi_integer"
require_relative "opt/problem"
require_relative "opt/product"
require_relative "opt/version"

# solvers
require_relative "opt/solvers/abstract_solver"
require_relative "opt/solvers/cbc_solver"
require_relative "opt/solvers/clp_solver"
require_relative "opt/solvers/glop_solver"
require_relative "opt/solvers/glpk_solver"
require_relative "opt/solvers/highs_solver"
require_relative "opt/solvers/osqp_solver"
require_relative "opt/solvers/scs_solver"

module Opt
  class Error < StandardError; end

  class << self
    attr_accessor :solvers, :default_solvers
  end
  self.solvers = {}
  self.default_solvers = {}

  def self.register_solver(key, cls)
    solvers[key] = cls
  end

  def self.available_solvers(&filter)
    available_solvers = solvers.select { |_, v| v.available? }
    available_solvers = available_solvers.select(&filter) unless filter.nil?
    available_solvers.map(&:first)
  end
end

Opt.register_solver :cbc, Opt::Solvers::CbcSolver
Opt.register_solver :clp, Opt::Solvers::ClpSolver
Opt.register_solver :glop, Opt::Solvers::GlopSolver
Opt.register_solver :glpk, Opt::Solvers::GlpkSolver
Opt.register_solver :highs, Opt::Solvers::HighsSolver
Opt.register_solver :osqp, Opt::Solvers::OsqpSolver
Opt.register_solver :scs, Opt::Solvers::ScsSolver
