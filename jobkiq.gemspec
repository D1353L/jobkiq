# frozen_string_literal: true

require_relative 'lib/jobkiq/version'

Gem::Specification.new do |spec|
  spec.name          = 'jobkiq'
  spec.version       = Jobkiq::VERSION
  spec.authors       = ['D1353L']
  spec.email         = ['D1353L@users.noreply.github.com']

  spec.summary       = 'Async jobs processor'
  spec.description   = 'A simple background job processing library with tag-based concurrency control.'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'TODO: Set to your gem server https://example.com'

  # Include all files tracked by git, excluding certain files/directories
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      f == __FILE__ || f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end

  # Executable scripts
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  # Library path
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'dry-cli', '~> 1.3'
  spec.add_dependency 'logger', '~> 1.7'
  spec.add_dependency 'redis', '~> 5.4'
end
