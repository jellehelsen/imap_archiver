require 'helper'

class TestImapArchiver < Test::Unit::TestCase
  context "The archiver" do
    setup do
      @archiver = ImapArchiver::Archiver.new('mailserver','user','password')
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
      @archiver.reconnect
    end
    
    should "reconnect when an IOError is raised during archiving" do
      @archiver.connection = mock()
      @archiver.connection.stubs(:select)
      @archiver.connection.stubs(:search).returns([1])
      @archiver.connection.stubs(:list).returns(true)
      @archiver.connection.expects(:copy).with([1], 'Public Folders/Archief/test/Mar 2010').at_least_once.raises(IOError)
      @archiver.expects(:reconnect).at_least_once
      @archiver.archive_folder_between_dates('Public Folders/test',Date.today,Date.today)
    end
  end
end
