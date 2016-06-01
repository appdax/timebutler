require 'simplecov'
require 'codeclimate-test-reporter'
require 'timecop'
require 'pry'

CodeClimate::TestReporter.start

SimpleCov.start do
  add_filter '/spec'
  formatter SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      CodeClimate::TestReporter::Formatter
    ]
  )
end

Dir['lib/**/*.rb'].each { |f| require_relative "../#{f}" }
