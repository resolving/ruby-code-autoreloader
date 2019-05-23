# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'ruby_code_autoreloader/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name          = 'ruby-code-autoreloader'
  s.version       = RubyCodeAutoreloader::VERSION
  s.authors       = ['Victor Vinogradov https://github.com/happyjedi']
  s.email         = ['happy.jedi.g@gmail.com']
  s.files         = `git ls-files`.split($\)
  s.test_files    = s.files.grep(%r{^(test|spec)/})
  s.require_paths = ['lib']
  s.summary       = 'A simple way to add code auto-reloading to any not Rails app'
  s.description   = 'A simple way to add code auto-reloading to any not Rails app'
  s.homepage      = 'https://github.com/resolving/ruby-code-autoreloader'
  s.license       = 'MIT'

  s.required_ruby_version = '>= 2.5.3'

  s.add_dependency 'activesupport', '>= 5.1.4'

  s.add_development_dependency 'byebug', '>= 9.0'
  s.add_development_dependency 'rspec', '>= 3.5.0'
end
