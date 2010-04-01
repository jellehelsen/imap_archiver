$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.dirname(__FILE__)+'/imap_archiver')
require "rubygems"
require "net/imap"
require "date"
require "active_support/all"
require "archiver"

Version = '0.0.1'
module ImapArchiver
end
