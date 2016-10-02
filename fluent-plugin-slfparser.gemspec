# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-slfparser"
  gem.version       = "0.0.5"
  gem.authors       = ["Fabian Kajzar"]
  gem.email         = ["fabiankajzar@gmail.com"]
  gem.description   = %q{parsing of SLF4J based logs. }
  gem.summary       = %q{Fluentd plugin to parse SLF4J based logs.}
  gem.homepage      = "https://github.com/Fabian-K/fluent-plugin-slfparser"
  gem.license       = "Apache-2.0"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake"
  gem.add_development_dependency "test-unit", "~> 3.0.2"
  gem.add_runtime_dependency "fluentd"
end