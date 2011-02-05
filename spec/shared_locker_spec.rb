require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper::SharedLocker do
  describe ReadLocker do
    before do
      @zk = ZooKeeper.new("localhost:#{ZK_TEST_PORT}", :watcher => :default)
      @zk2 = ZooKeeper.new("localhost:#{ZK_TEST_PORT}", :watcher => :default)
      @connections = [@zk, @zk2]

      wait_until{ @connections.all? {|c| c.connected?} }

      @path_to_lock = "/lock_tester"
    end

    after(:each) do
      @connections.aach { |c| c.close! }
      wait_until { @connections.all? { |c| !c.connected? } }
    end
  end

end

