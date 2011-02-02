module ZooKeeper
  # common Connection methods between java and C ruby versions
  class Connection
    DEFAULTS = {
      :timeout => 10000
    }

    # creates a new locker based on the name you send in
    # @param [String] name the name of the lock you wish to use
    # @see ZooKeeper::Locker#initialize
    # @return ZooKeeper::Locker the lock using this connection and name
    # @example
    #   zk.locker("blah").lock!
    def locker(name)
      Locker.new(self, name)
    end

    # creates a new message queue of name _name_
    # @param [String] name the name of the queue
    # @return [ZooKeeper::MessageQueue] the queue object
    # @see ZooKeeper::MessageQueue#initialize
    # @example
    #   zk.queue("blah").publish({:some_data => "that is yaml serializable"})
    def queue(name)
      MessageQueue.new(self, name)
    end

    # convenience method for acquiring a lock then executing a code block
    def with_lock(path, &b)
      locker(path).with_lock(&b)
    end

    # creates all parent paths and 'path' in zookeeper as nodes with zero data
    # opts should be valid options to ZooKeeper#create
    #---
    # TODO: write a non-recursive version of this. ruby doesn't have TCO, so
    # this could get expensive w/ psychotically long paths
    #
    def mkdir_p(path)
      create(path, '', :mode => :persistent)
    rescue Exceptions::NodeExists
      return
    rescue Exceptions::NoNode
      if File.dirname(path) == '/'
        # ok, we're screwed, blow up
        raise ZooStoreException, "could not create '/', something is wrong", caller
      end

      mkdir_p(File.dirname(path))
      retry
    end

    # recursively remove all children of path then remove path itself
    def rm_rf(path)
      children(path).each do |child|
        rm_rf(File.join(path, child))
      end

      delete(path)
      nil
    rescue Exceptions::NoNode
    end
  end
end

