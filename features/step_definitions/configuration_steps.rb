Given /^I have no file "([^"]*)"$/ do |filename|
  `rm -f #{filename}` 
end

When /^I load the configuration file "([^"]*)"$/ do |filename|
  @archiver = ImapArchiver::Archiver.new(filename)
end

Then /^the configuration ([^"]*) should be "([^"]*)"$/ do |key,value|
  if value =~ /^\/.*\/$/
    value = Regexp.compile(value.gsub("/",""))
  end
  @archiver.send(key).should == value
end