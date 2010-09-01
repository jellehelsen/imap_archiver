require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "tempfile"
describe "imap_archiver" do
  before(:all) do
    @config_file = File.new(File.join(Dir.tmpdir,"imap_archiver_config.rb"),'w+')
    @config_file.write  """
    ImapArchiver::Config.run do |config|
       config.imap_server = 'imap.example.net'
       config.username = 'jhelsen'
       config.password = 'secret'
       config.folders_to_archive = /^test/
       config.archive_folder = '/Archive/test'
       config.base_folder = ''
    end
    """
    @config_file.close
  end
  
  after(:all) do
    # File.delete(@config_file.path)
  end
  
  before(:each) do
    @connection = stub_everything()
    @expectation = Net::IMAP.expects(:new).with("imap.example.net").returns(@connection)
    @archive_date = Date.today.months_ago(3).beginning_of_month
  end
  it "should create and authenticate an imap connection and list all folders" do
    @connection.expects(:authenticate).with("CRAM-MD5","jhelsen","secret").returns(true)
    @connection.expects(:list).with("","*").returns([])
    flunk "Config file gone!!!" unless File.file?(@config_file.path)
    ImapArchiver::CLI.execute(STDOUT,STDIN,["-F",@config_file.path])
  end
  
  it "should select and search the matching mailboxes" do
    @connection.expects(:list).with("","*").returns([mock1=stub(:name=>'testfolder'),mock2=stub(:name=>'foldertest')])
    @connection.expects(:select).with('testfolder')
    @connection.expects(:search).twice.returns([]) #search current range and before
    ImapArchiver::CLI.execute(STDOUT,STDIN,["-F",@config_file.path])
  end
  
  it "should create a mailbox for archiving if it does not exist" do
    @connection.expects(:list).with("","*").returns([mock1=stub(:name=>'testfolder'),mock2=stub(:name=>'foldertest')])
    @connection.expects(:select).with('testfolder')
    @connection.expects(:search).twice.returns([1,2],[])
    @connection.expects(:list).with('',"/Archive/test/testfolder/#{@archive_date.strftime("%b %Y")}")
    @connection.expects(:create).with("/Archive/test/testfolder/#{@archive_date.strftime("%b %Y")}")
    
    ImapArchiver::CLI.execute(STDOUT,STDIN,["-F",@config_file.path])
  end
  
  it "should not create a mailbox for archiving if it does  exist" do
    @connection.expects(:list).with("","*").returns([mock1=stub(:name=>'testfolder'),mock2=stub(:name=>'foldertest')])
    @connection.expects(:select).with('testfolder')
    @connection.expects(:search).twice.returns([1,2],[])
    @connection.expects(:list).with('',"/Archive/test/testfolder/#{@archive_date.strftime("%b %Y")}").returns(stub_everything('archive folder'))
    @connection.expects(:create).never
    
    ImapArchiver::CLI.execute(STDOUT,STDIN,["-F",@config_file.path])
  end
  
  it "should copy messages found to the archive folder" do
    @connection.expects(:list).with("","*").returns([mock1=stub(:name=>'testfolder'),mock2=stub(:name=>'foldertest')])
    @connection.expects(:select).with('testfolder')
    # @connection.expects(:search).twice.returns([1,2],[])
    @connection.expects(:search).with(["SINCE", @archive_date.strftime("%d-%b-%Y"), "BEFORE", @archive_date.end_of_month.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).returns([1,2])
    @connection.expects(:search).with(["BEFORE", @archive_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).returns([])
    
    @connection.expects(:copy).with([1,2],"/Archive/test/testfolder/#{@archive_date.strftime("%b %Y")}")
    
    ImapArchiver::CLI.execute(STDOUT,STDIN,["-F",@config_file.path])
    
  end
  
  it "should delete the copied messages" do
    @connection.expects(:list).with("","*").returns([mock1=stub(:name=>'testfolder'),mock2=stub(:name=>'foldertest')])
    @connection.expects(:select).with('testfolder')
    @connection.expects(:search).twice.returns([1,2],[])
    @connection.expects(:store).with([1,2],"+FLAGS",[:Deleted])
    @connection.expects(:expunge)
    ImapArchiver::CLI.execute(STDOUT,STDIN,["-F",@config_file.path])
    
  end
  
  it "should search for messages older then the archiving period" do
    @connection.expects(:list).with("","*").returns([mock1=stub(:name=>'testfolder'),mock2=stub(:name=>'foldertest')])
    @connection.expects(:select).with('testfolder').twice
    @connection.expects(:search).with(["SINCE", @archive_date.strftime("%d-%b-%Y"), "BEFORE", @archive_date.end_of_month.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).returns([1,2])
    @connection.expects(:search).with(["BEFORE", @archive_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).returns([3,4])
    @archive_date = @archive_date.prev_month
    @connection.expects(:search).with(["SINCE", @archive_date.strftime("%d-%b-%Y"), "BEFORE", @archive_date.end_of_month.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).returns([1,2])
    @connection.expects(:search).with(["BEFORE", @archive_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).returns([])
    
    ImapArchiver::CLI.execute(STDOUT,STDIN,["-F",@config_file.path])
    
    
  end
end