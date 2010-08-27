require 'helper'

class TestImapArchiver < Test::Unit::TestCase
  context "The archiver" do
    setup do
      @archiver = ImapArchiver::Archiver.new('mailserver','user','password')
      @archiver.connection = mock()
    end
    should "store it's initialisation parameters" do
      assert_equal('mailserver', @archiver.mailserver)
      assert_equal('user', @archiver.username)
      assert_equal('password', @archiver.password)
    end
    
    should "use CRAM-MD5 as a default authentication algorithm" do
      assert_equal("CRAM-MD5", @archiver.auth_mech)
    end
    
    should "create and authenticate an imap connection when calling reconnect" do
      connection = mock()
      Net::IMAP.expects(:new).with("mailserver").returns(connection)
      connection.expects(:authenticate).with("CRAM-MD5","user","password")
      @archiver.reconnect
    end
    
    should "call reconnect when calling connect" do
      @archiver.expects(:reconnect)
      @archiver.connect
    end
    
    should "reconnect when an IOError is raised during archiving" do
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
    
    should "list all folders in base_folder when starting archiving" do
      @archiver.expects(:folder_list).returns([])
      @archiver.start
    end
    
    should "copy and delete all found messages" do
      @archiver.instance_variable_set(:@msg_count, 0)
      @archiver.connection.expects(:select).at_least_once
      @archiver.connection.expects(:search).twice.returns([1,5,6],[])
      @archiver.connection.expects(:list).returns(true)
      @archiver.connection.expects(:copy).with([1,5,6],"Public Folders/Archief/test/#{Date.today.strftime("%b %Y")}")
      @archiver.connection.expects(:store)
      @archiver.connection.expects(:expunge)
      
      @archiver.archive_folder_between_dates('Public Folders/test',Date.today,Date.today)
    end
    
    should "list all folders in folders_to_archive array" do
      @archiver.folders_to_archive = ["Public Folders/test1", "test2"]
      @archiver.connection.expects(:list).with('',"Public Folders/test1")
      @archiver.connection.expects(:list).with('',"test2")
      @archiver.start
    end
    
    should "list all folders in folders_to_archive regexp" do
      @archiver.folders_to_archive = /testregexp/
      mock1 = mock(:name => 'hello')
      mock2 = mock()
      mock2.expects(:name).twice.returns('testregexp')
      @archiver.connection.expects(:list).with('',"*").returns([mock1,mock2])
      @archiver.expects(:archive_folder_between_dates)
      @archiver.start
    end
    
    should "filter the folder_list when using a regexp" do
      @archiver.folders_to_archive = /testregexp/
      mock1 = mock(:name => 'hello')
      mock2 = mock(:name => 'een testregexp test')
      @archiver.connection.expects(:list).with('',"*").returns([mock1,mock2])
      folder_list = @archiver.folder_list
      assert_equal([mock2], folder_list)
    end
    
    should "strip the folder_list of non-existing mailboxes" do
      @archiver.folders_to_archive = ["Public Folders/test1", "test2"]
      @archiver.connection.expects(:list).with('',"Public Folders/test1").returns(mock1 = mock())
      @archiver.connection.expects(:list).with('',"test2").returns(nil)
      assert_equal([mock1], @archiver.folder_list)
    end
    
  end
end
