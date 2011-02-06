require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ImapArchiver" do
  it "should read the correct version" do
    ImapArchiver::Version.should == "0.0.8"
  end
end
