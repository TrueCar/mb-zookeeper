require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper, "with no paths" do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181", :watcher => nil)
    wait_until{ @zk.connected? }
    delete_test!
  end
  
  after(:each) do
    delete_test!
    @zk.close!
    wait_until{ @zk.closed? }
  end

  def delete_test!
    if (@zk.exists?('/test'))
      @zk.children("/test").each do |child|
        @zk.delete("/test/#{child}")
      end
      @zk.delete('/test')
    end
  end



  it "should not exist" do
    @zk.exists?("/test").should be_nil
  end

  it "should create a path" do
    @zk.create("/test", "test_data").should == "/test"
  end

  it "should be able to set the data" do
    @zk.create("/test", "something")
    @zk.set("/test", "somethingelse")
    @zk.get("/test").first.should == "somethingelse"
  end

  it "should raise an exception for a non existent path" do
    lambda { @zk.get("/non_existent_path") }.should raise_error(KeeperException::NoNode)
  end

  it "should create a path with sequence set" do
    @zk.create("/test", "test_data", :mode => :persistent_sequential).should =~ /test(\d+)/
  end

  it "should create an ephemeral path" do
    @zk.create("/test", "test_data", :mode => :ephemeral).should == "/test"
  end

  it "should remove ephemeral path when client session ends" do
    @zk.create("/test", "test_data", :mode => :ephemeral).should == "/test"
    @zk.exists?("/test").should_not be_nil
    @zk.close!

    @zk = ZooKeeper.new("localhost:2181", :watcher => nil)
    wait_until{ @zk.connected? }
    @zk.exists?("/test").should be_nil
  end

  it "should remove sequential ephemeral path when client session ends" do
    created = @zk.create("/test", "test_data", :mode => :ephemeral_sequential)
    created.should =~ /test(\d+)/
    @zk.exists?(created).should_not be_nil
    @zk.close!

    @zk = ZooKeeper.new("localhost:2181", :watcher => nil)
    wait_until{ @zk.connected? }
    @zk.exists?(created).should be_nil
  end

end

describe ZooKeeper, "with a path" do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181", :watcher => nil)
    wait_until{ @zk.connected? }
    delete_test!
    @zk.create("/test", "test_data", :mode => :persistent)
  end

  after(:each) do
    delete_test!
    @zk.close!
    wait_until{ @zk.closed? }
  end

  def delete_test!
    if (@zk.exists?('/test'))
      @zk.children("/test").each do |child|
        @zk.delete("/test/#{child}")
      end
      @zk.delete('/test')
    end
  end

  it "should return a stat" do
    @zk.exists?("/test").should be_instance_of(ZooKeeper::Stat)
  end

  it "should get data and stat" do
    data, stat = @zk.get("/test", :stat => stat)
    data.should == "test_data"
    stat.should be_a_kind_of(ZooKeeper::Stat)
    stat.created_time.should_not == 0
  end

  it "should set data with a file" do
    file = File.read('spec/test_file.txt')
    @zk.set("/test", file)
    @zk.get("/test").first.should == file
  end

  it "should delete path" do
    @zk.delete("/test")
    @zk.exists?("/test").should be_nil
  end

  it "should create a child path" do
    @zk.create("/test/child", "child").should == "/test/child"
  end

  it "should create sequential child paths" do
    (child1 = @zk.create("/test/child", "child1", :mode => :persistent_sequential)).should =~ /\/test\/child(\d+)/
    (child2 = @zk.create("/test/child", "child2", :mode => :persistent_sequential)).should =~ /\/test\/child(\d+)/
    children = @zk.children("/test")
    children.length.should == 2
    children.should be_include(child1.match(/\/test\/(child\d+)/)[1])
    children.should be_include(child2.match(/\/test\/(child\d+)/)[1])
  end

  it "should have no children" do
    @zk.children("/test").should be_empty
  end

end

describe ZooKeeper, "with children" do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181", :watcher => nil)
    wait_until{ @zk.connected? }
    delete_test!
    @zk.create("/test", "test_data", :mode => :persistent)
    @zk.create("/test/child", "child", :mode => "persistent").should == "/test/child"
  end

  after(:each) do
    delete_test!
    @zk.close!
    wait_until{ @zk.closed? }
  end

  def delete_test!
    if (@zk.exists?('/test'))
      @zk.children("/test").each do |child|
        @zk.delete("/test/#{child}")
      end
      @zk.delete('/test')
    end
  end

  it "should get children" do
    @zk.children("/test").should eql(["child"])
  end

end
