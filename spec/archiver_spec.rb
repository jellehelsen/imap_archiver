require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe ImapArchiver::Archiver do
  it "should load and validate the configuration" do
    ImapArchiver::Config.expects(:load_config)
    ImapArchiver::Archiver.any_instance.expects(:config_valid?)
    ImapArchiver::Archiver.new("configfile")
  end
  
  describe "IMAP connection" do
    before(:each) do
      ImapArchiver::Config.expects(:load_config)
      ImapArchiver::Archiver.any_instance.expects(:config_valid?)
      @archiver = ImapArchiver::Archiver.new("configfile")
      @archiver.imap_server = "mailserver"
      @archiver.username = "user"
      @archiver.password = "password"
      @archiver.auth_mech = 'CRAM-MD5'
      @archiver.base_folder = 'Public Folders'
    end
    
    it "should create and authenticate an imap connection when calling reconnect" do
      connection = mock()
      Net::IMAP.expects(:new).with("mailserver").returns(connection)
      connection.expects(:authenticate).with("CRAM-MD5","user","password")
      @archiver.reconnect
    end
        
    it "should reconnect when calling connect" do
      @archiver.expects(:reconnect)
      @archiver.connect
    end
    
    it "should reconnect when an IOError is raised during archiving" do
      @archiver.instance_variable_set(:@msg_count, 0)
      @archiver.connection.expects(:select).times(2)
      @archiver.connection.expects(:search).times(3).returns([1],[1],[])
      @archiver.connection.expects(:list).times(2).returns(true)
      @archiver.connection.stubs(:copy).raises(IOError).then.returns(nil)
      @archiver.expects(:reconnect).times(1)
      @archiver.connection.expects(:store)
      @archiver.connection.expects(:expunge)
      @archiver.archive_folder_between_dates('Public Folders/test',Date.today,Date.today)
    end
    
    it "should list all folders in base_folder when starting archiving" do
      @archiver.expects(:folder_list).returns([])
      @archiver.start
    end
    
    it "should copy and delete all found messages" do

    end
  end
  
  describe "listing folders" do
    before(:each) do
      ImapArchiver::Config.expects(:load_config)
      ImapArchiver::Archiver.any_instance.expects(:config_valid?)
      @archiver = ImapArchiver::Archiver.new("configfile")
      @archiver.imap_server = "mailserver"
      @archiver.username = "user"
      @archiver.password = "password"
      @archiver.auth_mech = 'CRAM-MD5'
      @archiver.expects(:connect)
    end
    it "should list all folders in folders_to_archive array" do
      @archiver.folders_to_archive = ["Public Folders/test1", "test2"]
      @archiver.connection.expects(:list).with('',"Public Folders/test1")
      @archiver.connection.expects(:list).with('',"test2")
      @archiver.start
    end
    
    it "should list all folders in folders_to_archive regexp" do
      @archiver.folders_to_archive = /testregexp/
      mock1 = mock(:name => 'hello')
      mock2 = mock()
      mock2.expects(:name).twice.returns('testregexp')
      @archiver.connection.expects(:list).with('',"*").returns([mock1,mock2])
      @archiver.expects(:archive_folder_between_dates)
      @archiver.start
    end
    
    it "should filter the folder_list when using a regexp" do
      @archiver.folders_to_archive = /testregexp/
      mock1 = mock(:name => 'hello')
      mock2 = mock(:name => 'een testregexp test')
      @archiver.connection.expects(:list).with('',"*").returns([mock1,mock2])
      folder_list = @archiver.folder_list
      folder_list.should == [mock2]
    end
    
    it "should strip the folder_list of non-existing mailboxes" do
      @archiver.folders_to_archive = ["Public Folders/test1", "test2"]
      @archiver.connection.expects(:list).with('',"Public Folders/test1").returns(mock1 = mock())
      @archiver.connection.expects(:list).with('',"test2").returns(nil)
      @archiver.folder_list.should == [mock1]
    end  
  end
end