$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'imap_archiver'

require "aruba"
# require 'rspec/expectations'
# require 'cucumber/rspec/doubles'
require 'rspec/core'
require "rspec/mocks"
RSpec.configure do |c|
 # c.mock_framework = :rspec
 c.mock_framework = :mocha
 # c.mock_framework = :rr
 # c.mock_framework = :flexmock
end

require 'cucumber/rspec/doubles'
# require 'spec/stubs/cucumber'