SPEC_LOCATION = File.expand_path(File.dirname(__FILE__))

class ZooKeeperTestServer

  @@log_level_set = false
  
  def self.running?
    # XXX: uhh, what if you have zookeeper running on your system already?
    
    `ps | grep zookeeper`.include?("zookeeper-3.3.1")
  end

  def self.start(background=true)
    set_log_level
    FileUtils.remove_dir("/tmp/zookeeper", true)
    FileUtils.mkdir_p("/tmp/zookeeper/server1/data")
    if background
      thread = Thread.new do
        system("#{SPEC_LOCATION}/zookeeper-3.3.1/bin/zkServer.sh start &>/dev/null")
      end
    else
      system("#{SPEC_LOCATION}/zookeeper-3.3.1/bin/zkServer.sh start &>/dev/null")
    end
  end

  def self.stop
    system("#{SPEC_LOCATION}/zookeeper-3.3.1/bin/zkServer.sh stop &>/dev/null")
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


#   ZOOMAIN = 'org.apache.zookeeper.server.quorum.QuorumPeerMain'

#   ZK_DIST_PATH = File.expand_path('zookeeper-3.3.1', File.dirname(__FILE__))

#   ZOO_CFG_PATH = File.join(ZK_DIST_PATH, 'conf/zoo.cfg')

#   def initialize
#     pid = nil
#   end

#   def zk_classpath
#     Dir["#{ZK_DIST_PATH}/zookeeper-3.*.jar", "#{ZK_DIST_PATH}/lib/*.jar"].join(':')
#   end

#   # this is the MRI verison
#   def start_server_mri
#     raise "server already running! pid: #{pid}" if pid

#     pid = fork do
#       ENV['CLASSPATH'] = zk_classpath

#       exec("java -Dzookeeper.log.dir=/tmp -Dzookeeper.root.logger=INFO,CONSOLE #{ZOOMAIN} #{ZOO_CFG_PATH}")
#     end
#   end
#   
end
