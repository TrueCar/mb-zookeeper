require 'spec/zookeeper_test_server'

namespace :test_server do
  
  desc "Start ZooKeeper test server instance"
  task :start do
    ZooKeeperTestServer.start(false)
    puts "started zookeeper test server on localhost:2181"
  end
  
  desc "Stop ZooKeeper test server instance"
  task :stop do
    puts "stopping zookeeper test server on localhost:2181"
    ZooKeeperTestServer.stop
  end
  
  desc "Determine if ZooKeeper test server instance is running"
  task :running? do
    puts ZooKeeperTestServer.running?
  end

end

task :test_watch do
  puts `gem build zookeeper.gemspec`
  puts `sudo gem install zookeeper-0.3.gem`
  puts `spec spec/watch_spec.rb`
end

task :stress_watch do
  20.times do |time|
    puts time
    puts `spec spec/watch_spec.rb`
  end
end
