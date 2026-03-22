# frozen_string_literal: true

require_relative 'lib/philiprehberger/cors/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-cors'
  spec.version       = Philiprehberger::Cors::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'CORS middleware with origin validation and preflight handling'
  spec.description   = 'Rack-compatible CORS middleware supporting configurable allowed origins, ' \
                       'methods, headers, credentials, and max-age. Handles preflight OPTIONS ' \
                       'requests and sets appropriate Access-Control headers.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-cors'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
