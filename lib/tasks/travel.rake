
namespace :travel do
  desc 'Increase age fields'
  task :ahead do |_, args|
    args.with_defaults days: 1
    go_ahead(args[:days])
  end

  desc 'Decrease age fields'
  task :back do |_, args|
    args.with_defaults days: 1
    go_back(args[:days])
  end
end

private

# Increase all age fields by one day.
#
# @param [ Int ] days Amount of days.
#                     Defaults to: 1
#
# @return [ Void ]
def go_ahead(days = 1)
  puts "Traveling ahead #{days} day#{'s' if days > 1}"

  require 'benchmark'
  require 'time_butler'

  time = Benchmark.realtime { TimeButler.go_ahead days }

  puts "Total time elapsed #{time.round(2)} seconds"
end

# Decrease all age fields by one day.
#
# @param [ Int ] inc: Amount of days.
#                     Defaults to: 1
#
# @return [ Void ]
def go_back(days = 1)
  puts "Traveling back #{days} day#{'s' if days > 1}"

  require 'benchmark'
  require 'time_butler'

  time = Benchmark.realtime { TimeButler.go_back days }

  puts "Total time elapsed #{time.round(2)} seconds"
end
