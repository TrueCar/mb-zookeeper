module ZooKeeper
  class LockerBase
    # @private
    attr_accessor :zk

    # our absolute lock node path
    #
    # ex. '/_zklocking/foobar/__blah/lock000000007'
    attr_reader :lock_path #;nodoc:


    # @private
    def initialize(zookeeper_client, name, root_lock_node = "/_zklocking")
      @zk = zookeeper_client
      @root_lock_node = root_lock_node
      @path = name
      @locked = false
    end

    # the basename of our lock path
    #
    # for the lock_path '/_zklocking/foobar/__blah/lock000000007'
    # lock_basename is 'lock000000007'
    #
    # returns nil if lock_path is not set
    def lock_basename
      lock_path and File.basename(lock_path)
    end

    protected
      def create_root_path!
        @zk.mkdir_p(root_lock_path)
      end

      # prefix is the string that will appear in front of the sequence num,
      # defaults to 'lock'
      def create_lock_path!(prefix='lock')
        create_root_path!
        @lock_path = @zk.create("#{root_lock_path}/#{prefix}", "", :mode => :ephemeral_sequential)
      rescue Exceptions::NoNode
        retry
      end

      def cleanup_lock_path!
        @zk.delete(@lock_path)
        @zk.delete(root_lock_path) rescue Exceptions::NotEmpty
      end

      def root_lock_path
        @root_lock_path ||= "#{@root_lock_node}/#{@path.gsub("/", "__")}"
      end
  end
end

