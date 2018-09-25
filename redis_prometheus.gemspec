# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_prometheus/version'

Gem::Specification.new do |spec|
  spec.name          = "redis_prometheus"
  spec.version       = RedisPrometheus::VERSION
  spec.authors       = ["Andy Jeffries"]
  spec.email         = ["andy@andyjeffries.co.uk"]

  spec.summary       = %q{Capture and serve rack statistics for Prometheus in Redis}
  spec.description   = %q{In order to ensure all your statistics are served to Prometheus across multiple machines/pods/instances/containers, store the details in Redis}
  spec.homepage      = "https://github.com/civo/redis_prometheus"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
