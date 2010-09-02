require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe ImapArchiver::CLI do
  it "should start the archiver with the default config file if no options are given" do
    ImapArchiver::Archiver.expects(:run).with('~/.imap_archiver.rb')
    ImapArchiver::CLI.execute(STDOUT,STDIN,[])
  end
  
  it "should display the help message" do
    help_message = """Usage: imap_archiver [options]

Options are:

    -h, --help                       Show this help message.
    -F PATH
                                     Configuration file
                                     Default: ~/.imap_archiver.yml
"""
    io = StringIO.new
    # OptionParser.any_instance.expects(:program_name).returns('imap_archiver')
    $0='imap_archiver'
    lambda { ImapArchiver::CLI.execute(io,STDIN,['-h']) }.should raise_error(SystemExit)
    io.string.should == help_message
  end
  
  it "should load the given config file" do
    ImapArchiver::Archiver.expects(:run).with('/tmp/imap_archiver.rb')
    ImapArchiver::CLI.execute(STDOUT,STDIN,%w(-F /tmp/imap_archiver.rb))
  end
end