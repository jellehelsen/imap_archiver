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
    end
    """
    @config_file.close
  end
  
  after(:all) do
    # File.delete(@config_file.path)
  end
  
  before(:each) do
    @connection = mock()
    Net::IMAP.expects(:new).with("imap.example.net").returns(@connection)
    @connection.expects(:authenticate).with("CRAM-MD5","jhelsen","secret").returns(true)
  end
  it "should create and authenticate an imap connection and list all folders" do
    @connection.expects(:list).with("","*").returns([])
    flunk "Config file gone!!!" unless File.file?(@config_file.path)
    ImapArchiver::CLI.execute(STDOUT,STDIN,["-F",@config_file.path])
  end
  
  it "should select and search the matching mailboxes" do
    @connection.expects(:list).with("","*").returns([mock1=stub(:name=>'testfolder'),mock2=stub(:name=>'foldertest')])
    @connection.expects(:select).with('testfolder')
    @connection.expects(:search).returns([]).times(2) #search current range and before
    ImapArchiver::CLI.execute(STDOUT,STDIN,["-F",@config_file.path])
  end
end