module ZooKeeper
  # NOTE: these locks exist in a different namespace than those created w/
  # Locker, and are therefore incompatible
  class SharedLocker < LockerBase
    READ_LOCK_PREFIX  = 'read'.freeze
    WRITE_LOCK_PREFIX = 'write'.freeze

    
    class NoWriteLockFoundException < StandardError #:nodoc:
    end

    def self.digit_from_lock_file(path)
      path[/0*(\d+)$/, 1].to_i
    end

    def initialize(zookeeper_client, name, root_lock_node = '/_zksharedlocking')
      super
      @read_locked = false
      @write_locked = false
    end

    def lock_for_read!(blocking=false)
      create_lock_path!(READ_LOCK_PREFIX)

      if got_read_lock?      
        @read_locked = true
        return true
      elsif blocking
        block_until_read_lock!
      else
        false
      end
    end

    def lock_number #:nodoc:
      @lock_number ||= (lock_path and digit_from(lock_path))
    end

    # returns the sequence number of the next lowest write lock node
    #
    # raises NoWriteLockFoundException when there are no write nodes with a 
    # sequence less than ours
    #
    def next_lowest_write_lock_num #:nodoc:
      digit_from(next_lowest_write_lock_name)
    end

    # the next lowest write lock number to ours
    #
    # so if we're "read010" and the children of the lock node are:
    #
    #   %w[write008 write009 read010 read011]
    #
    # then this method will return write009
    #
    # raises NoWriteLockFoundException if there were no write nodes with an
    # index lower than ours 
    #
    def next_lowest_write_lock_name #:nodoc:
      ary = lock_children.sort { |a,b| digit_from(a) <=> digit_from(b) }
      my_idx = ary.index(lock_basename)   # our idx would be 2

      not_found = lambda { raise NoWriteLockFoundException }

      ary[0..my_idx].reverse.find(not_found) { |n| n =~ /^write/ }
    end

    def got_read_lock? #:nodoc:
      lock_number > next_lowest_write_lock_num
    rescue NoWriteLockFoundException
      true
    end

    protected
      def digit_from(path)
        self.class.digit_from_lock_path(path)
      end

      def lock_children(watch=false)
        @zk.children(root_lock_path, :watch => watch)
      end

      # TODO: make this generic, can either block or non-block
      def block_until_read_lock!
        queue = Queue.new

        node = next_lowest_write_lock_name

        write_lock_deletion_cb = lambda do
          unless @zk.exists(node, :watch => true)
            queue << :locked
          end
        end

        @zk.watcher.register(node, &write_lock_deletion_cb)
        write_lock_deletion_cb.call   # avoid a race condition between registration and availability

        queue.pop   # block waiting for node deletion
      rescue NoWriteLockFoundException
        @read_locked = true
      end
  end
end

