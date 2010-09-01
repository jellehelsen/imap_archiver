$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'imap_archiver'
require 'rspec'
require 'rspec/autorun'
require "mocha"
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.mock_framework = :mocha
end
