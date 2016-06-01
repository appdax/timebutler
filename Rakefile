
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'

Dir.chdir('lib') { Dir['tasks/*.rake'].each { |file| load file } }
