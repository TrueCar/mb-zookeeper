module ZooKeeper
  module TopLevelModuleMethods
    # delegates to ZooKeeper::Connection#initialize
    def new(*args)
      Connection.new(*args)
    end
  end
end

ZooKeeper.class_eval do
  extend ZooKeeper::TopLevelModuleMethods
end

