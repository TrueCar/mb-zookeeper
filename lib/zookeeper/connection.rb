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
  end
end

