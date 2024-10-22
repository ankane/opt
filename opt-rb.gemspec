require_relative "lib/opt/version"

Gem::Specification.new do |spec|
  spec.name          = "opt-rb"
  spec.version       = Opt::VERSION
  spec.summary       = "Convex optimization for Ruby"
  spec.homepage      = "https://github.com/ankane/opt"
  spec.license       = "Apache-2.0"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 3.1"
end
