# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grammar_monkey/version'

Gem::Specification.new do |spec|
  spec.name                  = "grammar_monkey"
  spec.version               = GrammarMonkey::VERSION.dup
  spec.authors               = ["BR"]
  spec.homepage    = 'http://github.com/composer22/grammar_monkey'
  spec.summary     = "Some ported writing analysis features from http://grammark.org"
  spec.description = spec.summary
  spec.license     = 'GPL3'

  spec.required_ruby_version = '>= 1.9.3'
  spec.platform              = Gem::Platform::RUBY

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec", ">= 2.7.0"

  spec.has_rdoc         = true
  spec.rdoc_options     = ['-all', '--inline-source', '--charset=UTF-8']
  spec.extra_rdoc_files = ['README.rdoc']

end
