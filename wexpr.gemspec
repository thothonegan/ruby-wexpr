
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "wexpr/version"

Gem::Specification.new do |spec|
  spec.name          = "wexpr"
  spec.version       = Wexpr::VERSION
  spec.authors       = ["Kenneth Perry (thothonegan)"]
  spec.email         = ["thothonegan@gmail.com"]

  spec.summary       = %q{Wexpr parser and emitter for ruby}
  spec.description   = %q{
	Wexpr is a simple configuration language, similar to lisps's S expressions or JSON. Designed to be readable, while being quick and easy to parse.
	This is a ruby library to parse and emit wexpr.
  }
  spec.homepage      = "https://github.com/thothonegan/ruby-wexpr"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  #if spec.respond_to?(:metadata)
  #  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #else
  #  raise "RubyGems 2.0 or newer is required to protect against " \
  #    "public gem pushes."
  #end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "minitest", "~> 5.0"
  
  spec.required_ruby_version = '>= 2.0'
end
