source 'https://rubygems.org'

raise 'Ruby 2.2 or newer required' unless RUBY_VERSION >= '2.2.0'

gem 'mongo', '~> 2.2'

gem 'rake', '~> 11.1', require: false
gem 'whenever', '~> 0.9', require: false

group :development, :test do
  gem 'pry-nav'
  gem 'dotenv'
end

group :test do
  gem 'rspec', '~> 3.4'
  gem 'timecop', '~> 0.8'
  gem 'hashdiff', '~> 0.3'
  gem 'simplecov'
  gem 'codeclimate-test-reporter'
end
