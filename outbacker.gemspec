# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'outbacker/version'

Gem::Specification.new do |spec|
  spec.name          = "outbacker"
  spec.version       = Outbacker::VERSION
  spec.authors       = ["Anthony Garcia"]
  spec.email         = ["polypressure@outlook.com"]
  spec.summary       = "Drive complexity out of your Rails controllers once and for all, while keeping your models fit and trim."
  spec.description   = <<-DESC
    A micro library to keep conditional logic out of your Rails
    controllers and help you write more intention-revealing
    code with both skinny controllers and skinny models.
  DESC
  spec.homepage      = "https://github.com/polypressure/outbacker"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'configurations', '~> 2.2', '>= 2.2.0'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.5"
  spec.add_development_dependency 'minitest-reporters', '~> 1.0', '>= 1.0.19'
  spec.add_development_dependency 'm', '~> 1.3', '>= 1.3.1'
  spec.add_development_dependency 'simplecov', '~> 0.10', '>= 0.10.0'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.4', '>= 0.4.7'
end
