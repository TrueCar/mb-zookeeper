SPEC_LOCATION = File.expand_path(File.dirname(__FILE__))

class ZooKeeperTestServer

  @@log_level_set = false
  
  def self.running?
    `ps | grep zookeeper`.include?("zookeeper-3.3.1")
  end

  def self.start(background=true)
    set_log_level
    FileUtils.remove_dir("/tmp/zookeeper", true)
    FileUtils.mkdir_p("/tmp/zookeeper/server1/data")
    if background
      thread = Thread.new do
        `#{SPEC_LOCATION}/zookeeper-3.3.1/bin/zkServer.sh start`
      end
    else
      `#{SPEC_LOCATION}/zookeeper-3.3.1/bin/zkServer.sh start`
    end
  end

  def self.stop
    `#{SPEC_LOCATION}/zookeeper-3.3.1/bin/zkServer.sh stop`
    FileUtils.remove_dir("/tmp/zookeeper", true)
  end
  
  def self.set_log_level
    return if @@log_level_set
    if defined?(JRUBY_VERSION)
      require 'java'
      require 'log4j'
      import org.apache.log4j.Logger
      import org.apache.log4j.Level
      Logger.getRootLogger().set_level(Level::OFF)
    end
     @@log_level_set = true
  end
  
end
