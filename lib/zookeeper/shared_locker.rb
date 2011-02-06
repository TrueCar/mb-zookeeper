module ZooKeeper
  # NOTE: these locks exist in a different namespace than those created w/
  # Locker, and are therefore incompatible
  #---
  # XXX: Should probably split this into two classes, ReadLocker and
  # WriteLocker as the protocols are similar but slightly different
  #
  module SharedLocker
    READ_LOCK_PREFIX  = 'read'.freeze
    WRITE_LOCK_PREFIX = 'write'.freeze

    def self.read_locker(zk, path)
      ReadLocker.new(zk, path)
    end

    def self.write_locker(zk, path)
      WriteLocker.new(zk, path)
    end
    
    class NoWriteLockFoundException < StandardError #:nodoc:
    end

    class WeAreTheLowestLockNumberException < StandardError #:nodoc:
    end

    class Base < LockerBase
      def self.digit_from_lock_path(path)
        path[/0*(\d+)$/, 1].to_i
      end

      def initialize(zookeeper_client, name, root_lock_node = '/_zksharedlocking')
        super
      end

      protected 
        def digit_from(path)
          self.class.digit_from_lock_path(path)
        end

        def lock_children(watch=false)
          @zk.children(root_lock_path, :watch => watch)
        end

        def ordered_lock_children(watch=false)
          lock_children(watch).sort { |a,b| digit_from(a) <=> digit_from(b) }
        end
    end

    class ReadLocker < Base
      # block caller until lock is aquired, then yield
      def with_lock
        lock!(true)
        yield
      ensure
        unlock!
      end

      def lock!(blocking=false)
        return true if @locked
        create_lock_path!(READ_LOCK_PREFIX)

        if got_read_lock?      
          @locked = true
        elsif blocking
          block_until_read_lock!
        else
          # we didn't get the lock, and we're not gonna wait around for it, so
          # clean up after ourselves
          cleanup_lock_path!
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
        ary = ordered_lock_children()
        my_idx = ary.index(lock_basename)   # our idx would be 2

        not_found = lambda { raise NoWriteLockFoundException }

        ary[0..my_idx].reverse.find(not_found) { |n| n =~ /^write/ }
      end

      def got_read_lock? #:nodoc:
        false if next_lowest_write_lock_num 
      rescue NoWriteLockFoundException
        true
      end

      protected
        # TODO: make this generic, can either block or non-block
        def block_until_read_lock!
          begin
            @zk.block_until_node_deleted(File.join(root_lock_path, next_lowest_write_lock_name))
          rescue NoWriteLockFoundException
            # next_lowest_write_lock_name may raise NoWriteLockFoundException,
            # which means we should not block as we have the lock (there is nothing to wait for)
          end

          @locked = true
        end
    end # ReadLocker

    class WriteLocker < Base
      def lock!(blocking=false)
        return true if @locked
        create_lock_path!(WRITE_LOCK_PREFIX)

        if got_write_lock?
          @locked = true
        elsif blocking
          block_until_write_lock!
        else
          cleanup_lock_path!
          false
        end
      end

      protected
        # the node that is next-lowest in sequence number to ours, the one we
        # watch for updates to
        def next_lowest_node
          ary = ordered_lock_children()
          my_idx = ary.index(lock_basename)

          raise WeAreTheLowestLockNumberException if my_idx == 0

          ary[(my_idx - 1)] 
        end

        def got_write_lock?
          ordered_lock_children.first == lock_basename
        end

        def block_until_write_lock!
          begin
            @zk.block_until_node_deleted(File.join(root_lock_path, next_lowest_node))
          rescue WeAreTheLowestLockNumberException
          end

          @locked = true
        end
    end # WriteLocker
  end   # SharedLocker
end     # ZooKeeper

