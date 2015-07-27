# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'outbacker/version'

Gem::Specification.new do |spec|
  spec.name          = "outbacker"
  spec.version       = Outbacker::VERSION
  spec.authors       = ["Anthony Garcia"]
  spec.email         = ["polypressure@outlook.com"]
  spec.summary       = <<-DESC
    A micro library to simplify Rails controllers and encourage
    intention-revealing Rails code with both skinny controllers
    skinny and skinny models.
  DESC
  spec.homepage      = "https://github.com/polypressure/outbacker"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.5"
  spec.add_development_dependency "m", "~> 1.3.1"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency 'configurations', '~> 2.2.0'
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "codeclimate-test-reporter"
end
