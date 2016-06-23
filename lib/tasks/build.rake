
namespace :build do
  desc 'Remove dangling images and exited containers'
  task :clean do
    system 'docker rm $(docker ps -a -q -f status=exited)'
    system 'docker rmi $(docker images -q -f dangling=true)'
  end

  desc 'Build image for edge tag'
  task(:edge) { task('build:tag').invoke(:edge) }

  desc 'Build image for test tag'
  task(:test) { task('build:tag').invoke(:test) }

  task(:tag, [:tag]) do |_, args|
    tag   = args[:tag] || 'edge'
    image = "appdax/timebutler:#{tag}"

    FileUtils.ln_s "build/#{tag}/.dockerignore", '.dockerignore'
    system "docker build -t #{image} -f build/#{tag}/Dockerfile ."
    FileUtils.rm '.dockerignore'
    exit($CHILD_STATUS.exitstatus) unless $CHILD_STATUS.success?
  end
end
