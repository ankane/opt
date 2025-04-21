require "bundler/gem_tasks"
require "rake/testtask"

SOLVERS = %w(cbc clp glop glpk highs osqp scs)

SOLVERS.each do |solver|
  namespace :test do
    task("env:#{solver}") { ENV["SOLVER"] = solver }

    Rake::TestTask.new(solver => "env:#{solver}") do |t|
      t.description = "Run tests for #{solver}"
      t.pattern = "test/**/*_test.rb"
    end
  end
end

desc "Run all solver tests"
task :test do
  SOLVERS.each do |solver|
    next if ["jruby", "truffleruby"].include?(RUBY_ENGINE) && solver == "glop"
    Rake::Task["test:#{solver}"].invoke
  end
end

task default: :test
