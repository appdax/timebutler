require 'simplecov'
require 'timecop'
require 'pry'

SimpleCov.start do
  add_filter '/spec'
  add_filter '/lib/extensions/exception_notifier.rb'
end

Dir['lib/**/*.rb'].each { |f| require_relative "../#{f}" }
