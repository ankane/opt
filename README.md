# Opt

:fire: Convex optimization for Ruby

Supports Cbc, Clp, GLOP, GLPK, HiGHS, OSQP, and SCS

[![Build Status](https://github.com/ankane/opt/workflows/build/badge.svg?branch=master)](https://github.com/ankane/opt/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "opt-rb"
```

And install one or more solvers based on your problem types:

Solver | LP | QP | MIP | License
--- | --- | --- | --- | ---
[Cbc](https://github.com/ankane/cbc-ruby) | ✓ | | ✓ | EPL-2.0
[Clp](https://github.com/ankane/clp-ruby) | ✓ | | | EPL-2.0
[GLOP](https://github.com/ankane/or-tools-ruby) | ✓ | | | Apache-2.0
[GLPK](https://github.com/ankane/glpk-ruby) | ✓ | | ✓ | GPL-3.0-or-later
[HiGHS](https://github.com/ankane/highs-ruby) | ✓ | ✓ | ✓ | MIT
[OSQP](https://github.com/ankane/osqp-ruby) | ✓ | ✓ | | Apache-2.0
[SCS](https://github.com/ankane/scs-ruby) | ✓ | * | | MIT

\* supports, but not implemented yet

## Getting Started

Create and solve a problem

```ruby
x1 = Opt::Variable.new(0.., "x1")
x2 = Opt::Variable.new(0.., "x2")

prob = Opt::Problem.new
prob.add(2 * x1 + 2 * x2 >= 7)
prob.add(3 * x1 + 4 * x2 >= 12)
prob.add(2 * x1 + x2 >= 6)
prob.minimize(8 * x1 + 10 * x2)
prob.solve
```

Get the value of a variable

```ruby
x1.value
```

QP

```ruby
prob.minimize(x1 * x1)
```

MIP

```ruby
x1 = Opt::Integer.new(0.., "x1")
x2 = Opt::Binary.new("x2")
```

## Reference

Specify the solver

```ruby
prob.solve(solver: :cbc)
```

Enable verbose logging

```ruby
prob.solve(verbose: true)
```

Set the time limit in seconds

```ruby
prob.solve(time_limit: 30)
```

## Credits

This project was inspired by [CVXPY](https://github.com/cvxpy/cvxpy) and [OR-Tools](https://github.com/google/or-tools).

## History

View the [changelog](CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/opt/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/opt/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/opt.git
cd opt
bundle install
bundle exec rake test
```
