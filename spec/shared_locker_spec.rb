require File.join(File.dirname(__FILE__), 'spec_helper')
require 'timeout'

describe ZooKeeper::SharedLocker do
  describe :ReadLocker do
    before do
      @zk = ZooKeeper.new("localhost:#{ZK_TEST_PORT}", :watcher => :default)
      @zk2 = ZooKeeper.new("localhost:#{ZK_TEST_PORT}", :watcher => :default)
      @connections = [@zk, @zk2]

      wait_until{ @connections.all? {|c| c.connected?} }

      @path = "shlock"
      @root_lock_path = "/_zksharedlocking/#{@path}"

      @read_locker  = ZooKeeper::SharedLocker.read_locker(@zk, @path)
      @read_locker2 = ZooKeeper::SharedLocker.read_locker(@zk, @path)
    end

    after do
      @connections.each { |c| c.close! }
      wait_until { @connections.all? { |c| !c.connected? } }
    end

    describe :root_lock_path do
      it %[should be a unique namespace by default] do
        @read_locker.root_lock_path.should == @root_lock_path
      end
    end

    describe :lock! do
      describe 'non-blocking success' do
        before do
          @rval   = @read_locker.lock!
          @rval2  = @read_locker2.lock!
        end

        it %[should acquire the first lock] do
          @rval.should be_true
          @read_locker.should be_locked
        end

        it %[should acquire the second lock] do
          @rval2.should be_true
          @read_locker2.should be_locked
        end
      end

      describe 'non-blocking failure' do
        before do
          @zk.mkdir_p(@root_lock_path)
          @write_lock_path = @zk.create('/_zksharedlocking/shlock/write', '', :mode => :ephemeral_sequential)
          @rval = @read_locker.lock!
        end

        after do
          @zk.rm_rf('/_zksharedlocking')
        end

        it %[should return false] do
          @rval.should be_false
        end

        it %[should not be locked] do
          @read_locker.should_not be_locked
        end
      end

      describe 'blocking success' do
        before do
          @zk.mkdir_p(@root_lock_path)
          @write_lock_path = @zk.create('/_zksharedlocking/shlock/write', '', :mode => :ephemeral_sequential)
          $stderr.sync = true
        end

        it %[should acquire the lock after the write lock is released] do
          ary = []

          @read_locker.lock!.should be_false

          th = Thread.new do
            @read_locker.lock!(true)
            ary << :locked
          end

          ary.should be_empty
          @read_locker.should_not be_locked

          @zk.delete(@write_lock_path)

          th.join(2)

          ary.length.should == 1

          @read_locker.should be_locked
        end

      end
    end
  end
end

