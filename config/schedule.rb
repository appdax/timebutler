# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :path, ENV.fetch('APP_HOME', Whenever.path)
set :job_template, "/bin/sh -l -c ':job'"

job_type :rake, 'cd :path && :bundle_command rake :task --silent :output'

every :day, at: 'midnight' do
  rake 'travel:ahead'
end
