require_relative 'lib/nvar/version'

Gem::Specification.new do |spec|
  spec.name          = "nvar"
  spec.version       = Nvar::VERSION
  spec.authors       = ["Simon Fish"]
  spec.email         = ["si@mon.fish"]

  spec.summary       = %q{Manage environment variables in Ruby}
  spec.description   = %q{Manage environment variables in Ruby}
  spec.homepage      = "https://github.com/boardfish/nvar"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency     "activesupport", [">= 5.0.0", "< 8.0"]
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "climate_control"
  spec.add_development_dependency "vcr"
end
