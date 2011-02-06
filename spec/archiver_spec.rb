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
      connection = mock(:capability => ["AUTH=CRAM-MD5"])
      Net::IMAP.expects(:new).with("mailserver").returns(connection)
      connection.expects(:authenticate).with("CRAM-MD5","user","password")
      @archiver.reconnect
    end
    
    it "should fallback to plain login if no other authentication mechanisms are available" do
      connection = mock()
      Net::IMAP.expects(:new).with("mailserver").returns(connection)
      connection.expects(:capability).returns(%w(AUTH=PLAIN AUTH=LOGIN))
      connection.expects(:login).with("user","password")
      @archiver.connect
      
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
      @archiver.archive_folder = 'archive'
      @archiver.base_folder = 'Public Folders'
      # @archiver.expects(:connect)
      @archiver.connection = stub_everything
    end
    it "should list all folders in folders_to_archive array" do
      @archiver.folders_to_archive = ["Public Folders/test1", "test2"]
      @archiver.connection.expects(:list).with('',"Public Folders/test1").returns([stub(:name => 'Public Folders/test1')])
      @archiver.connection.expects(:list).with('',"test2").returns([stub(:name => 'test2')])
      @archiver.connection.expects(:search).times(4).returns([])
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
      @archiver.connection.expects(:list).with('',"Public Folders/test1").returns([mock1 = mock()])
      @archiver.connection.expects(:list).with('',"test2").returns(nil)
      @archiver.folder_list.should == [mock1]
    end  
  end

  describe "copying mails" do
    before do
      ImapArchiver::Config.expects(:load_config)
      ImapArchiver::Archiver.any_instance.expects(:config_valid?)
      @archiver = ImapArchiver::Archiver.new("configfile")
      @archiver.imap_server = "mailserver"
      @archiver.username = "user"
      @archiver.password = "password"
      @archiver.auth_mech = 'CRAM-MD5'
      @archiver.archive_folder = 'archive'
      @archiver.base_folder = 'Public Folders'
      # @archiver.expects(:connect)
      @archiver.connection = mock
      @archiver.connection.stubs(:capability).returns([])
      @archiver.connection.stubs(:list).returns(mock)
      @archiver.connection.stubs(:select)
      @archiver.connection.stubs(:store)
      @archiver.connection.stubs(:expunge)
      @archiver.instance_variable_set("@msg_count",0)
    end

    it "should copy archivable msgs in chunks" do
      #@archiver.folders_to_archive = ["Public Folders/test1"]
      #@archiver.connection.expects(:list).with('',"Public Folders/test1").returns([mock1 = mock(:name => "Public Folders/test1")])
      since_date = Date.today.months_ago(3).beginning_of_month 
      before_date= Date.today.months_ago(2).beginning_of_month 
      conditions = ["SINCE", since_date.strftime("%d-%b-%Y"), "BEFORE", before_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]
      @archiver.connection.expects(:search).with(conditions).returns((1..996).to_a)
      @archiver.connection.expects(:search).with(["BEFORE", since_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).returns([])
      @archiver.connection.expects(:copy).with((1..100).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.connection.expects(:copy).with((101..200).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.connection.expects(:copy).with((201..300).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.connection.expects(:copy).with((301..400).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.connection.expects(:copy).with((401..500).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.connection.expects(:copy).with((501..600).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.connection.expects(:copy).with((601..700).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.connection.expects(:copy).with((701..800).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.connection.expects(:copy).with((801..900).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.connection.expects(:copy).with((901..996).to_a, "archive/test1/#{since_date.strftime("%b %Y")}")
      @archiver.archive_folder_between_dates("Public Folders/test1",since_date,before_date) #if folder.name =~ /^Public Folders\/Team\//
      @archiver.instance_variable_get("@msg_count").should == 996
    end
  end
end
