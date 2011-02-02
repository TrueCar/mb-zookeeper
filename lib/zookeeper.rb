ZOOKEEPER_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

# The base connection class
# @example
#   zk = ZooKeeper.new("localhost:2181")
#   zk.create("/my_path")
module ZooKeeper
end

if defined?(JRUBY_VERSION)
  require "#{ZOOKEEPER_ROOT}/ext/zookeeper_j/zookeeper"
else
  require 'zookeeper_c/zookeeper'
end


require 'zookeeper/exceptions'
require 'zookeeper/id'
require 'zookeeper/permission'
require 'zookeeper/acl'
require 'zookeeper/stat'
require 'zookeeper/watcher_event'
require 'zookeeper/locker'
require 'zookeeper/message_queue'
require 'zookeeper/event_handler_subscription'
require 'zookeeper/event_handler'
require 'zookeeper/connection'
require 'zookeeper/connection_pool'
require 'zookeeper/logging'
require 'zookeeper/top_level_module_methods'


