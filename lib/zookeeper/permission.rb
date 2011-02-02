module ZooKeeper
  # not really used in this gem
  # @private
  # :nodoc:
  module Permission
    READ   = 1 << 0
    WRITE  = 1 << 1
    CREATE = 1 << 2
    DELETE = 1 << 3
    ADMIN  = 1 << 4
    ALL    = READ | WRITE | CREATE | DELETE
  end
  
end
