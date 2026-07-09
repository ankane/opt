source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest"

# solvers
gem "cbc"
gem "clp"
gem "glpk"
gem "highs", "< 0.3"
gem "osqp"
gem "scs"

# only require when needed to prevent segfault with osqp
gem "or-tools", platform: :mri, require: false
